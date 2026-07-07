-- =============================================
-- Donna Amparo — Workers de push (Fase 1.2)
-- Migration 012
--
-- RPC para enfileirar/cancelar jobs (#101+)
-- Claim atomico para Edge Function process-notification-jobs
-- =============================================

ALTER TABLE public.notification_jobs
  DROP CONSTRAINT IF EXISTS notification_jobs_status_check;

ALTER TABLE public.notification_jobs
  ADD CONSTRAINT notification_jobs_status_check
  CHECK (status IN ('pending', 'processing', 'sent', 'cancelled', 'failed'));

-- ---------------------------------------------
-- Claim: pending + fire_at <= now (SKIP LOCKED)
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION public.claim_pending_notification_jobs(
  p_limit integer DEFAULT 50
)
RETURNS SETOF public.notification_jobs
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  WITH picked AS (
    SELECT id
    FROM public.notification_jobs
    WHERE status = 'pending'
      AND fire_at <= now()
    ORDER BY fire_at ASC
    LIMIT p_limit
    FOR UPDATE SKIP LOCKED
  )
  UPDATE public.notification_jobs j
  SET
    status = 'processing',
    updated_at = now()
  FROM picked
  WHERE j.id = picked.id
  RETURNING j.*;
END;
$$;

REVOKE ALL ON FUNCTION public.claim_pending_notification_jobs(integer) FROM PUBLIC;

-- ---------------------------------------------
-- Enfileirar job (plug-ins Flutter / #101)
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION public.enqueue_notification_job(
  p_patient_id uuid,
  p_profile_id uuid,
  p_type text,
  p_fire_at timestamptz,
  p_payload jsonb DEFAULT '{}'::jsonb,
  p_source_type text DEFAULT NULL,
  p_source_id text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  IF NOT public.is_member_of_patient(p_patient_id) THEN
    RAISE EXCEPTION 'not a care team member';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.care_teams ct
    WHERE ct.patient_id = p_patient_id
      AND ct.profile_id = p_profile_id
      AND ct.accepted_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'target profile is not on care team';
  END IF;

  INSERT INTO public.notification_jobs (
    patient_id,
    profile_id,
    type,
    fire_at,
    payload,
    source_type,
    source_id
  ) VALUES (
    p_patient_id,
    p_profile_id,
    p_type,
    p_fire_at,
    p_payload,
    p_source_type,
    p_source_id
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.enqueue_notification_job(
  uuid, uuid, text, timestamptz, jsonb, text, text
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.enqueue_notification_job(
  uuid, uuid, text, timestamptz, jsonb, text, text
) TO authenticated;

-- ---------------------------------------------
-- Cancelar jobs pendentes por origem
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION public.cancel_notification_jobs_by_source(
  p_patient_id uuid,
  p_source_type text,
  p_source_id text
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  IF NOT public.is_member_of_patient(p_patient_id) THEN
    RAISE EXCEPTION 'not authorized';
  END IF;

  UPDATE public.notification_jobs
  SET
    status = 'cancelled',
    updated_at = now()
  WHERE patient_id = p_patient_id
    AND source_type = p_source_type
    AND source_id = p_source_id
    AND status IN ('pending', 'processing');

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

REVOKE ALL ON FUNCTION public.cancel_notification_jobs_by_source(uuid, text, text) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.cancel_notification_jobs_by_source(uuid, text, text)
  TO authenticated;

-- ---------------------------------------------
-- Inbox legada (service role / worker)
-- Tenta message; fallback body.
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION public.insert_notification_inbox(
  p_profile_id uuid,
  p_patient_id uuid,
  p_type text,
  p_title text,
  p_body text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  BEGIN
    INSERT INTO public.notifications (
      profile_id,
      patient_id,
      type,
      title,
      message,
      read,
      created_at
    ) VALUES (
      p_profile_id,
      p_patient_id,
      p_type,
      p_title,
      p_body,
      false,
      now()
    );
  EXCEPTION
    WHEN undefined_column THEN
      INSERT INTO public.notifications (
        profile_id,
        patient_id,
        type,
        title,
        body,
        read,
        created_at
      ) VALUES (
        p_profile_id,
        p_patient_id,
        p_type,
        p_title,
        p_body,
        false,
        now()
      );
  END;
END;
$$;

REVOKE ALL ON FUNCTION public.insert_notification_inbox(uuid, uuid, text, text, text) FROM PUBLIC;
