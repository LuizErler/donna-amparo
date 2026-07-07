import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2.49.1";

export function createAdminClient(): SupabaseClient {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!url || !serviceRoleKey) {
    throw new Error("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY sao obrigatorios.");
  }

  return createClient(url, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export function assertCronSecret(req: Request): void {
  const expected = Deno.env.get("CRON_SECRET");
  if (!expected) return;

  const provided = req.headers.get("x-cron-secret");
  if (provided !== expected) {
    throw new Error("cron secret invalido");
  }
}
