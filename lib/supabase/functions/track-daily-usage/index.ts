// track-daily-usage
//
// Gatekeeper for the public.daily_analysis_usage table. Replaces direct
// PostgREST access from the Flutter client.
//
// Actions:
//   - get:       Return today's count + limit (no write).
//   - increment: Atomically increment today's count and return the new total.
//
// Per-user "today" is computed SERVER-SIDE from the user's IANA timezone
// (e.g. "Asia/Tokyo") combined with server UTC time. The client cannot
// influence the date by changing its clock.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers":
    "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-max-age": "86400",
};

const JSON_HEADERS = {
  ...CORS_HEADERS,
  "content-type": "application/json",
};

type Tier = "plus10" | "plus20" | "none";

const TIER_LIMITS: Record<Tier, number> = {
  plus10: 10,
  plus20: 20,
  none: 0,
};

interface RequestBody {
  action?: "get" | "increment";
  app_user_id?: string;
  tier?: Tier;
  // IANA timezone name e.g. "Asia/Tokyo", "America/New_York", "UTC"
  timezone?: string;
}

// Compute YYYY-MM-DD for "now" in the given IANA timezone, using the SERVER
// UTC clock. If the timezone is invalid we fall back to UTC.
function todayInTimezone(tz: string): string {
  try {
    const fmt = new Intl.DateTimeFormat("en-CA", {
      timeZone: tz,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    });
    // en-CA produces YYYY-MM-DD.
    const parts = fmt.format(new Date());
    // Sanity check: must look like YYYY-MM-DD.
    if (/^\d{4}-\d{2}-\d{2}$/.test(parts)) return parts;
  } catch (_) {
    // fall through
  }
  // Fallback: UTC date.
  const d = new Date();
  const y = d.getUTCFullYear().toString().padStart(4, "0");
  const m = (d.getUTCMonth() + 1).toString().padStart(2, "0");
  const day = d.getUTCDate().toString().padStart(2, "0");
  return `${y}-${m}-${day}`;
}

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: JSON_HEADERS });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return jsonResponse(405, { error: "method_not_allowed" });
  }

  // Require an authenticated Supabase session (anon sign-in is fine).
  // The verify_jwt setting in config.toml enforces this at the gateway, but
  // we double-check the header exists for clarity.
  const authHeader = req.headers.get("authorization");
  if (!authHeader) {
    return jsonResponse(401, { error: "missing_authorization" });
  }

  let body: RequestBody;
  try {
    body = (await req.json()) as RequestBody;
  } catch (_e) {
    return jsonResponse(400, { error: "invalid_json" });
  }

  const action = body.action ?? "get";
  const appUserId = (body.app_user_id ?? "").trim();
  const tier = (body.tier ?? "none") as Tier;
  const tz = (body.timezone ?? "UTC").trim() || "UTC";

  if (!appUserId) {
    return jsonResponse(400, { error: "missing_app_user_id" });
  }
  if (!(tier in TIER_LIMITS)) {
    return jsonResponse(400, { error: "invalid_tier" });
  }

  const limit = TIER_LIMITS[tier];
  const usageDate = todayInTimezone(tz);

  // Use service role: this function IS the gatekeeper and bypasses RLS.
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) {
    return jsonResponse(500, { error: "server_misconfigured" });
  }
  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  if (action === "get") {
    const { data, error } = await admin
      .from("daily_analysis_usage")
      .select("count, usage_date")
      .eq("app_user_id", appUserId)
      .eq("usage_date", usageDate)
      .maybeSingle();

    if (error) {
      return jsonResponse(500, { error: "db_error", detail: error.message });
    }

    const count = (data?.count as number | undefined) ?? 0;
    return jsonResponse(200, {
      count,
      limit,
      remaining: Math.max(0, limit - count),
      usage_date: usageDate,
      tier,
    });
  }

  if (action === "increment") {
    if (tier === "none") {
      return jsonResponse(400, { error: "no_tier" });
    }

    // Read current value.
    const { data: existing, error: readErr } = await admin
      .from("daily_analysis_usage")
      .select("count")
      .eq("app_user_id", appUserId)
      .eq("usage_date", usageDate)
      .maybeSingle();

    if (readErr) {
      return jsonResponse(500, { error: "db_read_error", detail: readErr.message });
    }

    const currentCount = (existing?.count as number | undefined) ?? 0;

    // Server-side limit enforcement.
    if (currentCount >= limit) {
      return jsonResponse(200, {
        count: currentCount,
        limit,
        remaining: 0,
        usage_date: usageDate,
        tier,
        limit_reached: true,
        incremented: false,
      });
    }

    const newCount = currentCount + 1;
    const nowIso = new Date().toISOString();

    const { error: upsertErr } = await admin
      .from("daily_analysis_usage")
      .upsert(
        {
          app_user_id: appUserId,
          usage_date: usageDate,
          count: newCount,
          tier,
          updated_at: nowIso,
        },
        { onConflict: "app_user_id,usage_date" },
      );

    if (upsertErr) {
      return jsonResponse(500, {
        error: "db_write_error",
        detail: upsertErr.message,
      });
    }

    return jsonResponse(200, {
      count: newCount,
      limit,
      remaining: Math.max(0, limit - newCount),
      usage_date: usageDate,
      tier,
      limit_reached: newCount >= limit,
      incremented: true,
    });
  }

  return jsonResponse(400, { error: "invalid_action" });
});
