import { sendFcmToToken } from "../_shared/fcm.ts";
import { createAdminClient } from "../_shared/supabase-admin.ts";

export type NotificationJobRow = {
  id: string;
  patient_id: string | null;
  profile_id: string | null;
  type: string;
  fire_at: string;
  payload: Record<string, unknown>;
  status: string;
  source_type: string | null;
  source_id: string | null;
};

type DeviceTokenRow = {
  token: string;
  platform: string;
};

function payloadString(
  payload: Record<string, unknown>,
  key: string,
  fallback: string,
): string {
  const value = payload[key];
  if (typeof value === "string" && value.trim().length > 0) return value;
  return fallback;
}

function buildMessage(job: NotificationJobRow): { title: string; body: string } {
  const payload = job.payload ?? {};
  const title = payloadString(payload, "title", "Donna Amparo");
  const body = payloadString(
    payload,
    "body",
    payloadString(payload, "message", "Voce tem um novo alerta."),
  );
  return { title, body };
}

function buildFcmData(job: NotificationJobRow): Record<string, unknown> {
  const payload = job.payload ?? {};
  const route = payload.route ?? payload.screen ?? "alertas";
  return {
    route: String(route),
    job_id: job.id,
    job_type: job.type,
    patient_id: job.patient_id ?? "",
    source_type: job.source_type ?? "",
    source_id: job.source_id ?? "",
  };
}

async function markJob(
  supabase: ReturnType<typeof createAdminClient>,
  jobId: string,
  status: "sent" | "failed",
): Promise<void> {
  const { error } = await supabase
    .from("notification_jobs")
    .update({ status, updated_at: new Date().toISOString() })
    .eq("id", jobId);

  if (error) {
    console.error("markJob error", jobId, error.message);
  }
}

async function insertInbox(
  supabase: ReturnType<typeof createAdminClient>,
  job: NotificationJobRow,
  title: string,
  body: string,
): Promise<void> {
  if (!job.profile_id) return;

  const { error } = await supabase.rpc("insert_notification_inbox", {
    p_profile_id: job.profile_id,
    p_patient_id: job.patient_id,
    p_type: job.type,
    p_title: title,
    p_body: body,
  });

  if (error) {
    console.error("insertInbox error", job.id, error.message);
  }
}

export async function processJob(
  supabase: ReturnType<typeof createAdminClient>,
  job: NotificationJobRow,
): Promise<{ sent: boolean; reason?: string }> {
  if (!job.profile_id) {
    await markJob(supabase, job.id, "failed");
    return { sent: false, reason: "profile_id ausente" };
  }

  const { data: tokens, error: tokensError } = await supabase
    .from("device_tokens")
    .select("token, platform")
    .eq("profile_id", job.profile_id);

  if (tokensError) {
    await markJob(supabase, job.id, "failed");
    return { sent: false, reason: tokensError.message };
  }

  const deviceTokens = (tokens ?? []) as DeviceTokenRow[];
  if (deviceTokens.length === 0) {
    await markJob(supabase, job.id, "failed");
    return { sent: false, reason: "sem device_tokens" };
  }

  const { title, body } = buildMessage(job);
  const data = buildFcmData(job);

  let anySuccess = false;
  const errors: string[] = [];

  for (const deviceToken of deviceTokens) {
    const result = await sendFcmToToken({
      token: deviceToken.token,
      title,
      body,
      data,
    });

    if (result.ok) {
      anySuccess = true;
    } else {
      errors.push(`${deviceToken.platform}:${result.status}:${result.body}`);
    }
  }

  if (anySuccess) {
    await insertInbox(supabase, job, title, body);
    await markJob(supabase, job.id, "sent");
    return { sent: true };
  }

  const reason = errors.join(" | ").slice(0, 500);
  await markJob(supabase, job.id, "failed");
  return { sent: false, reason };
}

export async function claimPendingJobs(
  supabase: ReturnType<typeof createAdminClient>,
  limit = 50,
): Promise<NotificationJobRow[]> {
  const { data, error } = await supabase.rpc("claim_pending_notification_jobs", {
    p_limit: limit,
  });

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as NotificationJobRow[];
}
