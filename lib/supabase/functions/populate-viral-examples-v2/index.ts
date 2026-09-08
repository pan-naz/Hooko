import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Max-Age": "86400",
};

// ════════════════════════════════════════════════════════════════════
// CONFIG - Hard filters (applied to YouTube search results)
// ════════════════════════════════════════════════════════════════════
const MIN_LIKES = 1_000;
const MAX_DURATION_SECONDS = 120; // < 2 minutes
const MAX_AGE_YEARS = 1;
const FINAL_WINNERS = 3;          // Gemini picks 3 winners from clean pool
const TIME_BUDGET_MS = 395_000; // ~Supabase Edge Function max wall-clock (400s); leave 5s headroom to return response

interface Niche {
  id: string;
  name: string;
  search_keywords: string;
  video_count: number;
}

interface Technique {
  id: string;
  name: string;
  type: string;
  category: string;
  description: string;
}

interface Candidate {
  videoId: string;
  title: string;
  description: string;
  thumbnailUrl: string;
  channelTitle: string;
  publishedAt: string;
  viewCount: number;
  likeCount: number;
  durationSeconds: number;
  isVertical: boolean;
}

class QuotaExhaustedError extends Error {
  constructor(message: string) { super(message); this.name = "QuotaExhaustedError"; }
}

function isQuotaExhaustedError(error: { code?: number; message?: string; errors?: Array<{ reason?: string }> }): boolean {
  if (error.code === 403) {
    const reasons = ["quotaExceeded", "dailyLimitExceeded", "rateLimitExceeded", "userRateLimitExceeded"];
    if (error.errors?.some(e => reasons.includes(e.reason || ""))) return true;
    if (error.message?.toLowerCase().match(/quota|limit exceeded/)) return true;
  }
  return false;
}

function parseDurationToSeconds(duration: string): number {
  if (!duration) return 0;
  const m = duration.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/);
  if (!m) return 0;
  return (parseInt(m[1] || "0") * 3600) + (parseInt(m[2] || "0") * 60) + parseInt(m[3] || "0");
}

function shuffleArray<T>(arr: T[]): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

async function callGemini(geminiUrl: string, prompt: string, maxTokens: number, temp = 0.2): Promise<string> {
  const r = await fetch(geminiUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: { maxOutputTokens: maxTokens, temperature: temp }
    }),
  });
  const d = await r.json();
  if (d.error) {
    console.error("Gemini error:", d.error);
    return "";
  }
  return d.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || "";
}

// Structured JSON Gemini call — guarantees parseable output (no regex guessing).
async function callGeminiJson<T = unknown>(
  geminiUrl: string,
  prompt: string,
  maxTokens: number,
  schema: Record<string, unknown>,
  temp = 0.2
): Promise<T | null> {
  try {
    const r = await fetch(geminiUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          maxOutputTokens: maxTokens,
          temperature: temp,
          responseMimeType: "application/json",
          responseSchema: schema,
        }
      }),
    });
    const d = await r.json();
    if (d.error) {
      console.error("Gemini JSON error:", d.error);
      return null;
    }
    const txt = d.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || "";
    const finishReason = d.candidates?.[0]?.finishReason;
    if (!txt) {
      console.error("Gemini JSON empty response. finishReason:", finishReason);
      return null;
    }
    // Sanitize: strip markdown code fences and isolate the JSON payload.
    const cleaned = extractJsonPayload(txt);
    if (!cleaned) {
      console.error("Gemini JSON no payload found. finishReason:", finishReason, "raw:", txt.substring(0, 200));
      return null;
    }
    try {
      return JSON.parse(cleaned) as T;
    } catch (e) {
      console.error("Gemini JSON parse fail:", (e as Error).message, "finishReason:", finishReason, "cleaned:", cleaned.substring(0, 200));
      return null;
    }
  } catch (e) {
    console.error("Gemini JSON request fail:", (e as Error).message);
    return null;
  }
}

// Extract the first balanced JSON object/array from a string,
// stripping markdown fences (```json ... ```) and surrounding prose.
function extractJsonPayload(raw: string): string | null {
  let s = raw.trim();
  // Strip leading/trailing markdown code fence
  s = s.replace(/^```(?:json)?\s*/i, "").replace(/```\s*$/i, "").trim();
  if (!s) return null;
  // Fast path: already starts with { or [
  if (s.startsWith("{") || s.startsWith("[")) {
    // Find balanced end
    const end = findBalancedEnd(s);
    if (end > 0) return s.substring(0, end);
    return s; // best effort
  }
  // Find first { or [ and isolate from there
  const objStart = s.indexOf("{");
  const arrStart = s.indexOf("[");
  const start = objStart === -1 ? arrStart : arrStart === -1 ? objStart : Math.min(objStart, arrStart);
  if (start === -1) return null;
  const sub = s.substring(start);
  const end = findBalancedEnd(sub);
  return end > 0 ? sub.substring(0, end) : sub;
}

function findBalancedEnd(s: string): number {
  const open = s[0];
  if (open !== "{" && open !== "[") return -1;
  const close = open === "{" ? "}" : "]";
  let depth = 0;
  let inStr = false;
  let esc = false;
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (inStr) {
      if (esc) esc = false;
      else if (c === "\\") esc = true;
      else if (c === '"') inStr = false;
      continue;
    }
    if (c === '"') { inStr = true; continue; }
    if (c === open) depth++;
    else if (c === close) {
      depth--;
      if (depth === 0) return i + 1;
    }
  }
  return -1;
}

// ════════════════════════════════════════════════════════════════════
// BATCH VERTICAL CHECK — VISION based.
// Fetches each thumbnail as bytes and sends them inline to Gemini so the
// model can VISUALLY inspect aspect ratio (vertical Shorts thumbnails
// stored as 16:9 have black/blurred bars on left+right).
// Processed in sub-batches of SUB_BATCH to keep payload size reasonable.
// ════════════════════════════════════════════════════════════════════
async function fetchImageAsInline(url: string): Promise<{ mimeType: string; data: string } | null> {
  try {
    const r = await fetch(url);
    if (!r.ok) return null;
    const buf = new Uint8Array(await r.arrayBuffer());
    const mimeType = (r.headers.get("content-type") || "image/jpeg").split(";")[0].trim();
    // base64 encode
    let bin = "";
    const CHUNK = 0x8000;
    for (let i = 0; i < buf.length; i += CHUNK) {
      bin += String.fromCharCode.apply(null, Array.from(buf.subarray(i, i + CHUNK)));
    }
    return { mimeType, data: btoa(bin) };
  } catch { return null; }
}

async function batchCheckVertical(
  videos: Array<{ videoId: string; title: string; thumbnailUrl: string }>,
  geminiUrl: string,
  runId: string
): Promise<Set<string>> {
  const SUB_BATCH = 10;
  const set = new Set<string>();
  let analyzed = 0, imgFailed = 0;

  const schema = {
    type: "object",
    properties: {
      results: {
        type: "array",
        items: {
          type: "object",
          properties: {
            i: { type: "integer" },
            vertical: { type: "boolean" },
          },
          required: ["i", "vertical"],
        },
      },
    },
    required: ["results"],
  };

  for (let off = 0; off < videos.length; off += SUB_BATCH) {
    const chunk = videos.slice(off, off + SUB_BATCH);
    const images = await Promise.all(chunk.map(v => fetchImageAsInline(v.thumbnailUrl)));

    const parts: Array<Record<string, unknown>> = [];
    parts.push({
      text:
`You will see ${chunk.length} YouTube thumbnails (numbered ${1}..${chunk.length}).
For EACH image decide if the ORIGINAL video is VERTICAL (9:16 portrait — a YouTube Short / Reel) or HORIZONTAL (16:9 landscape).

Visual signals for VERTICAL:
- The thumbnail is stored as 16:9 but has clear black, blurred, or solid-color BARS on the LEFT and RIGHT sides, with portrait content centered.
- Subject/person fills a tall narrow column in the middle.
- The whole image is itself portrait orientation.

Visual signals for HORIZONTAL:
- Full-frame 16:9 imagery with no side bars.
- Subject/scene spans the full width.

Reply with JSON: { "results": [ { "i": <1-based number>, "vertical": <true|false> }, ... ] }
Return one entry per image, in order. If an image is unclear, choose the most likely answer.`,
    });

    for (let i = 0; i < chunk.length; i++) {
      const img = images[i];
      parts.push({ text: `--- Image ${i + 1} ---` });
      if (img) {
        parts.push({ inlineData: { mimeType: img.mimeType, data: img.data } });
      } else {
        imgFailed++;
        parts.push({ text: "(image unavailable — answer false)" });
      }
    }

    try {
      const r = await fetch(geminiUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts }],
          generationConfig: {
            maxOutputTokens: 2000,
            temperature: 0.1,
            responseMimeType: "application/json",
            responseSchema: schema,
          },
        }),
      });
      const d = await r.json();
      if (d.error) {
        console.error(`[${runId}]   vision chunk err:`, d.error.message);
        continue;
      }
      const txt = d.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || "";
      const payload = extractJsonPayload(txt);
      if (!payload) {
        console.error(`[${runId}]   vision chunk: no JSON payload`);
        continue;
      }
      const parsed = JSON.parse(payload) as { results?: Array<{ i: number; vertical: boolean }> };
      for (const row of parsed.results || []) {
        const idx = (row.i - 1);
        if (idx >= 0 && idx < chunk.length) {
          analyzed++;
          if (row.vertical === true) set.add(chunk[idx].videoId);
        }
      }
    } catch (e) {
      console.error(`[${runId}]   vision chunk parse err:`, (e as Error).message);
    }
  }

  console.log(`[${runId}]   📐 Vision vertical: ${set.size}/${videos.length} vertical (analyzed=${analyzed}, img_failed=${imgFailed})`);
  return set;
}

// ════════════════════════════════════════════════════════════════════
// BATCH ENGLISH + RELEVANCE check on TITLES (one Gemini call)
// ════════════════════════════════════════════════════════════════════
async function batchCheckEnglishRelevance(
  candidates: Candidate[],
  nicheName: string,
  geminiUrl: string,
  runId: string
): Promise<boolean[]> {
  const prompt = `You are a STRICT content validator for "${nicheName}" niche - NATIVE ENGLISH audience only (US/UK/CA/AU style).

REJECT if title OR channel name shows ANY of:
- Non-Latin script (हिंदी, தமிழ், 中文, العربية, ગુજરાતી, ਪੰਜਾਬੀ, etc.)
- Transliterated non-English in Latin script:
  • Hindi/Urdu: "Bhai/Yaar/Bahut/Accha/Mast/Mazaa/Kya baat/Zindagi/Pyaar/Dosti/Paisa"
  • Tamil: "Vera level/Semma/Thalaiva/Macha/Iruku/Enna koduma/Mass entry"
  • Telugu/Kannada/Malayalam: "Anna/Bava/Mawa"
  • Indonesian/Filipino: "Mantap/Keren/Galing/Astig/Sobrang/Grabe"
  • Spanish: "Increíble/Hermoso/Qué bonito/Muy bueno"
  • Portuguese: "Muito bom/Parabéns/Maravilhoso/Que legal"
  • Turkish/Arabic transliterations
- Mixed English with non-English slang ("Super ah iruku", "Mass entry", "Bhai ka video")
- Channel name suggesting non-English audience (e.g. contains "Hindi", "Tamil", "Bharti", "Desi", "India Vlogs", "Bollywood", "Bharat", etc.)
- NOT directly about "${nicheName}"

When in doubt → FAIL. Better to lose a borderline video than admit a non-English one.

CANDIDATES (${candidates.length}):
${candidates.map((v, i) => `${i + 1}. "${v.title}" | ch: "${v.channelTitle}" | views: ${v.viewCount.toLocaleString()}`).join("\n")}

Reply EXACTLY one line per candidate: "N. PASS" or "N. FAIL - reason"`;

  const txt = await callGemini(geminiUrl, prompt, 4000, 0.1);
  const lines = txt.split("\n").filter(l => l.trim());
  const results: boolean[] = [];
  let pass = 0;
  for (let i = 0; i < candidates.length; i++) {
    const line = lines.find(l => new RegExp(`^${i + 1}[\\.\\)]?\\s`, "i").test(l.trim()));
    const upper = (line || "").toUpperCase();
    const ok = upper.includes("PASS") && !upper.includes("FAIL");
    results.push(ok);
    if (ok) pass++;
  }
  console.log(`[${runId}]   ✅ Title+English+relevance: ${pass}/${candidates.length} pass`);
  return results;
}

// ════════════════════════════════════════════════════════════════════
// Pick top FINAL_WINNERS from clean pool in ONE Gemini call
// ════════════════════════════════════════════════════════════════════
async function pickWinners(
  pool: Candidate[],
  nicheName: string,
  count: number,
  geminiUrl: string,
  runId: string
): Promise<number[]> {
  if (pool.length <= count) return pool.map((_, i) => i);

  const prompt = `Select the ${count} BEST viral YouTube Shorts for "${nicheName}" niche.
All candidates already passed: vertical, English (title + comments), directly relevant, recent, high engagement.

Choose based on: strong hook potential, clarity, engagement (views×likes), diversity.

CANDIDATES (${pool.length}):
${pool.map((v, i) => `${i + 1}. "${v.title}" — ${v.viewCount.toLocaleString()} views / ${v.likeCount.toLocaleString()} likes (${v.channelTitle})`).join("\n")}

Return JSON: { "winners": [<${count} candidate numbers, 1-based, no duplicates>] }`;

  const schema = {
    type: "object",
    properties: {
      winners: {
        type: "array",
        items: { type: "integer" },
        minItems: count,
        maxItems: count,
      },
    },
    required: ["winners"],
  };

  const collect = (raw: number[]): number[] => {
    const out: number[] = [];
    for (const n of raw) {
      const idx = n - 1;
      if (idx >= 0 && idx < pool.length && !out.includes(idx)) out.push(idx);
      if (out.length === count) break;
    }
    return out;
  };

  // Attempt 1 — structured JSON
  let unique: number[] = [];
  let source = "json";
  const json = await callGeminiJson<{ winners: number[] }>(geminiUrl, prompt, 1000, schema, 0.3);
  if (json?.winners?.length) unique = collect(json.winners);

  // Attempt 2 — structured JSON retry with higher temp (in case model gave duplicates / short list)
  if (unique.length < count) {
    const retry = await callGeminiJson<{ winners: number[] }>(geminiUrl, prompt, 1000, schema, 0.5);
    if (retry?.winners?.length) {
      const merged = collect([...unique.map(i => i + 1), ...retry.winners]);
      if (merged.length > unique.length) {
        unique = merged;
        source = "json-retry";
      }
    }
  }

  // Attempt 3 — plain-text fallback with regex parsing (legacy path)
  if (unique.length < count) {
    const txt = await callGemini(geminiUrl, prompt + "\n(If JSON failed, reply ONLY with comma-separated numbers.)", 1000, 0.3);
    const nums = txt.match(/\d+/g)?.map(s => parseInt(s)) || [];
    const merged = collect([...unique.map(i => i + 1), ...nums]);
    if (merged.length > unique.length) {
      unique = merged;
      source = "regex-fallback";
    }
  }

  // Last resort — top-up by view ranking so we never return fewer than `count`
  if (unique.length < count) {
    const byViews = [...pool.keys()].sort((a, b) => pool[b].viewCount - pool[a].viewCount);
    for (const idx of byViews) {
      if (unique.length >= count) break;
      if (!unique.includes(idx)) unique.push(idx);
    }
    source = unique.length === count ? `${source}+view-rank-topup` : source;
  }

  console.log(`[${runId}]   🏆 Winners (${source}): indices ${unique.join(",")}`);
  return unique.slice(0, count);
}

// ════════════════════════════════════════════════════════════════════
// MAIN HANDLER
// ════════════════════════════════════════════════════════════════════
serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: CORS_HEADERS });

  const startTime = Date.now();
  const runId = `run_${Date.now().toString(36)}`;

  let quotaExhausted = false;
  let quotaMsg = "";
  const results: Array<Record<string, unknown>> = [];
  let totalAdded = 0;
  let totalFailed = 0;
  let nichesProcessed = 0;

  try {
    console.log(`\n${"=".repeat(60)}\n[${runId}] 🚀 POPULATE VIRAL EXAMPLES V2 (upfront comment check)\n${"=".repeat(60)}`);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const youtubeApiKey = Deno.env.get("YOUTUBE_API_KEY")!;
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY")!;
    if (!youtubeApiKey || !geminiApiKey) throw new Error("Missing API keys");

    let exactNiches = 7;
    let exactVideos = 3;
    try {
      const body = await req.json();
      if (typeof body.exactNiches === "number") exactNiches = Math.min(Math.max(body.exactNiches, 1), 30);
      if (typeof body.exactVideos === "number") exactVideos = Math.min(Math.max(body.exactVideos, 1), 5);
    } catch { /* defaults */ }
    console.log(`[${runId}] 🎯 Config: ${exactNiches} niches × up to ${exactVideos} videos`);

    const supabase = createClient(supabaseUrl, supabaseKey);

    // Fetch niches
    const { data: niches, error: nichesErr } = await supabase.from("niches").select("id, name, slug");
    if (nichesErr) throw nichesErr;
    if (!niches?.length) {
      return new Response(JSON.stringify({ success: false, error: "No niches" }),
        { headers: { ...CORS_HEADERS, "Content-Type": "application/json" } });
    }

    // Fetch techniques
    const { data: techData } = await supabase.from("techniques").select("id, name, type, category, description");
    const allTechniques: Technique[] = techData || [];
    console.log(`[${runId}] 📚 ${allTechniques.length} techniques loaded`);

    // Count videos per niche (for level-based selection)
    const nichesWithCounts: Niche[] = [];
    for (const n of niches) {
      const { count } = await supabase.from("viral_examples").select("*", { count: "exact", head: true }).eq("niche_id", n.id);
      nichesWithCounts.push({
        id: n.id, name: n.name,
        search_keywords: n.slug.replace(/[-_]/g, " "),
        video_count: count || 0,
      });
    }

    // Select lowest-count niches first, randomized within levels
    const sorted = [...nichesWithCounts].sort((a, b) => a.video_count - b.video_count);
    const byLevel = new Map<number, Niche[]>();
    sorted.forEach(n => {
      const arr = byLevel.get(n.video_count) || [];
      arr.push(n); byLevel.set(n.video_count, arr);
    });
    const nichesToProcess: Niche[] = [];
    for (const lvl of [...byLevel.keys()].sort((a, b) => a - b)) {
      if (nichesToProcess.length >= exactNiches) break;
      nichesToProcess.push(...shuffleArray(byLevel.get(lvl) || []).slice(0, exactNiches - nichesToProcess.length));
    }
    console.log(`[${runId}] 📋 Selected ${nichesToProcess.length} niches`);

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=${geminiApiKey}`;

    // ── LLM-generated YouTube Shorts search queries (fresh per invocation) ──
    // For each selected niche, ask Gemini to produce 3–5 short search queries
    // that match real Shorts titles / creator vocabulary. We then pick ONE at
    // random per niche per run -> different queries each invocation.
    const keywordsByNicheId = new Map<string, string[]>();
    try {
      const currentYear = new Date().getUTCFullYear();
      const kwPrompt = `You generate YouTube Shorts search queries.

For each niche below, return 3-5 short search queries (2-5 words each) that real Shorts viewers/creators would type or that appear in real Shorts titles. Mix formats: hooks, problems, results, "how to", trending phrasings. English only. No hashtags, no quotes, no punctuation. If a query includes a year, it MUST be ${currentYear} (never any other year).

Niches:
${nichesToProcess.map((n, i) => `${i + 1}. id="${n.id}" name="${n.name}" slug="${n.id}"`).join("\n")}

Return JSON: {"niches":[{"id":"<uuid>","queries":["q1","q2","q3"]}, ...]}`;

      const kwSchema = {
        type: "object",
        properties: {
          niches: {
            type: "array",
            items: {
              type: "object",
              properties: {
                id: { type: "string" },
                queries: { type: "array", items: { type: "string" } },
              },
              required: ["id", "queries"],
            },
          },
        },
        required: ["niches"],
      };

      const kwResp = await callGeminiJson<{ niches: Array<{ id: string; queries: string[] }> }>(
        geminiUrl, kwPrompt, 8000, kwSchema, 0.7, // moderate temperature -> fresh but coherent queries
      );
      if (kwResp?.niches) {
        for (const n of kwResp.niches) {
          const cleaned = (n.queries || [])
            .map(q => (q || "").trim())
            // Replace any 4-digit year (2000-2099) with the current year
            .map(q => q.replace(/\b(20\d{2})\b/g, String(currentYear)))
            .filter(q => q.length >= 2 && q.length <= 80);
          if (cleaned.length) keywordsByNicheId.set(n.id, cleaned);
        }
        console.log(`[${runId}] 🧠 Gemini generated keywords for ${keywordsByNicheId.size}/${nichesToProcess.length} niches`);
      } else {
        console.log(`[${runId}] ⚠️ Gemini keyword generation returned nothing - falling back to slugs`);
      }
    } catch (e) {
      console.log(`[${runId}] ⚠️ Keyword generation failed: ${(e as Error).message} - falling back to slugs`);
    }

    // Apply generated keywords (random pick per niche) with slug fallback
    for (const n of nichesToProcess) {
      const list = keywordsByNicheId.get(n.id);
      if (list && list.length) {
        n.search_keywords = list[Math.floor(Math.random() * list.length)];
        console.log(`[${runId}]   🔑 "${n.name}" -> "${n.search_keywords}" (from ${list.length} options)`);
      }
    }

    const maxAgeDate = new Date();
    maxAgeDate.setFullYear(maxAgeDate.getFullYear() - MAX_AGE_YEARS);

    const ENGLISH_CODES = ["en"];
    const NON_ENGLISH_CODES = [
      "hi","ta","te","ml","kn","bn","mr","gu","pa","ur",
      "es","pt","ar","fa","he",
      "zh","ja","ko","vi","th","id","ms",
      "ru","uk","pl","cs","sk",
      "de","fr","it","nl","tr","fil","tl",
    ];

    let timeBudgetExceeded = false;

    nicheLoop:
    for (let i = 0; i < nichesToProcess.length; i++) {
      const niche = nichesToProcess[i];
      const elapsed = Date.now() - startTime;
      console.log(`\n[${runId}] 🔄 [${i + 1}/${nichesToProcess.length}] "${niche.name}" | elapsed=${(elapsed / 1000).toFixed(1)}s`);

      if (elapsed > TIME_BUDGET_MS) {
        timeBudgetExceeded = true;
        console.log(`[${runId}]   ⏰ Time budget exceeded - stopping`);
        break;
      }

      // ── Existing videos ───────────────────────────────
      const { data: existing } = await supabase.from("viral_examples").select("youtube_url").eq("niche_id", niche.id);
      const existingIds = new Set(
        (existing || []).map(v => {
          const m = v.youtube_url?.match(/(?:shorts\/|watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]+)/);
          return m ? m[1] : null;
        }).filter(Boolean)
      );

      // ── YouTube SEARCH (50 candidates) ────────────────
      // publishedAfter = MAX_AGE_YEARS ago (matches hard filter so YouTube prefilters)
      const publishedAfterIso = maxAgeDate.toISOString();
      // NOTE: regionCode removed — we target English audience globally, not a specific country.
      // relevanceLanguage=en stays as a ranking hint toward English content.
      // Negative keywords (`-term`) tell YouTube to exclude videos with these tokens in title/description.
      // Zero extra quota — appended to the existing search query.
      const NEGATIVE_KEYWORDS = [
        // Indian languages
        "hindi","tamil","telugu","punjabi","bhojpuri","urdu","bangla","bengali","malayalam",
        "kannada","marathi","gujarati","india","indian","bollywood","desi","hindustani",
        // SE Asia
        "indonesia","indonesian","filipino","tagalog","vietnam","vietnamese","thai","thailand",
        "malaysia","malaysian",
        // East Asia
        "chinese","mandarin","cantonese","japanese","korean",
        // Middle East
        "arabic","arab","persian","farsi","turkish","hebrew",
        // Latin/Iberian/Slavic
        "espanol","español","spanish","portuguese","português","brasil","brazil","russian",
        "ukraine","ukrainian","polish",
        // Common transliterated giveaways in titles
        "bhai","yaar","semma","thalaiva","mantap","keren",
      ].map(w => `-${w}`).join(" ");
      const searchQuery = `${niche.search_keywords} ${NEGATIVE_KEYWORDS}`;
      const searchUrl = `https://www.googleapis.com/youtube/v3/search?part=snippet&q=${encodeURIComponent(searchQuery)}&type=video&videoDuration=short&relevanceLanguage=en&publishedAfter=${publishedAfterIso}&maxResults=50&order=viewCount&key=${youtubeApiKey}`;
      const searchData = await (await fetch(searchUrl)).json();
      if (searchData.error) {
        if (isQuotaExhaustedError(searchData.error)) { quotaExhausted = true; quotaMsg = searchData.error.message; console.log(`🚨 [${runId}] YOUTUBE QUOTA EXHAUSTED — stopping run. Message: ${quotaMsg}`); break nicheLoop; }
        results.push({ niche: niche.name, status: `YouTube search error: ${searchData.error.message}` });
        totalFailed++; continue;
      }
      const newVids = (searchData.items || []).filter((it: { id: { videoId: string } }) => !existingIds.has(it.id.videoId));
      console.log(`[${runId}]   🔍 ${searchData.items?.length || 0} found / ${newVids.length} new`);
      if (!newVids.length) {
        results.push({ niche: niche.name, status: "No new videos" }); totalFailed++; continue;
      }

      // ── STATS ──────────────────────────────────────────
      const videoIds = newVids.map((it: { id: { videoId: string } }) => it.id.videoId).join(",");
      const statsUrl = `https://www.googleapis.com/youtube/v3/videos?part=statistics,snippet,contentDetails&id=${videoIds}&key=${youtubeApiKey}`;
      const statsData = await (await fetch(statsUrl)).json();
      if (statsData.error) {
        if (isQuotaExhaustedError(statsData.error)) { quotaExhausted = true; quotaMsg = statsData.error.message; console.log(`🚨 [${runId}] YOUTUBE QUOTA EXHAUSTED — stopping run. Message: ${quotaMsg}`); break nicheLoop; }
        results.push({ niche: niche.name, status: `Stats error: ${statsData.error.message}` });
        totalFailed++; continue;
      }
      if (!statsData.items?.length) { results.push({ niche: niche.name, status: "No stats" }); totalFailed++; continue; }

      // ── HARD FILTERS: likes, age, duration, lang metadata, transliteration ──
      // (region restriction filter removed — we now target English audience globally, not US-specific)
      let dropDuration = 0, dropLikes = 0, dropAge = 0, dropLang = 0, dropTranslit = 0;
      const nonLatinRegex = /[\ऀ-\u097F\؀-\u06FF\一-\u9FFF\฀-\u0E7F\Ѐ-\u04FF\u3040-\u309F\u30A0-\u30FF\가-\uD7AF]/;

      // Transliterated non-English giveaways. Word-boundary matched, case-insensitive.
      // Hits drop the video pre-Gemini (saves both Gemini calls + improves precision).
      const translitRegex = new RegExp(
        "\\b(" +
        // Hindi / Urdu
        "bhai|yaar|bahut|accha|acha|mast|mazaa|mazza|kya|baat|dil|dosti|pyaar|pyar|zindagi|" +
        "bhagwan|namaste|namaskar|jai\\s+shri|jai\\s+ho|matlab|paisa|paise|" +
        // Tamil
        "vera\\s+level|semma|thalaiva|thalaivar|macha|machan|enna\\s+koduma|super\\s+ah|" +
        "iruku|irukku|da\\s+mass|mass\\s+entry|" +
        // Telugu / Kannada / Malayalam (common transliterations)
        "anna|bava|mawa|chandamama|" +
        // Indonesian / Filipino
        "mantap|keren|galing|astig|sobrang|grabe|" +
        // Spanish (strong markers)
        "increíble|increible|qué\\s+bonito|muy\\s+bueno|hermoso|que\\s+lindo|" +
        // Portuguese
        "muito\\s+bom|maravilhoso|parabéns|parabens|que\\s+legal|" +
        // Turkish
        "harika|çok\\s+güzel|cok\\s+guzel" +
        ")\\b",
        "i"
      );

      const filtered: Candidate[] = [];
      for (const item of statsData.items as Array<{
        id: string;
        snippet: { title: string; description: string; thumbnails: { high?: { url: string }; default?: { url: string } }; channelTitle: string; publishedAt: string; defaultLanguage?: string; defaultAudioLanguage?: string };
        statistics: { viewCount?: string; likeCount?: string };
        contentDetails?: { duration?: string; regionRestriction?: { allowed?: string[]; blocked?: string[] } };
      }>) {
        const views = parseInt(item.statistics.viewCount || "0");
        const likes = parseInt(item.statistics.likeCount || "0");
        const pub = new Date(item.snippet.publishedAt);
        const dur = parseDurationToSeconds(item.contentDetails?.duration || "");

        if (likes < MIN_LIKES) { dropLikes++; continue; }
        if (pub <= maxAgeDate) { dropAge++; continue; }
        if (!dur || dur > MAX_DURATION_SECONDS) { dropDuration++; continue; }

        const dl = item.snippet.defaultLanguage?.toLowerCase();
        const al = item.snippet.defaultAudioLanguage?.toLowerCase();
        if (dl && NON_ENGLISH_CODES.some(c => dl.startsWith(c))) { dropLang++; continue; }
        if (al && NON_ENGLISH_CODES.some(c => al.startsWith(c))) { dropLang++; continue; }
        if (nonLatinRegex.test(item.snippet.title)) { dropLang++; continue; }

        // Transliterated non-English in title or description (pre-Gemini, free).
        const titleDesc = `${item.snippet.title} ${item.snippet.description || ""}`;
        if (translitRegex.test(titleDesc)) { dropTranslit++; continue; }

        filtered.push({
          videoId: item.id,
          title: item.snippet.title,
          description: item.snippet.description,
          thumbnailUrl: item.snippet.thumbnails?.high?.url || item.snippet.thumbnails?.default?.url || "",
          channelTitle: item.snippet.channelTitle,
          publishedAt: item.snippet.publishedAt,
          viewCount: views,
          likeCount: likes,
          durationSeconds: dur,
          isVertical: false,
        });
      }
      console.log(`[${runId}]   🧹 Hard filters: ${filtered.length} survive (likes=${dropLikes}, age=${dropAge}, dur=${dropDuration}, lang=${dropLang}, translit=${dropTranslit})`);
      if (!filtered.length) { results.push({ niche: niche.name, status: "No survivors after hard filters" }); totalFailed++; continue; }

      // ── VERTICAL CHECK FIRST (vision-based, on hard-filter survivors) ──
      // Gemini sees the actual thumbnail bytes and decides 9:16 vs 16:9.
      // This is the strongest single signal — run it on everyone before any other Gemini step.
      const sortedByViews = [...filtered].sort((a, b) => b.viewCount - a.viewCount);
      const vSet = await batchCheckVertical(
        sortedByViews.map(f => ({ videoId: f.videoId, title: f.title, thumbnailUrl: f.thumbnailUrl })),
        geminiUrl,
        runId
      );
      const verticals = sortedByViews.filter(f => vSet.has(f.videoId));
      console.log(`[${runId}]   📐 After vertical check: ${verticals.length}/${sortedByViews.length}`);
      if (!verticals.length) { results.push({ niche: niche.name, status: "No vertical videos" }); totalFailed++; continue; }

      // ── TITLE ENGLISH + RELEVANCE (batch Gemini, one call) on vertical survivors ──
      const enRel = await batchCheckEnglishRelevance(verticals, niche.name, geminiUrl, runId);
      const cleanPool = verticals.filter((_, idx) => enRel[idx]);
      console.log(`[${runId}]   ✨ CLEAN POOL: ${cleanPool.length} videos`);
      if (!cleanPool.length) { results.push({ niche: niche.name, status: "No English/relevant verticals" }); totalFailed++; continue; }

      // ── PICK 3 WINNERS (one Gemini call) ──
      const targetCount = Math.min(exactVideos, cleanPool.length);
      const winnerIdx = await pickWinners(cleanPool, niche.name, targetCount, geminiUrl, runId);
      const winners = winnerIdx.map(i => cleanPool[i]);
      console.log(`[${runId}]   🏆 Got ${winners.length} winners (target: ${exactVideos})`);

      // ── For each winner: techniques + description (parallel) ──
      const techniquesByType: Record<string, Technique[]> = {};
      for (const t of allTechniques) { (techniquesByType[t.type] ??= []).push(t); }

      let currentLevel = niche.video_count;
      const perWinner = await Promise.all(winners.map(async (selected) => {
        const techPrompt = `Pick 1-2 techniques used in this viral Short: "${selected.title}" (${niche.name})

AUDIO: ${(techniquesByType['audio'] || []).map(t => t.name).join(", ")}
VISUAL: ${(techniquesByType['visual'] || []).map(t => t.name).join(", ")}
EMOTION: ${(techniquesByType['emotion'] || []).map(t => t.name).join(", ")}

Reply with technique names separated by commas only.`;

        const descPromptBuilder = (techs: string) => `Write ONE complete sentence (25-40 words) explaining how this viral ${niche.name} video uses ${techs} to hook viewers.

TITLE: "${selected.title}"

Rules:
1. Output ONLY the sentence. No preface, no quotes, no markdown.
2. Exactly ONE grammatically complete sentence ending in "." — subject + verb + object.
3. Between 25 and 40 words. Never less than 20.
4. Must explicitly mention how "${techs}" is used (not just name it).
5. Do not start with "This video" or "The video".
6. Be specific to this video, not generic.

Example of GOOD output:
"The creator opens with a rapid-fire countdown of unexpected facts, leveraging jump cuts every two seconds to maintain breakneck pacing that prevents any chance of viewer scroll-away."

Example of BAD output (incomplete / vague):
"FireCrow's clutch employs."
"Showcasing one year."`;

        // Validates that a description is a complete, useful sentence.
        const isCompleteSentence = (s: string): boolean => {
          if (!s) return false;
          const trimmed = s.trim();
          if (trimmed.length < 40) return false;
          const wc = trimmed.split(/\s+/).length;
          if (wc < 15) return false;
          // Must end with terminal punctuation
          if (!/[.!?]$/.test(trimmed)) return false;
          // Must have at least one verb-ish pattern (rough heuristic: contains a space + lowercase word ending in s/ed/ing/es OR common verbs)
          if (!/\b(uses|use|employs|leverages|combines|hooks|creates|delivers|opens|builds|maintains|captures|grabs|drives|forces|keeps|makes|turns|relies|exploits|showcases|reveals|builds|sparks|triggers|is|are|features)\b/i.test(trimmed)) return false;
          return true;
        };

        // Step 1: get techniques
        const techRaw = await callGemini(geminiUrl, techPrompt, 1000, 0.3);
        const selectedNames: string[] = [];
        const selectedIds: string[] = [];
        const want = techRaw.split(",").map(s => s.trim().toLowerCase()).filter(Boolean);
        for (const tech of allTechniques) {
          const nl = tech.name.toLowerCase();
          for (const w of want) {
            if (nl.includes(w) || w.includes(nl)) {
              if (!selectedIds.includes(tech.id)) {
                selectedIds.push(tech.id); selectedNames.push(tech.name);
              }
              break;
            }
          }
          if (selectedIds.length >= 2) break;
        }

        // Step 2: description — up to 2 attempts, then fallback
        const techsText = selectedNames.length ? selectedNames.join(" and ") : "viral techniques";

        const cleanDesc = (raw: string): string => {
          let d = raw
            .replace(/^["'\s]+|["'\s]+$/g, "")
            .replace(/^(here['']?s?\s*(a\s*)?(complete\s*)?(sentence|description)?:?\s*)/i, "")
            .replace(/^(answer|output|response):?\s*/i, "")
            .replace(/\*\*/g, "")
            .trim();
          // Keep only the first complete sentence if model gave several
          const sents = d.match(/[^.!?]+[.!?]+/g);
          if (sents && sents.length >= 1) d = sents[0].trim();
          // Trim to 40 words max
          const w = d.split(/\s+/);
          if (w.length > 40) d = w.slice(0, 40).join(" ").replace(/[,;:\s]+$/, "") + ".";
          return d;
        };

        // Attempt 1 — normal temp, generous tokens (Gemini 2.5 uses tokens for thinking)
        let description = cleanDesc(await callGemini(geminiUrl, descPromptBuilder(techsText), 2000, 0.8));

        // Attempt 2 — retry if first attempt is incomplete/fragmented
        if (!isCompleteSentence(description)) {
          console.log(`[${runId}]   ↻ Retry description for "${selected.title.substring(0, 40)}" (got: "${description.substring(0, 60)}")`);
          description = cleanDesc(await callGemini(geminiUrl, descPromptBuilder(techsText), 2000, 0.7));
        }

        // Fallback only if both attempts failed validation
        if (!isCompleteSentence(description)) {
          const fallbacks = [
            `The creator hooks viewers instantly with ${techsText}, making it impossible to scroll past this ${niche.name} Short.`,
            `By combining ${techsText}, this ${niche.name} Short creates an addictive viewing experience that keeps audiences watching to the end.`,
            `Strategic use of ${techsText} turns this ${niche.name} video into a scroll-stopping piece that demands viewer attention.`,
          ];
          description = fallbacks[Math.floor(Math.random() * fallbacks.length)];
        }

        return { selected, selectedIds, selectedNames, description };
      }));

      // ── INSERT (sequential to keep level counter coherent) ──
      let addedHere = 0;
      for (const w of perWinner) {
        const insertData = {
          niche_id: niche.id,
          youtube_url: `https://youtube.com/shorts/${w.selected.videoId}`,
          description: w.description,
          thumbnail_url: w.selected.thumbnailUrl,
          niche_name: niche.name,
          technique_ids: w.selectedIds.length ? w.selectedIds : null,
        };
        const { error: insErr } = await supabase.from("viral_examples").insert(insertData);
        if (insErr) {
          console.error(`[${runId}]   ❌ Insert failed:`, insErr.message);
          results.push({ niche: niche.name, status: `Insert failed: ${insErr.message}`, video: w.selected.title });
          totalFailed++;
        } else {
          addedHere++; totalAdded++; currentLevel++;
          console.log(`[${runId}]   ✅ Inserted: "${w.selected.title.substring(0, 60)}"`);
          results.push({
            niche: niche.name, status: "SUCCESS",
            video: w.selected.title, level: currentLevel,
            techniques: w.selectedNames.length ? w.selectedNames : undefined,
          });
        }
      }
      // Pad failures up to exactVideos so the response shape stays consistent
      for (let v = addedHere; v < exactVideos; v++) {
        results.push({ niche: niche.name, status: `Only ${addedHere} winners available (clean pool was ${cleanPool.length})`, level: currentLevel });
        totalFailed++;
      }
      nichesProcessed = i + 1;
    }

    const duration = Date.now() - startTime;
    const targetTotal = exactNiches * exactVideos;
    console.log(`\n${"=".repeat(60)}\n[${runId}] 🏁 DONE: ${totalAdded}/${targetTotal} added in ${(duration / 1000).toFixed(1)}s\n${"=".repeat(60)}`);

    return new Response(JSON.stringify({
      success: !quotaExhausted,
      quota_exhausted: quotaExhausted,
      quota_exhaustion_message: quotaExhausted ? quotaMsg : null,
      run_id: runId,
      duration_ms: duration,
      time_budget_exceeded: timeBudgetExceeded,
      config: { exact_niches: exactNiches, exact_videos_per_niche: exactVideos, target_total: targetTotal },
      summary: {
        total_niches: niches.length,
        niches_processed: nichesProcessed,
        videos_added: totalAdded,
        videos_failed: totalFailed,
        target_achieved: totalAdded === targetTotal,
        achievement_rate: ((totalAdded / targetTotal) * 100).toFixed(1) + "%",
      },
      results,
    }), { headers: { ...CORS_HEADERS, "Content-Type": "application/json" } });

  } catch (error) {
    const duration = Date.now() - startTime;
    if (error instanceof QuotaExhaustedError) {
      return new Response(JSON.stringify({
        success: false, quota_exhausted: true, quota_exhaustion_message: error.message,
        run_id: runId, duration_ms: duration,
        partial_results: { videos_added: totalAdded, videos_failed: totalFailed },
        results,
      }), { status: 429, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } });
    }
    console.error(`[${runId}] ❌ FATAL:`, error);
    return new Response(JSON.stringify({
      success: false, run_id: runId,
      error: error instanceof Error ? error.message : String(error),
      duration_ms: duration,
    }), { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } });
  }
});
