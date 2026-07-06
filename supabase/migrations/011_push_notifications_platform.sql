-- =============================================
-- Donna Amparo — Plataforma de push (Fase 1)
-- Migration 011
--
-- device_tokens: FCM por cuidador
-- notification_jobs: fila para Edge Functions (fase 1.2)
-- notifications: inbox in-app (RLS em 001)
-- =============================================

CREATE TABLE public.device_tokens (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id   uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token        text NOT NULL,
  platform     text NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  app_version  text,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (profile_id, token)
);

CREATE INDEX IF NOT EXISTS device_tokens_profile_idx
  ON public.device_tokens (profile_id);

COMMENT ON TABLE public.device_tokens IS
  'Tokens FCM por cuidador (profile_id = auth.users.id).';

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "device_tokens_select_own" ON public.device_tokens
  FOR SELECT USING (auth.uid() = profile_id);

CREATE POLICY "device_tokens_insert_own" ON public.device_tokens
  FOR INSERT WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "device_tokens_update_own" ON public.device_tokens
  FOR UPDATE USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "device_tokens_delete_own" ON public.device_tokens
  FOR DELETE USING (auth.uid() = profile_id);

-- Fila transversal (worker via service role / Edge Functions)
CREATE TABLE public.notification_jobs (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id   uuid REFERENCES public.patients(id) ON DELETE CASCADE,
  profile_id   uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  type         text NOT NULL,
  fire_at      timestamptz NOT NULL,
  payload      jsonb NOT NULL DEFAULT '{}'::jsonb,
  status       text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'sent', 'cancelled', 'failed')),
  source_type  text,
  source_id    text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS notification_jobs_pending_fire_at_idx
  ON public.notification_jobs (fire_at)
  WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS notification_jobs_profile_idx
  ON public.notification_jobs (profile_id);

COMMENT ON TABLE public.notification_jobs IS
  'Fila de notificacoes push/inbox processada por Edge Functions.';

ALTER TABLE public.notification_jobs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notification_jobs_select_own" ON public.notification_jobs
  FOR SELECT USING (auth.uid() = profile_id);

-- Inbox in-app: tabela legada ja existia (id bigint, read boolean).
-- Evolucao de schema (read_at, data jsonb) fica para migration futura.
DROP POLICY IF EXISTS "notifications_insert_own" ON public.notifications;
CREATE POLICY "notifications_insert_own" ON public.notifications
  FOR INSERT WITH CHECK (auth.uid() = profile_id);
