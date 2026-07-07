import { sendFcmToToken } from "../_shared/fcm.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { createAdminClient } from "../_shared/supabase-admin.ts";

type SendPushBody = {
  profile_id?: string;
  title?: string;
  body?: string;
  data?: Record<string, unknown>;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "method not allowed" }, 405);
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "unauthorized" }, 401);
    }

    const body = (await req.json()) as SendPushBody;
    const profileId = body.profile_id?.trim();
    if (!profileId) {
      return jsonResponse({ error: "profile_id obrigatorio" }, 400);
    }

    const title = body.title?.trim() || "Teste Donna Amparo";
    const pushBody = body.body?.trim() || "Push de teste da plataforma.";
    const data = body.data ?? { route: "alertas" };

    const supabase = createAdminClient();
    const { data: tokens, error: tokensError } = await supabase
      .from("device_tokens")
      .select("token, platform")
      .eq("profile_id", profileId);

    if (tokensError) {
      return jsonResponse({ error: tokensError.message }, 500);
    }

    if (!tokens || tokens.length === 0) {
      return jsonResponse({ error: "sem device_tokens para o profile" }, 404);
    }

    const deliveries = [];
    for (const row of tokens) {
      const result = await sendFcmToToken({
        token: row.token,
        title,
        body: pushBody,
        data,
      });
      deliveries.push({
        platform: row.platform,
        ok: result.ok,
        status: result.status,
      });
    }

    const sent = deliveries.some((d) => d.ok);
    return jsonResponse({ sent, deliveries }, sent ? 200 : 502);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error("send-push", message);
    return jsonResponse({ error: message }, 500);
  }
});
