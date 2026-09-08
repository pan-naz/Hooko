import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { GoogleGenerativeAI, Part, SchemaType, GenerativeModel, GenerateContentResult } from "https://esm.sh/@google/generative-ai@0.21.0";

// SSE CORS headers
const SSE_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-max-age": "86400",
  "content-type": "text/event-stream",
  "cache-control": "no-cache",
  "connection": "keep-alive",
};

const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-max-age": "86400",
};

// Retry configuration
const RETRY_CONFIG = {
  maxRetries: 2,
  retryDelaysMs: [2000, 3000],
  retryableStatusCodes: [500, 503, 429],
};

// Types
interface Technique {
  id: string;
  slug: string;
  name: string;
  type: "audio" | "visual" | "emotion";
  category: string;
}

interface Niche {
  id: string;
  slug: string;
  name: string;
  category: string;
  avg_hook_score: number;
  tiktok_engagement: number | null;
  instagram_engagement: number | null;
  youtube_engagement: number | null;
}

interface ViralExample {
  id: string;
  niche_id: string;
  niche_name: string | null;
  description: string;
  thumbnail_url: string | null;
  youtube_url: string | null;
  technique_ids: string[] | null;
}

interface Phase1Result {
  detectedLanguage: string;
  currentHookQuote: string;
  audioType: "WITH_SPEECH" | "SILENT_MUSIC_ONLY";
  voicePercentage: number;
  timeline0To3s: string;
  firstSpokenWord: string;
  voiceStartSeconds: number;
  isVoiceLate: boolean;
  nicheSlug: string;
  audioScoreRaw: number;
  audioScore: number;
  visualScore: number;
  audioPenalty: number;
  overallScore: number;
  audioFeedback: string;
  visualFeedback: string;
}

interface HookAlternative {
  index: number;
  estimated_score: number;
  say_this_quote: string;
  audio_techniques: string[];
  say_this_rationale: string;
  show_this_quote: string;
  visual_techniques: string[];
  show_this_rationale: string;
  pro_tips: Array<{
    icon_type: "audio" | "visual" | "timing";
    tips: string[];
  }>;
  general_tips: string[];
  script_after_hook: string;
  visual_after_hook: string;
  cta: {
    say_this_content: string;
    say_this_timing: string;
    show_this_content: string;
    show_this_timing: string;
  } | null;
  suggested_caption: string;
  suggested_hashtags: string[];
  viral_example: {
    thumbnail_url: string;
    tags: string[];
    description: string;
    youtube_url: string;
  } | null;
}

interface PhaseTokenUsage {
  inputTokens: number;          // promptTokenCount (includes video/audio/text)
  outputTokens: number;         // candidatesTokenCount (visible response text)
  thinkingTokens: number;       // thoughtsTokenCount (Gemini 2.5 reasoning, billed as output)
  cachedInputTokens: number;    // cachedContentTokenCount (subset of input, billed at reduced rate)
  totalTokens: number;          // totalTokenCount (authoritative sum reported by API)
}

interface TokenUsage {
  phase1: PhaseTokenUsage;
  phase2: PhaseTokenUsage;
  total: PhaseTokenUsage;
}

function emptyPhaseTokenUsage(): PhaseTokenUsage {
  return {
    inputTokens: 0,
    outputTokens: 0,
    thinkingTokens: 0,
    cachedInputTokens: 0,
    totalTokens: 0,
  };
}

interface RetryInfo {
  phase1Retries: number;
  phase2Retries: number;
}

// ═══════════════════════════════════════════════════════════
// SSE HELPERS
// ═══════════════════════════════════════════════════════════

type SSEWriter = {
  sendEvent: (event: string, data: unknown) => void;
  sendKeepAlive: () => void;
  close: () => void;
};

function createSSEWriter(controller: ReadableStreamDefaultController<Uint8Array>): SSEWriter {
  const encoder = new TextEncoder();
  
  return {
    sendEvent: (event: string, data: unknown) => {
      const message = `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`;
      controller.enqueue(encoder.encode(message));
    },
    sendKeepAlive: () => {
      const message = `: keep-alive\n\n`;
      controller.enqueue(encoder.encode(message));
    },
    close: () => {
      controller.close();
    },
  };
}

// ═══════════════════════════════════════════════════════════
// BASE64 ENCODING HELPER
// ═══════════════════════════════════════════════════════════
function uint8ArrayToBase64(bytes: Uint8Array): string {
  let binary = "";
  const chunkSize = 8192;
  for (let i = 0; i < bytes.length; i += chunkSize) {
    const chunk = bytes.subarray(i, i + chunkSize);
    binary += String.fromCharCode(...chunk);
  }
  return btoa(binary);
}

// ═══════════════════════════════════════════════════════════
// RETRY HELPER (without per-phase timeouts - SSE handles keep-alive)
// ═══════════════════════════════════════════════════════════
async function withRetry<T>(
  operation: () => Promise<T>,
  phaseName: string,
  config: typeof RETRY_CONFIG = RETRY_CONFIG
): Promise<{ result: T; retryCount: number }> {
  let lastError: Error | null = null;
  let retryCount = 0;
  
  for (let attempt = 0; attempt <= config.maxRetries; attempt++) {
    try {
      if (attempt > 0) {
        const delayMs = config.retryDelaysMs[attempt - 1] || config.retryDelaysMs[config.retryDelaysMs.length - 1];
        console.log(`⏳ ${phaseName}: Retry ${attempt}/${config.maxRetries} - waiting ${delayMs}ms...`);
        await new Promise(resolve => setTimeout(resolve, delayMs));
      }
      
      console.log(`🔄 ${phaseName}: Attempt ${attempt + 1}/${config.maxRetries + 1}`);
      const result = await operation();
      
      if (attempt > 0) {
        console.log(`✅ ${phaseName}: Succeeded on retry ${attempt}`);
      }
      
      return { result, retryCount: attempt };
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));
      const isRetryable = isRetryableError(error);
      
      console.error(`❌ ${phaseName}: Attempt ${attempt + 1} failed - ${lastError.message}`);
      
      if (!isRetryable || attempt >= config.maxRetries) {
        throw lastError;
      }
      
      retryCount = attempt + 1;
    }
  }
  
  throw lastError || new Error(`${phaseName} failed after all retries`);
}

function isRetryableError(error: unknown): boolean {
  if (error instanceof Error) {
    const message = error.message.toLowerCase();
    if (
      message.includes("overloaded") ||
      message.includes("high demand") ||
      message.includes("capacity") ||
      message.includes("rate limit") ||
      message.includes("quota") ||
      message.includes("temporarily unavailable") ||
      message.includes("503") ||
      message.includes("500") ||
      message.includes("429")
    ) {
      return true;
    }
    // deno-lint-ignore no-explicit-any
    const anyError = error as any;
    if (anyError.status && RETRY_CONFIG.retryableStatusCodes.includes(anyError.status)) {
      return true;
    }
  }
  return false;
}

// ═══════════════════════════════════════════════════════════
// PHASE 1 RESPONSE SCHEMA
// ═══════════════════════════════════════════════════════════
// Note: is_voice_late, audio_penalty, audio_score, overall_score are computed
// server-side from voice_start_seconds + audio_score_raw + visual_score, so we
// don't ask Gemini to return them (reduces output tokens & avoids inconsistency).
const phase1ResponseSchema = {
  type: SchemaType.OBJECT,
  properties: {
    detected_language: { type: SchemaType.STRING, description: "ISO 639-1 code" },
    current_hook_quote: { type: SchemaType.STRING, description: "Transcribed opening spoken sentence, or '[No speech detected]'" },
    audio_type: { type: SchemaType.STRING, enum: ["WITH_SPEECH", "SILENT_MUSIC_ONLY"] },
    voice_percentage: { type: SchemaType.NUMBER, description: "% of video containing speech (0-100)" },
    timeline_0_to_3s: { type: SchemaType.STRING, description: "What happens visually/audibly in first 3s" },
    first_spoken_word: { type: SchemaType.STRING, description: "First word heard (empty if silent)" },
    voice_start_seconds: { type: SchemaType.NUMBER, description: "EXACT timestamp the first spoken word begins (0 if silent)" },
    niche_slug: { type: SchemaType.STRING, description: "Niche slug copied EXACTLY from provided list" },
    audio_score_raw: { type: SchemaType.NUMBER, description: "Audio quality score 0-100, BEFORE late-voice penalty" },
    visual_score: { type: SchemaType.NUMBER, description: "Visual quality score 0-100" },
    audio_feedback: { type: SchemaType.STRING, description: "10-20 words, in detected_language." },
    visual_feedback: { type: SchemaType.STRING, description: "10-20 words, in detected_language." },
  },
  required: [
    "detected_language", "current_hook_quote", "audio_type", "voice_percentage",
    "timeline_0_to_3s", "first_spoken_word", "voice_start_seconds",
    "niche_slug", "audio_score_raw", "visual_score",
    "audio_feedback", "visual_feedback",
  ],
};

// ═══════════════════════════════════════════════════════════
// PHASE 2 RESPONSE SCHEMA (built per-call so script_after_hook
// can carry a duration-proportional minLength, which Gemini's
// structured-output mode hard-enforces — instead of merely
// suggesting via prompt text).
// ═══════════════════════════════════════════════════════════
// deno-lint-ignore no-explicit-any
function buildPhase2ResponseSchema(scriptMinChars: number): any {
  return {
  type: SchemaType.OBJECT,
  properties: {
    why_not_working: {
      type: SchemaType.ARRAY,
      items: { type: SchemaType.STRING },
      description: "3-5 reasons why the hook is underperforming, in detected_language.",
    },
    hook_alternatives: {
      type: SchemaType.ARRAY,
      items: {
        type: SchemaType.OBJECT,
        properties: {
          index: { type: SchemaType.NUMBER },
          estimated_score: { type: SchemaType.NUMBER },
          say_this_quote: { type: SchemaType.STRING },
          audio_techniques: { type: SchemaType.ARRAY, items: { type: SchemaType.STRING } },
          say_this_rationale: { type: SchemaType.STRING },
          show_this_quote: { type: SchemaType.STRING },
          visual_techniques: { type: SchemaType.ARRAY, items: { type: SchemaType.STRING } },
          show_this_rationale: { type: SchemaType.STRING },
          pro_tips: {
            type: SchemaType.ARRAY,
            items: {
              type: SchemaType.OBJECT,
              properties: {
                icon_type: { type: SchemaType.STRING, enum: ["audio", "visual", "timing"] },
                tips: { type: SchemaType.ARRAY, items: { type: SchemaType.STRING } },
              },
              required: ["icon_type", "tips"],
            },
          },
          general_tips: { type: SchemaType.ARRAY, items: { type: SchemaType.STRING } },
          script_after_hook: {
            type: SchemaType.STRING,
            minLength: scriptMinChars,
            description: `Post-hook spoken script. MUST be at least ${scriptMinChars} characters (enforced) — outputs below this are rejected by the schema. Use the full word budget specified in the prompt; do NOT summarize.`,
          },
          visual_after_hook: { type: SchemaType.STRING },
          cta: {
            type: SchemaType.OBJECT,
            nullable: true,
            properties: {
              say_this_content: { type: SchemaType.STRING },
              say_this_timing: { type: SchemaType.STRING },
              show_this_content: { type: SchemaType.STRING },
              show_this_timing: { type: SchemaType.STRING },
            },
            required: ["say_this_content", "say_this_timing", "show_this_content", "show_this_timing"],
          },
          suggested_caption: { type: SchemaType.STRING },
          suggested_hashtags: { type: SchemaType.ARRAY, items: { type: SchemaType.STRING } },
        },
        required: [
          "index", "estimated_score", "say_this_quote", "audio_techniques",
          "say_this_rationale", "show_this_quote", "visual_techniques",
          "show_this_rationale", "pro_tips", "general_tips", "script_after_hook",
          "visual_after_hook", "suggested_caption", "suggested_hashtags",
        ],
      },
    },
  },
  required: ["why_not_working", "hook_alternatives"],
  };
}

// Helper functions
function createSupabaseClient(): SupabaseClient {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !supabaseServiceKey) {
    throw new Error("Missing required Supabase configuration");
  }
  return createClient(supabaseUrl, supabaseServiceKey);
}

function getGeminiClient(): GoogleGenerativeAI {
  const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
  if (!geminiApiKey) {
    throw new Error("Missing GEMINI_API_KEY");
  }
  return new GoogleGenerativeAI(geminiApiKey);
}

async function fetchTechniques(supabase: SupabaseClient): Promise<Technique[]> {
  const { data, error } = await supabase
    .from("techniques")
    .select("id, slug, name, type, category");
  if (error) throw new Error("Failed to fetch techniques from database");
  return data || [];
}

async function fetchNiches(supabase: SupabaseClient): Promise<Niche[]> {
  const { data, error } = await supabase
    .from("niches")
    .select("id, slug, name, category, avg_hook_score, tiktok_engagement, instagram_engagement, youtube_engagement");
  if (error) throw new Error("Failed to fetch niches from database");
  return data || [];
}

const clampScore = (score: number): number => Math.max(0, Math.min(100, score));

// ═══════════════════════════════════════════════════════════
// VIRAL EXAMPLE MATCHING LOGIC
// ═══════════════════════════════════════════════════════════
async function matchViralExamples(
  supabase: SupabaseClient,
  nicheSlug: string,
  niches: Niche[],
  techniques: Technique[],
  alternatives: HookAlternative[]
): Promise<(HookAlternative["viral_example"] | null)[]> {
  console.log(`🎬 Viral matching: niche="${nicheSlug}", alternatives=${alternatives.length}`);

  const niche = niches.find(n => n.slug.toLowerCase() === nicheSlug.toLowerCase());
  if (!niche) {
    console.log("⚠️ Niche not found, no viral examples will be attached");
    return alternatives.map(() => null);
  }

  const { data: viralExamples, error } = await supabase
    .from("viral_examples")
    .select("id, niche_id, niche_name, description, thumbnail_url, youtube_url, technique_ids")
    .eq("niche_id", niche.id);

  if (error) {
    console.error("❌ Error fetching viral examples:", error);
    return alternatives.map(() => null);
  }

  if (!viralExamples || viralExamples.length === 0) {
    console.log(`⚠️ No viral examples found for niche "${niche.name}"`);
    return alternatives.map(() => null);
  }

  console.log(`   Pool: ${viralExamples.length} examples for "${niche.name}"`);

  const techniqueSlugToId = new Map<string, string>();
  const techniqueIdToName = new Map<string, string>();
  techniques.forEach(t => {
    techniqueSlugToId.set(t.slug.toLowerCase(), t.id);
    techniqueIdToName.set(t.id, t.name);
  });

  const usedExampleIds = new Set<string>();
  const results: (HookAlternative["viral_example"] | null)[] = [];

  for (let altIndex = 0; altIndex < alternatives.length; altIndex++) {
    const alt = alternatives[altIndex];

    const altTechniqueIds = [...alt.audio_techniques, ...alt.visual_techniques]
      .map(s => techniqueSlugToId.get(s.toLowerCase()))
      .filter((id): id is string => id !== undefined);

    let bestMatch: ViralExample | null = null;
    let bestScore = -1;

    for (const example of viralExamples) {
      if (usedExampleIds.has(example.id)) continue;

      const exampleTechniqueIds = example.technique_ids || [];
      const overlapCount = altTechniqueIds.filter(id => exampleTechniqueIds.includes(id)).length;
      const descriptionScore = (example.description || "").length / 1000;
      const totalScore = overlapCount * 100 + descriptionScore;

      if (totalScore > bestScore) {
        bestScore = totalScore;
        bestMatch = example;
      }
    }

    if (bestMatch) {
      usedExampleIds.add(bestMatch.id);
      const tags = (bestMatch.technique_ids || [])
        .map(id => techniqueIdToName.get(id))
        .filter((name): name is string => name !== undefined);

      console.log(`   alt#${altIndex + 1} → matched ${bestMatch.id.substring(0, 8)} (overlap-based, ${tags.length} tags)`);

      results.push({
        thumbnail_url: bestMatch.thumbnail_url || "",
        tags: tags,
        description: bestMatch.description || "",
        youtube_url: bestMatch.youtube_url || "",
      });
    } else {
      console.log(`   alt#${altIndex + 1} → no available match`);
      results.push(null);
    }
  }

  console.log(`✅ Viral matching done: ${results.filter(r => r !== null).length}/${alternatives.length} matched`);
  return results;
}

// Build Phase 1 prompt
function buildPhase1Prompt(_techniques: Technique[], niches: Niche[], videoDurationSeconds: number): string {
  const nicheOptions = niches.map(n => ({ slug: n.slug, name: n.name }));

  return `You are a viral video hook analyzer. Analyze the FULL ${videoDurationSeconds}s video and return JSON.

⚠️ GLOBAL LANGUAGE RULE: Write EVERY user-facing string (audio_feedback, visual_feedback) entirely in detected_language. If detected_language != "en", translate fully — no English words, no mixed languages, no fallback to English. Technique slugs and niche_slug are NEVER translated.

=== 1. AUDIO TYPE ===
Listen ONLY to audio. Count distinct spoken WORDS.
NOT speech: music, beats, song lyrics / singing / rapping (even if words are intelligible — if a song is playing, those words DO NOT count as speech), ASMR/cooking sounds, ambient noise, SFX, animal sounds, gasps/sighs/laughs, single interjections ("mmm", "wow", "oh"), AND any on-screen text / captions / overlays (text is visual, never audio).
  - voice_percentage = (seconds containing actual speech / ${videoDurationSeconds}) * 100
  - audio_type = "WITH_SPEECH" if total_words >= 3 AND voice_percentage >= 30; else "SILENT_MUSIC_ONLY"

=== 2. LANGUAGE ===
  - SILENT_MUSIC_ONLY → detected_language = "en"
  - WITH_SPEECH → ISO 639-1 code of the spoken language ("en", "uk", "es", ...)

=== 3. VOICE TIMING & HOOK TRANSCRIPT ===
If SILENT_MUSIC_ONLY:
  voice_start_seconds=0, first_spoken_word="", timeline_0_to_3s="[No speech - only sounds]", current_hook_quote="[No speech detected]"
If WITH_SPEECH — MEASURE voice_start_seconds CAREFULLY (this drives a -10 penalty, accuracy is critical):
  - Scrub from t=0.0 second-by-second. voice_start_seconds = the EXACT timestamp the first spoken WORD begins (decimals allowed, e.g. 0.3, 1.4, 2.5, 4.7).
  - The following are NOT speech and DO NOT count: music, beats, background sounds, breaths, sighs, gasps, laughs, "mmm/uh/oh" interjections, on-screen text, sound effects.
  - DO NOT default to 0 or guess. If the opening contains music/silence/sounds before the first real word, voice_start_seconds MUST equal that delay (e.g. 2.3s of music intro → voice_start_seconds=2.3).
  - SELF-CHECK before answering: replay the first 3 seconds. If you hear NO spoken word in [0.0, 1.0), then voice_start_seconds >= 1.0. If NO spoken word in [0.0, 2.0), then voice_start_seconds >= 2.0. Adjust if your draft contradicts this.
  - first_spoken_word = the actual first word heard (matches the timestamp above).
  - timeline_0_to_3s = what happens visually/audibly in first 3s (mention the music/silence delay if any).
  - current_hook_quote = transcription of the opening spoken sentence (HEARD speech, not on-screen text).

=== 4. VISUAL SCORE (0-100) ===
Judge the full video: opening hook, camera, lighting, color, text/graphics, transitions, pacing, clarity.
Bands (most real videos land 45-60):
  71-100 viral-worthy (cinema-quality, pro lighting, multi-angle, flawless edit)
  61-70  good (professional, clean edit, proper color)
  50-60  average (decent phone, okay lighting, basic overlays)
  30-49  below average (single angle, poor lighting, no edit)
  0-29   poor (blurry, dark, technical issues)

=== 5. AUDIO SCORE — audio_score_raw (0-100) ===
WITH_SPEECH: voice clarity, mic quality, tone/energy, pacing, mix, background noise.
SILENT_MUSIC_ONLY: intentionality of sound design, music selection, ASMR/ambient quality, mix balance.
Bands (most real videos land 40-55):
  71-100 viral-worthy (studio mic / crystal-clear intentional sound)
  61-70  good (external mic or excellent phone / well-produced ambient)
  50-60  average (clear phone audio / acceptable ambient)
  30-49  below average (room echo, monotone / poor sound)
  0-29   poor (inaudible / harsh)

=== 6. NICHE (70/30 voice-first) ===
WITH_SPEECH: 70% spoken topic, 30% visuals (voice wins on conflict — speech about fitness + kitchen visual → fitness).
SILENT_MUSIC_ONLY: 100% visual.
Output niche_slug copied EXACTLY (underscores, not dashes) from:
${JSON.stringify(nicheOptions)}

=== 7. FEEDBACK (10-20 words each, in detected_language per global rule) ===
  - visual_feedback: what works / doesn't visually.
  - audio_feedback MUST match audio_type:
      • SILENT_MUSIC_ONLY → describe sound design / music / ambient / ASMR. NEVER use the words: voice, speech, narration, talking, speaking, spoken.
      • WITH_SPEECH → describe voice quality, tone, delivery, pacing.
  - HARD RULE (WITH_SPEECH only): IF voice_start_seconds > 0.7, audio_feedback MUST OPEN by explicitly calling out the late hook timing with the exact number (e.g. "Hook starts too late at 2.5s — viewers scroll before the first word."), THEN continue with voice-quality feedback. A server-side -10 penalty is applied and the user must understand why.

Return JSON matching the required schema.`;
}

// Compute a duration-proportional spoken-word target for script_after_hook.
// - WPS baseline 2.8 (~168 wpm) reflects energetic short-form delivery
//   (slightly faster than the generic 2.5 wps / 150 wpm conversational baseline,
//    matches how viral TikTok/Reels narrators actually pace).
// - Reserve ~3s for the hook (covered by improved_hook field).
// - Floor 40 words (anything less feels cut off).
// - Hard cap 200 words regardless of video length (per product spec).
// - Returns a ±band so Gemini has room without anchoring to the floor.
function computeScriptWordTarget(durationSeconds: number): { min: number; max: number; target: number } {
  const WPS = 2.8;
  const HOOK_RESERVE_S = 3;
  const speakingSeconds = Math.max(5, durationSeconds - HOOK_RESERVE_S);
  const rawTarget = Math.round(speakingSeconds * WPS);
  const target = Math.max(40, Math.min(200, rawTarget));
  const min = Math.max(40, Math.round(target * 0.85));
  const max = Math.min(200, Math.round(target * 1.10));
  return { min, max, target };
}

// Build Phase 2 prompt
function buildPhase2Prompt(
  phase1: Phase1Result,
  techniques: Technique[],
  nicheBenchmark: number,
  videoDurationSeconds: number
): string {
  const audioSlugs = techniques.filter(t => t.type === "audio").map(t => t.slug);
  const visualSlugs = techniques.filter(t => t.type === "visual").map(t => t.slug);
  const emotionSlugs = techniques.filter(t => t.type === "emotion").map(t => t.slug);
  
  const lang = phase1.detectedLanguage;
  const belowBenchmark = phase1.overallScore < nicheBenchmark;
  const scriptLen = computeScriptWordTarget(videoDurationSeconds);

  // Focused Phase 1 summary (only fields Phase 2 actually needs as context).
  const phase1Summary = {
    detected_language: phase1.detectedLanguage,
    audio_type: phase1.audioType,
    niche_slug: phase1.nicheSlug,
    current_hook_quote: phase1.currentHookQuote,
    voice_start_seconds: phase1.voiceStartSeconds,
    is_voice_late: phase1.isVoiceLate,
    audio_score: phase1.audioScore,
    visual_score: phase1.visualScore,
    overall_score: phase1.overallScore,
    audio_feedback: phase1.audioFeedback,
    visual_feedback: phase1.visualFeedback,
  };

  return `You are a viral video hook improvement expert. Rewatch the video and generate 3 distinct hook alternatives that fix the issues in the Phase 1 analysis.

⚠️ GLOBAL LANGUAGE RULE: Write EVERY user-facing string entirely in "${lang}" — quotes, rationales, tips, script_after_hook, visual_after_hook, CTA fields, caption, why_not_working. If "${lang}" != "en", translate fully — no English words, no mixed languages. NEVER translate: hashtags, technique slugs (audio/visual/emotion lists below).

=== PHASE 1 CONTEXT ===
${JSON.stringify(phase1Summary)}
Niche benchmark: ${nicheBenchmark} (overall_score is ${phase1.overallScore})

=== TECHNIQUE SLUGS (use EXACT slugs from these lists) ===
audio:   ${JSON.stringify(audioSlugs)}
visual:  ${JSON.stringify(visualSlugs)}
emotion: ${JSON.stringify(emotionSlugs)}

=== FOR EACH OF 3 ALTERNATIVES ===
1. Say This (audio hook, first 3s)
   - say_this_quote: compelling spoken hook
   - audio_techniques: 2-4 slugs from audio + emotion
   - say_this_rationale: 1 sentence on why it works

2. Show This (visual hook, first 3s)
   - show_this_quote: describe what appears on-screen
   - visual_techniques: 2-4 slugs from visual + emotion
   - show_this_rationale: 1 sentence on why it works

3. Pro Tips — EXACTLY 3 entries, all about the first-3-second hook only:
   - { icon_type: "audio",  tips: 2-4 tips on voice/tone/pacing }
   - { icon_type: "visual", tips: 2-4 tips on framing/camera/visuals }
   - { icon_type: "timing", tips: 2-4 tips on pacing/rhythm }

4. general_tips: 2-4 broader hook-improvement tips.

5. After the 3-second hook
   - script_after_hook: full post-hook spoken script sized to the analyzed video (${videoDurationSeconds}s total).
     • MINIMUM ${scriptLen.min} words — outputs below this are REJECTED by the schema. Do not stop early.
     • TARGET ${scriptLen.target} words (acceptable range ${scriptLen.min}-${scriptLen.max}). Aim for the target, not the minimum.
     • For videos longer than ~75s, you are writing a REWRITTEN CONDENSED VERSION that hits the strongest beats of the original — this is NOT a summary. Use the full ${scriptLen.target}-word budget; pack value into every sentence.
     • Upper bound ${scriptLen.max} words (hard cap 200 even for very long videos).
     • Complete sentences, no mid-sentence cutoff. Begin with "..." continuation from the hook.
     • Natural spoken pacing (~2.8 words/second at energetic short-form delivery).
   - visual_after_hook: visual directions for the rest of the video.

6. cta: { say_this_content, say_this_timing, show_this_content, show_this_timing } — may be null only if a CTA truly doesn't fit.

7. Caption & Hashtags
   - suggested_caption: viral-optimized caption, NO hashtags inside.
   - suggested_hashtags: 8-10 relevant hashtags.

8. estimated_score: predicted score after improvements. MUST be >= ${nicheBenchmark}.

=== WHY_NOT_WORKING ===
${belowBenchmark
  ? `overall_score ${phase1.overallScore} < benchmark ${nicheBenchmark} → produce 3-5 specific, actionable, 1-sentence reasons explaining what hurts engagement (in "${lang}" per global rule).`
  : `overall_score ${phase1.overallScore} >= benchmark ${nicheBenchmark} → return [] (empty array).`}

Return JSON matching the schema: { why_not_working, hook_alternatives }.`;
}

// Parse Phase 1 response
function parsePhase1Response(text: string): Phase1Result {
  // responseMimeType: "application/json" guarantees no markdown fences, so we
  // parse directly.
  // deno-lint-ignore no-explicit-any
  const parsed = JSON.parse(text) as any;
  
  console.log(`Phase 1 raw: voice_pct=${parsed.voice_percentage}, audio_type=${parsed.audio_type}, voice_start=${parsed.voice_start_seconds}s, hook="${parsed.current_hook_quote}"`);
  
  const voicePercentage = parsed.voice_percentage || 0;
  const enforcedAudioType = voicePercentage >= 30 ? "WITH_SPEECH" : "SILENT_MUSIC_ONLY";
  
  if (enforcedAudioType !== parsed.audio_type) {
    console.log(`⚠️ SERVER OVERRIDE: audio_type: ${parsed.audio_type} → ${enforcedAudioType}`);
  }
  
  const voiceStartSeconds = parsed.voice_start_seconds || 0;
  let enforcedIsVoiceLate: boolean;
  let enforcedAudioPenalty: number;
  let enforcedAudioScore: number;
  let enforcedOverallScore: number;
  
  const audioScoreRaw = clampScore(parsed.audio_score_raw || 0);
  const visualScore = clampScore(parsed.visual_score || 0);
  
  let enforcedHookQuote = parsed.current_hook_quote || "";
  let enforcedAudioFeedback = parsed.audio_feedback || "";
  
  if (enforcedAudioType === "SILENT_MUSIC_ONLY") {
    enforcedIsVoiceLate = false;
    enforcedAudioPenalty = 0;
    enforcedAudioScore = audioScoreRaw;
    enforcedHookQuote = "[No speech detected]";

    // If the model leaked voice-related wording for a silent video, drop the
    // bad sentence(s) instead of overriding with hardcoded English (which would
    // break localization for non-English videos).
    const voiceKeywords = ["voice", "speech", "narration", "narrate", "talking", "speaking", "spoken"];
    const sentences = enforcedAudioFeedback.split(/(?<=[.!?])\s+/);
    const cleaned = sentences.filter((s: string) => {
      const lower = s.toLowerCase();
      return !voiceKeywords.some(kw => lower.includes(kw));
    }).join(" ").trim();
    if (cleaned !== enforcedAudioFeedback) {
      console.log(`⚠️ SERVER OVERRIDE: stripped voice-related sentences from audioFeedback for SILENT_MUSIC_ONLY video`);
      enforcedAudioFeedback = cleaned;
    }
  } else {
    enforcedIsVoiceLate = voiceStartSeconds > 0.7;
    enforcedAudioPenalty = enforcedIsVoiceLate ? 10 : 0;
    enforcedAudioScore = Math.max(0, audioScoreRaw - enforcedAudioPenalty);
    
    console.log(`🎯 VOICE TIMING CHECK: ${voiceStartSeconds}s > 0.7 = ${enforcedIsVoiceLate}`);
    console.log(`   → audio_penalty: ${enforcedAudioPenalty}, audio_score: ${enforcedAudioScore}`);
  }
  
  enforcedOverallScore = Math.round((enforcedAudioScore + visualScore) / 2);
  
  return {
    detectedLanguage: parsed.detected_language || "en",
    currentHookQuote: enforcedHookQuote,
    audioType: enforcedAudioType,
    voicePercentage: voicePercentage,
    timeline0To3s: parsed.timeline_0_to_3s || "",
    firstSpokenWord: parsed.first_spoken_word || "",
    voiceStartSeconds: voiceStartSeconds,
    isVoiceLate: enforcedIsVoiceLate,
    nicheSlug: parsed.niche_slug || "relatable_pov_comedy",
    audioScoreRaw: audioScoreRaw,
    audioScore: enforcedAudioScore,
    visualScore: visualScore,
    audioPenalty: enforcedAudioPenalty,
    overallScore: enforcedOverallScore,
    audioFeedback: enforcedAudioFeedback,
    visualFeedback: parsed.visual_feedback || "",
  };
}

// Parse Phase 2 response
function parsePhase2Response(text: string): { hook_alternatives: HookAlternative[]; why_not_working: string[] } {
  // deno-lint-ignore no-explicit-any
  const parsed = JSON.parse(text) as any;
  return {
    hook_alternatives: parsed.hook_alternatives || [],
    why_not_working: parsed.why_not_working || [],
  };
}

// Custom error class for content blocked
class ContentBlockedError extends Error {
  blockReason: string;
  constructor(blockReason: string) {
    super(`CONTENT_BLOCKED:${blockReason}`);
    this.name = "ContentBlockedError";
    this.blockReason = blockReason;
  }
}

function getResponseTextSafely(response: GenerateContentResult, phaseName: string): string {
  const candidate = response.response.candidates?.[0];
  const promptFeedback = response.response.promptFeedback;
  
  if (promptFeedback?.blockReason) {
    console.error(`⚠️ ${phaseName}: Prompt blocked - reason: ${promptFeedback.blockReason}`);
    throw new ContentBlockedError(promptFeedback.blockReason);
  }
  
  if (candidate?.finishReason === "SAFETY" || candidate?.finishReason === "OTHER") {
    const blockReason = candidate.finishReason;
    console.error(`⚠️ ${phaseName}: Response blocked - reason: ${blockReason}`);
    throw new ContentBlockedError(blockReason);
  }
  
  try {
    return response.response.text();
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    if (errorMessage.includes("blocked") || errorMessage.includes("Text not available")) {
      const reasonMatch = errorMessage.match(/blocked due to (\w+)/i);
      const blockReason = reasonMatch?.[1] || "UNKNOWN";
      throw new ContentBlockedError(blockReason);
    }
    throw error;
  }
}

// ═══════════════════════════════════════════════════════════
// GEMINI CALL WITH KEEP-ALIVE
// ═══════════════════════════════════════════════════════════
async function callGeminiWithKeepAlive<T>(
  model: GenerativeModel,
  prompt: string,
  videoPart: Part,
  phaseName: string,
  sse: SSEWriter,
  parseResponse: (text: string) => T
): Promise<{ result: T; tokenUsage: PhaseTokenUsage; retryCount: number }> {
  // Start keep-alive interval (every 10 seconds)
  const keepAliveInterval = setInterval(() => {
    console.log(`💓 ${phaseName}: Sending keep-alive`);
    sse.sendKeepAlive();
  }, 10000);

  try {
    const { result: response, retryCount } = await withRetry(
      async () => {
        return await model.generateContent([prompt, videoPart]);
      },
      phaseName
    );

    const responseText = getResponseTextSafely(response, phaseName);
    const parsed = parseResponse(responseText);

    // Gemini 2.5 usageMetadata fields:
    //   promptTokenCount        → input (video + audio + text prompt)
    //   candidatesTokenCount    → visible output text
    //   thoughtsTokenCount      → internal reasoning (billed as output on 2.5)
    //   cachedContentTokenCount → subset of input that hit context cache
    //   totalTokenCount         → authoritative billing total
    // The SDK type def is behind the API, so read the extra fields off an
    // `any`-cast object.
    // deno-lint-ignore no-explicit-any
    const usage = (response.response.usageMetadata || {}) as any;
    const inputTokens = usage.promptTokenCount || 0;
    const outputTokens = usage.candidatesTokenCount || 0;
    const thinkingTokens = usage.thoughtsTokenCount || 0;
    const cachedInputTokens = usage.cachedContentTokenCount || 0;
    // Prefer the API-reported total; fall back to a computed sum if absent.
    const totalTokens = usage.totalTokenCount || (inputTokens + outputTokens + thinkingTokens);

    const tokenUsage: PhaseTokenUsage = {
      inputTokens,
      outputTokens,
      thinkingTokens,
      cachedInputTokens,
      totalTokens,
    };

    // Sanity check: warn if API total disagrees with our component sum by >1
    // token. This catches silent SDK/schema changes (e.g. new billed buckets).
    const componentSum = inputTokens + outputTokens + thinkingTokens;
    if (usage.totalTokenCount && Math.abs(componentSum - usage.totalTokenCount) > 1) {
      console.warn(
        `⚠️ ${phaseName}: token component mismatch — ` +
        `prompt(${inputTokens}) + output(${outputTokens}) + thinking(${thinkingTokens}) = ${componentSum}, ` +
        `but API reported totalTokenCount=${usage.totalTokenCount}. ` +
        `Raw usageMetadata: ${JSON.stringify(usage)}`
      );
    }

    return { result: parsed, tokenUsage, retryCount };
  } finally {
    clearInterval(keepAliveInterval);
  }
}

// Main handler
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }

  // Create SSE stream
  let sseWriter: SSEWriter | null = null;
  
  const stream = new ReadableStream({
    start(controller) {
      sseWriter = createSSEWriter(controller);
    },
  });

  // Start processing in the background
  const processVideo = async () => {
    if (!sseWriter) return;
    
    try {
      const body = await req.json();
      const { video_path, video_duration_seconds, bucket } = body;

      if (!video_path || !bucket) {
        sseWriter.sendEvent("error", { error: "Missing video_path or bucket", error_code: "INVALID_REQUEST" });
        sseWriter.close();
        return;
      }

      console.log(`Processing video: ${video_path} from bucket: ${bucket}`);
      sseWriter.sendEvent("progress", { status: "starting", progress: 0 });

      const tokenUsage: TokenUsage = {
        phase1: emptyPhaseTokenUsage(),
        phase2: emptyPhaseTokenUsage(),
        total: emptyPhaseTokenUsage(),
      };
      
      const retryInfo: RetryInfo = { phase1Retries: 0, phase2Retries: 0 };

      console.log("Creating Supabase client...");
      const supabase = createSupabaseClient();

      // Step 1: Download video from storage
      sseWriter.sendEvent("progress", { status: "downloading", progress: 5 });
      console.log(`Downloading video from bucket: ${bucket}, path: ${video_path}`);
      
      const { data: videoData, error: downloadError } = await supabase.storage
        .from(bucket)
        .download(video_path);

      if (downloadError || !videoData) {
        console.error("Download error:", downloadError);
        sseWriter.sendEvent("error", { error: "Failed to download video", error_code: "DOWNLOAD_FAILED" });
        sseWriter.close();
        return;
      }

      const videoSizeBytes = videoData.size;
      const videoSizeMB = (videoSizeBytes / (1024 * 1024)).toFixed(2);
      console.log(`Video downloaded: ${videoSizeBytes} bytes (${videoSizeMB} MB)`);

      // Step 2: Fetch techniques and niches
      sseWriter.sendEvent("progress", { status: "loading_data", progress: 10 });
      const [techniques, niches] = await Promise.all([
        fetchTechniques(supabase),
        fetchNiches(supabase),
      ]);

      console.log(`Loaded ${techniques.length} techniques, ${niches.length} niches`);

      // Step 3: Convert video to Base64
      sseWriter.sendEvent("progress", { status: "encoding", progress: 15 });
      console.log("═══════════════════════════════════════════════════════════");
      console.log("📤 Converting video to Base64 for inline upload");
      console.log("═══════════════════════════════════════════════════════════");
      
      const startConversion = Date.now();
      const videoArrayBuffer = await videoData.arrayBuffer();
      const videoBytes = new Uint8Array(videoArrayBuffer);
      const videoBase64 = uint8ArrayToBase64(videoBytes);
      const conversionTime = ((Date.now() - startConversion) / 1000).toFixed(2);
      
      console.log(`✅ Base64 conversion complete in ${conversionTime}s (${(videoBase64.length / (1024 * 1024)).toFixed(2)} MB encoded)`);

      // Step 4: Initialize Gemini models
      const genAI = getGeminiClient();
      
      const modelPhase1 = genAI.getGenerativeModel({ 
        model: "gemini-2.5-flash-lite",
        generationConfig: {
          temperature: 0.4,
          topP: 0.80,
          maxOutputTokens: 2048,
          responseMimeType: "application/json",
          responseSchema: phase1ResponseSchema,
        },
      });
      
      // Phase 2 model is created later (after scriptLen is known) so the
      // schema can carry a duration-proportional minLength on script_after_hook.

      const videoPart: Part = {
        inlineData: {
          mimeType: "video/mp4",
          data: videoBase64,
        },
      };

      // Step 5: PHASE 1 - Analysis & Scoring (with keep-alive)
      sseWriter.sendEvent("progress", { status: "phase1_start", progress: 20 });
      console.log("═══════════════════════════════════════════════════════════");
      console.log("🚀 Starting Phase 1: Analysis & Scoring (SSE with keep-alive)");
      console.log("═══════════════════════════════════════════════════════════");
      
      const phase1StartTime = Date.now();
      const phase1Prompt = buildPhase1Prompt(techniques, niches, video_duration_seconds || 30);
      
      const phase1Result = await callGeminiWithKeepAlive(
        modelPhase1,
        phase1Prompt,
        videoPart,
        "Phase 1 (Analysis)",
        sseWriter,
        parsePhase1Response
      );
      
      const phase1 = phase1Result.result;
      tokenUsage.phase1 = phase1Result.tokenUsage;
      retryInfo.phase1Retries = phase1Result.retryCount;
      
      const phase1Duration = ((Date.now() - phase1StartTime) / 1000).toFixed(2);
      
      console.log("═══════════════════════════════════════════════════════════");
      console.log("📊 PHASE 1 TOKEN USAGE:");
      console.log(`   Input tokens:    ${tokenUsage.phase1.inputTokens.toLocaleString()}` +
        (tokenUsage.phase1.cachedInputTokens > 0
          ? `  (cached: ${tokenUsage.phase1.cachedInputTokens.toLocaleString()})`
          : ""));
      console.log(`   Output tokens:   ${tokenUsage.phase1.outputTokens.toLocaleString()}`);
      console.log(`   Thinking tokens: ${tokenUsage.phase1.thinkingTokens.toLocaleString()}`);
      console.log(`   Total tokens:    ${tokenUsage.phase1.totalTokens.toLocaleString()}  (API-reported)`);
      console.log(`   Retries used:    ${retryInfo.phase1Retries}`);
      console.log(`   Duration:        ${phase1Duration}s`);
      console.log("═══════════════════════════════════════════════════════════");
      
      console.log("Phase 1 parsed:", JSON.stringify(phase1, null, 2));
      sseWriter.sendEvent("progress", { status: "phase1_complete", progress: 50 });

      // Step 6: Get niche benchmark
      let matchedNiche = niches.find(n => n.slug.toLowerCase() === phase1.nicheSlug.toLowerCase());
      
      if (!matchedNiche) {
        console.warn(`⚠️ Invalid niche slug: "${phase1.nicheSlug}" - attempting fuzzy match...`);
        const searchTerms = phase1.nicheSlug.toLowerCase().replace(/_/g, ' ').split(' ');
        matchedNiche = niches.find(n => {
          const nicheWords = n.slug.toLowerCase().replace(/_/g, ' ');
          return searchTerms.some(term => term.length > 3 && nicheWords.includes(term));
        });
        
        if (matchedNiche) {
          console.log(`✅ Fuzzy matched to: "${matchedNiche.slug}"`);
          phase1.nicheSlug = matchedNiche.slug;
        } else {
          const defaultSlug = "relatable_pov_comedy";
          matchedNiche = niches.find(n => n.slug === defaultSlug);
          phase1.nicheSlug = defaultSlug;
        }
      }
      
      const nicheBenchmark = matchedNiche?.avg_hook_score || 75;
      const nicheTiktokEngagement = matchedNiche?.tiktok_engagement ?? null;
      const nicheInstagramEngagement = matchedNiche?.instagram_engagement ?? null;
      const nicheYoutubeEngagement = matchedNiche?.youtube_engagement ?? null;
      
      let nicheAvgEngagement: number | null = null;
      const engagementValues = [nicheTiktokEngagement, nicheInstagramEngagement, nicheYoutubeEngagement].filter(v => v !== null) as number[];
      if (engagementValues.length > 0) {
        nicheAvgEngagement = engagementValues.reduce((a, b) => a + b, 0) / engagementValues.length;
      }
      
      console.log(`Niche: ${phase1.nicheSlug}, Benchmark: ${nicheBenchmark}`);

      // Step 7: PHASE 2 - Improvements (with keep-alive)
      sseWriter.sendEvent("progress", { status: "phase2_start", progress: 55 });
      console.log("═══════════════════════════════════════════════════════════");
      console.log("🚀 Starting Phase 2: Improvements (SSE with keep-alive)");
      console.log("═══════════════════════════════════════════════════════════");
      
      const phase2StartTime = Date.now();
      const phase2VideoDuration = video_duration_seconds || 30;
      const phase2ScriptLen = computeScriptWordTarget(phase2VideoDuration);
      // Char floor uses ~5.5 chars/word (English avg incl. spaces). Slight
      // undershoot is fine — char-min is a safety net; the prompt drives target.
      const phase2ScriptMinChars = Math.round(phase2ScriptLen.min * 5.5);
      console.log(`📏 Phase 2 script budget: target=${phase2ScriptLen.target}w, range=${phase2ScriptLen.min}-${phase2ScriptLen.max}w, schema minChars=${phase2ScriptMinChars}`);

      const modelPhase2 = genAI.getGenerativeModel({
        model: "gemini-3.1-flash-lite",
        generationConfig: {
          temperature: 0.7,
          topP: 0.90,
          maxOutputTokens: 12288,
          responseMimeType: "application/json",
          responseSchema: buildPhase2ResponseSchema(phase2ScriptMinChars),
        },
      });

      const phase2Prompt = buildPhase2Prompt(phase1, techniques, nicheBenchmark, phase2VideoDuration);

      const phase2Result = await callGeminiWithKeepAlive(
        modelPhase2,
        phase2Prompt,
        videoPart,
        "Phase 2 (Improvements)",
        sseWriter,
        parsePhase2Response
      );
      
      const phase2 = phase2Result.result;
      tokenUsage.phase2 = phase2Result.tokenUsage;
      retryInfo.phase2Retries = phase2Result.retryCount;
      
      const phase2Duration = ((Date.now() - phase2StartTime) / 1000).toFixed(2);
      
      console.log("═══════════════════════════════════════════════════════════");
      console.log("📊 PHASE 2 TOKEN USAGE:");
      console.log(`   Input tokens:    ${tokenUsage.phase2.inputTokens.toLocaleString()}` +
        (tokenUsage.phase2.cachedInputTokens > 0
          ? `  (cached: ${tokenUsage.phase2.cachedInputTokens.toLocaleString()})`
          : ""));
      console.log(`   Output tokens:   ${tokenUsage.phase2.outputTokens.toLocaleString()}`);
      console.log(`   Thinking tokens: ${tokenUsage.phase2.thinkingTokens.toLocaleString()}`);
      console.log(`   Total tokens:    ${tokenUsage.phase2.totalTokens.toLocaleString()}  (API-reported)`);
      console.log(`   Retries used:    ${retryInfo.phase2Retries}`);
      console.log(`   Duration:        ${phase2Duration}s`);
      console.log("═══════════════════════════════════════════════════════════");

      tokenUsage.total.inputTokens       = tokenUsage.phase1.inputTokens       + tokenUsage.phase2.inputTokens;
      tokenUsage.total.outputTokens      = tokenUsage.phase1.outputTokens      + tokenUsage.phase2.outputTokens;
      tokenUsage.total.thinkingTokens    = tokenUsage.phase1.thinkingTokens    + tokenUsage.phase2.thinkingTokens;
      tokenUsage.total.cachedInputTokens = tokenUsage.phase1.cachedInputTokens + tokenUsage.phase2.cachedInputTokens;
      tokenUsage.total.totalTokens       = tokenUsage.phase1.totalTokens       + tokenUsage.phase2.totalTokens;

      // Billable buckets per Gemini pricing:
      //   - input  = promptTokenCount (cached portion priced lower)
      //   - output = candidatesTokenCount + thoughtsTokenCount
      const billableOutput = tokenUsage.total.outputTokens + tokenUsage.total.thinkingTokens;

      console.log("═══════════════════════════════════════════════════════════");
      console.log("📊 TOTAL TOKEN USAGE (Gemini 2.5 billing breakdown):");
      console.log(`   Input tokens:           ${tokenUsage.total.inputTokens.toLocaleString()}`);
      console.log(`     of which cached:      ${tokenUsage.total.cachedInputTokens.toLocaleString()}`);
      console.log(`   Output (response):      ${tokenUsage.total.outputTokens.toLocaleString()}`);
      console.log(`   Output (thinking):      ${tokenUsage.total.thinkingTokens.toLocaleString()}`);
      console.log(`   Billable output total:  ${billableOutput.toLocaleString()}  (response + thinking)`);
      console.log(`   API total tokens:       ${tokenUsage.total.totalTokens.toLocaleString()}`);
      console.log("═══════════════════════════════════════════════════════════");

      sseWriter.sendEvent("progress", { status: "phase2_complete", progress: 85 });

      // Step 8: Match viral examples to alternatives
      sseWriter.sendEvent("progress", { status: "matching_examples", progress: 90 });
      const viralExampleMatches = await matchViralExamples(
        supabase,
        phase1.nicheSlug,
        niches,
        techniques,
        phase2.hook_alternatives
      );

      const alternativesWithExamples = phase2.hook_alternatives.map((alt, index) => ({
        ...alt,
        viral_example: viralExampleMatches[index] || null,
      }));

      // Step 9: Build final response
      const response = {
        detected_language: phase1.detectedLanguage,
        audio_type: phase1.audioType,
        voice_percentage: phase1.voicePercentage,
        niche_slug: phase1.nicheSlug,
        niche_name: matchedNiche?.name || null,
        niche_category: matchedNiche?.category || null,
        overall_score: phase1.overallScore,
        audio_score: phase1.audioScore,
        audio_score_raw: phase1.audioScoreRaw,
        visual_score: phase1.visualScore,
        benchmark: nicheBenchmark,
        current_hook_quote: phase1.currentHookQuote,
        audio_feedback: phase1.audioFeedback,
        visual_feedback: phase1.visualFeedback,
        niche_tiktok_engagement: nicheTiktokEngagement,
        niche_instagram_engagement: nicheInstagramEngagement,
        niche_youtube_engagement: nicheYoutubeEngagement,
        niche_avg_engagement: nicheAvgEngagement,
        industry_benchmark_tiktok: nicheTiktokEngagement,
        industry_benchmark_instagram: nicheInstagramEngagement,
        industry_benchmark_youtube: nicheYoutubeEngagement,
        industry_benchmark_avg: nicheAvgEngagement,
        why_not_working: phase2.why_not_working,
        voice_start_seconds: phase1.voiceStartSeconds,
        is_voice_late: phase1.isVoiceLate,
        audio_penalty: phase1.audioPenalty,
        hook_alternatives: alternativesWithExamples,
        token_usage: tokenUsage,
        retry_info: retryInfo,
        upload_method: "base64_inline_sse",
      };

      // Step 10: Cleanup - delete video from Supabase storage
      sseWriter.sendEvent("progress", { status: "cleanup", progress: 95 });
      try {
        await supabase.storage.from(bucket).remove([video_path]);
        console.log(`🗑️ Deleted Supabase video: ${video_path}`);
      } catch (deleteError) {
        console.error("Failed to delete Supabase video:", deleteError);
      }

      console.log("✅ Analysis complete (SSE with keep-alive)!");

      // Send final result
      sseWriter.sendEvent("complete", response);
      sseWriter.close();

    } catch (error: unknown) {
      console.error("❌ Error:", error);
      
      let errorMessage = "Analysis failed";
      let errorCode = "ANALYSIS_FAILED";
      
      if (error instanceof Error) {
        if (error instanceof ContentBlockedError || 
            error.message.includes("CONTENT_BLOCKED") || 
            error.message.includes("blocked") ||
            error.message.includes("Text not available")) {
          errorMessage = "Our AI detected content it cannot process. Videos with sensitive imagery, explicit material, or protected content may be restricted. Try a different video.";
          errorCode = "CONTENT_BLOCKED";
        } else if (isRetryableError(error)) {
          errorMessage = "Service temporarily unavailable due to high demand. Please try again in a few moments.";
          errorCode = "SERVICE_OVERLOADED";
        } else {
          errorMessage = error.message;
        }
      }
      
      if (sseWriter) {
        sseWriter.sendEvent("error", { error: errorMessage, error_code: errorCode });
        sseWriter.close();
      }
    }
  };

  // Start processing without blocking the response
  processVideo();

  return new Response(stream, { headers: SSE_HEADERS });
});