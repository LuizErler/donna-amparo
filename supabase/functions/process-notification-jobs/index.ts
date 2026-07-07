import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import {
  claimPendingJobs,
  processJob,
} from "../_shared/process-jobs.ts";
import {
  assertCronSecret,
  createAdminClient,
} from "../_shared/supabase-admin.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "method not allowed" }, 405);
  }

  try {
    assertCronSecret(req);

    const supabase = createAdminClient();
    const jobs = await claimPendingJobs(supabase, 50);

    const results = [];
    for (const job of jobs) {
      const result = await processJob(supabase, job);
      results.push({ job_id: job.id, type: job.type, ...result });
    }

    return jsonResponse({
      processed: results.length,
      sent: results.filter((r) => r.sent).length,
      failed: results.filter((r) => !r.sent).length,
      results,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error("process-notification-jobs", message);
    return jsonResponse({ error: message }, 500);
  }
});
