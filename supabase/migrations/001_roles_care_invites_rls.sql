-- =============================================
-- Donna Amparo — Papéis, care_invites e RLS
-- Rodar APOS o schema base no Supabase SQL Editor
--
-- Papeis (care_teams.role):
--   admin            = Cuidador Admin
--   caregiver        = Cuidador
--   caregiver_basic  = Cuidador Basico
--   observer         = Observador
-- =============================================

-- ---------------------------------------------
-- 1) Tipo / constraint de papeis
-- ---------------------------------------------
UPDATE public.care_teams
SET role = 'observer'
WHERE role IS NULL
   OR role IN ('visualizador', 'primary_caregiver', 'caregiver_principal');

ALTER TABLE public.care_teams
  ALTER COLUMN role SET DEFAULT 'observer';

ALTER TABLE public.care_teams
  DROP CONSTRAINT IF EXISTS care_teams_role_check;

ALTER TABLE public.care_teams
  ADD CONSTRAINT care_teams_role_check
  CHECK (role IN ('admin', 'caregiver', 'caregiver_basic', 'observer'));

COMMENT ON COLUMN public.care_teams.role IS
  'admin=Cuidador Admin, caregiver=Cuidador, caregiver_basic=Cuidador Basico, observer=Observador';

-- ---------------------------------------------
-- 2) care_invites (convite QR / link com papel)
-- ---------------------------------------------
CREATE TABLE IF NOT EXISTS public.care_invites (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id   uuid NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  role         text NOT NULL,
  token        uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
  invited_by   uuid NOT NULL REFERENCES auth.users(id),
  expires_at   timestamptz NOT NULL DEFAULT (now() + interval '7 days'),
  accepted_at  timestamptz,
  accepted_by  uuid REFERENCES auth.users(id),
  created_at   timestamptz DEFAULT now(),
  CONSTRAINT care_invites_role_check
    CHECK (role IN ('admin', 'caregiver', 'caregiver_basic', 'observer')),
  CONSTRAINT care_invites_accepted_pair_check
    CHECK (
      (accepted_at IS NULL AND accepted_by IS NULL)
      OR (accepted_at IS NOT NULL AND accepted_by IS NOT NULL)
    )
);

CREATE INDEX IF NOT EXISTS care_invites_token_idx ON public.care_invites (token);
CREATE INDEX IF NOT EXISTS care_invites_patient_idx ON public.care_invites (patient_id);

ALTER TABLE public.care_invites ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------
-- 3) Profile automatico no signup
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data ->> 'nome',
      NEW.raw_user_meta_data ->> 'full_name',
      ''
    ),
    NEW.email
  )
  ON CONFLICT (id) DO UPDATE
  SET
    full_name = COALESCE(EXCLUDED.full_name, profiles.full_name),
    email = COALESCE(EXCLUDED.email, profiles.email);

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ---------------------------------------------
-- 4) Helpers RLS (SECURITY DEFINER)
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION public.is_member_of_patient(p_patient_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.care_teams ct
    WHERE ct.patient_id = p_patient_id
      AND ct.profile_id = auth.uid()
      AND ct.accepted_at IS NOT NULL
  );
$$;

CREATE OR REPLACE FUNCTION public.is_patient_admin(p_patient_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.care_teams ct
    WHERE ct.patient_id = p_patient_id
      AND ct.profile_id = auth.uid()
      AND ct.role = 'admin'
      AND ct.accepted_at IS NOT NULL
  );
$$;

CREATE OR REPLACE FUNCTION public.can_write_care_data(p_patient_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.care_teams ct
    WHERE ct.patient_id = p_patient_id
      AND ct.profile_id = auth.uid()
      AND ct.role IN ('admin', 'caregiver', 'caregiver_basic')
      AND ct.accepted_at IS NOT NULL
  );
$$;

CREATE OR REPLACE FUNCTION public.can_manage_care_team(p_patient_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.is_patient_admin(p_patient_id);
$$;

-- ---------------------------------------------
-- 5) RPC: aceitar convite (link / QR)
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION public.accept_care_invite(p_token uuid)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invite public.care_invites%ROWTYPE;
  v_team_id bigint;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Usuario nao autenticado';
  END IF;

  SELECT * INTO v_invite
  FROM public.care_invites
  WHERE token = p_token
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Convite invalido';
  END IF;

  IF v_invite.accepted_at IS NOT NULL THEN
    RAISE EXCEPTION 'Convite ja utilizado';
  END IF;

  IF v_invite.expires_at < now() THEN
    RAISE EXCEPTION 'Convite expirado';
  END IF;

  INSERT INTO public.care_teams (
    profile_id,
    patient_id,
    role,
    invited_by,
    accepted_at
  )
  VALUES (
    auth.uid(),
    v_invite.patient_id,
    v_invite.role,
    v_invite.invited_by,
    now()
  )
  ON CONFLICT (profile_id, patient_id) DO UPDATE
  SET
    role = EXCLUDED.role,
    invited_by = EXCLUDED.invited_by,
    accepted_at = EXCLUDED.accepted_at
  RETURNING id INTO v_team_id;

  UPDATE public.care_invites
  SET accepted_at = now(), accepted_by = auth.uid()
  WHERE id = v_invite.id;

  RETURN v_team_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.accept_care_invite(uuid) TO authenticated;

-- ---------------------------------------------
-- 6) RLS — recriar policies principais
-- ---------------------------------------------

-- PROFILES
DROP POLICY IF EXISTS "profiles_own" ON public.profiles;
CREATE POLICY "profiles_select_own" ON public.profiles
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_insert_own" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- PATIENTS
DROP POLICY IF EXISTS "patients_via_care_team" ON public.patients;
CREATE POLICY "patients_select_member" ON public.patients
  FOR SELECT USING (public.is_member_of_patient(id));
CREATE POLICY "patients_insert_creator" ON public.patients
  FOR INSERT WITH CHECK (created_by = auth.uid());
CREATE POLICY "patients_update_admin" ON public.patients
  FOR UPDATE USING (public.is_patient_admin(id))
  WITH CHECK (public.is_patient_admin(id));

-- CARE_TEAMS
DROP POLICY IF EXISTS "care_teams_member" ON public.care_teams;
CREATE POLICY "care_teams_select_same_patient" ON public.care_teams
  FOR SELECT USING (
    profile_id = auth.uid()
    OR public.is_member_of_patient(patient_id)
  );
CREATE POLICY "care_teams_insert_onboarding" ON public.care_teams
  FOR INSERT WITH CHECK (
    profile_id = auth.uid()
    AND role = 'admin'
    AND patient_id IN (
      SELECT id FROM public.patients WHERE created_by = auth.uid()
    )
  );
CREATE POLICY "care_teams_insert_admin_invite" ON public.care_teams
  FOR INSERT WITH CHECK (
    public.is_patient_admin(patient_id)
  );
CREATE POLICY "care_teams_update_admin" ON public.care_teams
  FOR UPDATE USING (public.is_patient_admin(patient_id))
  WITH CHECK (public.is_patient_admin(patient_id));
CREATE POLICY "care_teams_delete_admin" ON public.care_teams
  FOR DELETE USING (public.is_patient_admin(patient_id));

-- CARE_INVITES
DROP POLICY IF EXISTS "care_invites_admin_select" ON public.care_invites;
DROP POLICY IF EXISTS "care_invites_admin_insert" ON public.care_invites;
CREATE POLICY "care_invites_admin_select" ON public.care_invites
  FOR SELECT USING (public.is_patient_admin(patient_id));
CREATE POLICY "care_invites_admin_insert" ON public.care_invites
  FOR INSERT WITH CHECK (
    public.is_patient_admin(patient_id)
    AND invited_by = auth.uid()
  );

-- MEDICATIONS + filhas
DROP POLICY IF EXISTS "medications_via_care_team" ON public.medications;
CREATE POLICY "medications_select_member" ON public.medications
  FOR SELECT USING (public.is_member_of_patient(patient_id));
CREATE POLICY "medications_write_caregiver" ON public.medications
  FOR ALL USING (
    public.can_write_care_data(patient_id)
    AND EXISTS (
      SELECT 1 FROM public.care_teams ct
      WHERE ct.patient_id = medications.patient_id
        AND ct.profile_id = auth.uid()
        AND ct.role IN ('admin', 'caregiver')
        AND ct.accepted_at IS NOT NULL
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.care_teams ct
      WHERE ct.patient_id = medications.patient_id
        AND ct.profile_id = auth.uid()
        AND ct.role IN ('admin', 'caregiver')
        AND ct.accepted_at IS NOT NULL
    )
  );

DROP POLICY IF EXISTS "medication_schedules_via_care_team" ON public.medication_schedules;
CREATE POLICY "medication_schedules_select_member" ON public.medication_schedules
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.medications m
      WHERE m.id = medication_schedules.medication_id
        AND public.is_member_of_patient(m.patient_id)
    )
  );
CREATE POLICY "medication_schedules_write_caregiver" ON public.medication_schedules
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.medications m
      JOIN public.care_teams ct ON ct.patient_id = m.patient_id
      WHERE m.id = medication_schedules.medication_id
        AND ct.profile_id = auth.uid()
        AND ct.role IN ('admin', 'caregiver')
        AND ct.accepted_at IS NOT NULL
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.medications m
      JOIN public.care_teams ct ON ct.patient_id = m.patient_id
      WHERE m.id = medication_schedules.medication_id
        AND ct.profile_id = auth.uid()
        AND ct.role IN ('admin', 'caregiver')
        AND ct.accepted_at IS NOT NULL
    )
  );

DROP POLICY IF EXISTS "medication_logs_via_care_team" ON public.medication_logs;
CREATE POLICY "medication_logs_select_member" ON public.medication_logs
  FOR SELECT USING (public.is_member_of_patient(patient_id));
CREATE POLICY "medication_logs_insert_basic_plus" ON public.medication_logs
  FOR INSERT WITH CHECK (public.can_write_care_data(patient_id));
CREATE POLICY "medication_logs_update_basic_plus" ON public.medication_logs
  FOR UPDATE USING (public.can_write_care_data(patient_id))
  WITH CHECK (public.can_write_care_data(patient_id));

DROP POLICY IF EXISTS "vital_signs_via_care_team" ON public.vital_signs;
CREATE POLICY "vital_signs_select_member" ON public.vital_signs
  FOR SELECT USING (public.is_member_of_patient(patient_id));
CREATE POLICY "vital_signs_write_basic_plus" ON public.vital_signs
  FOR ALL USING (public.can_write_care_data(patient_id))
  WITH CHECK (public.can_write_care_data(patient_id));

DROP POLICY IF EXISTS "appointments_via_care_team" ON public.appointments;
CREATE POLICY "appointments_select_member" ON public.appointments
  FOR SELECT USING (public.is_member_of_patient(patient_id));
CREATE POLICY "appointments_write_caregiver" ON public.appointments
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.care_teams ct
      WHERE ct.patient_id = appointments.patient_id
        AND ct.profile_id = auth.uid()
        AND ct.role IN ('admin', 'caregiver')
        AND ct.accepted_at IS NOT NULL
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.care_teams ct
      WHERE ct.patient_id = appointments.patient_id
        AND ct.profile_id = auth.uid()
        AND ct.role IN ('admin', 'caregiver')
        AND ct.accepted_at IS NOT NULL
    )
  );

DROP POLICY IF EXISTS "activity_logs_via_care_team" ON public.activity_logs;
CREATE POLICY "activity_logs_select_member" ON public.activity_logs
  FOR SELECT USING (public.is_member_of_patient(patient_id));
CREATE POLICY "activity_logs_insert_member" ON public.activity_logs
  FOR INSERT WITH CHECK (public.is_member_of_patient(patient_id));

DROP POLICY IF EXISTS "notifications_own" ON public.notifications;
CREATE POLICY "notifications_select_own" ON public.notifications
  FOR SELECT USING (auth.uid() = profile_id);
CREATE POLICY "notifications_update_own" ON public.notifications
  FOR UPDATE USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);
