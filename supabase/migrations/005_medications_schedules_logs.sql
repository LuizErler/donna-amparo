-- =============================================
-- Donna Amparo — Medicamentos, horarios e logs de dose
-- Migration 005
--
-- Depende de: patients, care_teams, helpers RLS (001)
-- Papeis:
--   admin/caregiver     — CRUD medicamentos e horarios
--   caregiver_basic     — confirma doses (medication_logs)
--   observer            — somente leitura
--
-- Substitui schema legado (frequency/active/hora) quando vazio.
-- =============================================

DROP TABLE IF EXISTS public.medication_logs CASCADE;
DROP TABLE IF EXISTS public.medication_schedules CASCADE;
DROP TABLE IF EXISTS public.medications CASCADE;

DROP FUNCTION IF EXISTS public.set_medications_updated_at() CASCADE;

-- ---------------------------------------------
-- 1) medications — cadastro do remedio
-- ---------------------------------------------
CREATE TABLE public.medications (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  patient_id   uuid NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  name         text NOT NULL,
  dosage       text,
  instructions text,
  is_active    boolean NOT NULL DEFAULT true,
  start_date   date,
  end_date     date,
  created_by   uuid NOT NULL REFERENCES auth.users(id),
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT medications_name_not_empty CHECK (char_length(trim(name)) > 0)
);

CREATE INDEX IF NOT EXISTS medications_patient_idx
  ON public.medications (patient_id);

CREATE INDEX IF NOT EXISTS medications_patient_active_idx
  ON public.medications (patient_id)
  WHERE is_active = true;

COMMENT ON TABLE public.medications IS
  'Medicamentos do paciente (nome, dosagem, instrucoes).';

-- ---------------------------------------------
-- 2) medication_schedules — horarios de dose
-- ---------------------------------------------
CREATE TABLE public.medication_schedules (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  medication_id  bigint NOT NULL REFERENCES public.medications(id) ON DELETE CASCADE,
  time_of_day    time NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT medication_schedules_unique_time
    UNIQUE (medication_id, time_of_day)
);

CREATE INDEX IF NOT EXISTS medication_schedules_medication_idx
  ON public.medication_schedules (medication_id);

COMMENT ON TABLE public.medication_schedules IS
  'Horarios de administracao (ex.: 08:00, 20:00).';

-- ---------------------------------------------
-- 3) medication_logs — confirmacao de dose por dia/horario
-- ---------------------------------------------
CREATE TABLE public.medication_logs (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  medication_id   bigint NOT NULL REFERENCES public.medications(id) ON DELETE CASCADE,
  patient_id      uuid NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  schedule_id     bigint REFERENCES public.medication_schedules(id) ON DELETE SET NULL,
  scheduled_for   date NOT NULL,
  scheduled_time  time NOT NULL,
  taken           boolean NOT NULL DEFAULT false,
  taken_at        timestamptz,
  taken_by        uuid REFERENCES auth.users(id),
  skipped_reason  text,
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT medication_logs_unique_slot
    UNIQUE (medication_id, scheduled_for, scheduled_time),
  CONSTRAINT medication_logs_taken_pair_check
    CHECK (
      (taken = false AND taken_at IS NULL AND taken_by IS NULL)
      OR (taken = true AND taken_at IS NOT NULL AND taken_by IS NOT NULL)
    )
);

CREATE INDEX IF NOT EXISTS medication_logs_patient_day_idx
  ON public.medication_logs (patient_id, scheduled_for);

CREATE INDEX IF NOT EXISTS medication_logs_medication_day_idx
  ON public.medication_logs (medication_id, scheduled_for);

COMMENT ON TABLE public.medication_logs IS
  'Registro diario de dose tomada ou pendente.';

-- ---------------------------------------------
-- 4) updated_at em medications
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION public.set_medications_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS medications_set_updated_at ON public.medications;

CREATE TRIGGER medications_set_updated_at
  BEFORE UPDATE ON public.medications
  FOR EACH ROW
  EXECUTE FUNCTION public.set_medications_updated_at();

-- ---------------------------------------------
-- 5) RLS
-- ---------------------------------------------
ALTER TABLE public.medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medication_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medication_logs ENABLE ROW LEVEL SECURITY;

-- MEDICATIONS
DROP POLICY IF EXISTS "medications_via_care_team" ON public.medications;
DROP POLICY IF EXISTS "medications_select_member" ON public.medications;
DROP POLICY IF EXISTS "medications_write_caregiver" ON public.medications;

CREATE POLICY "medications_select_member" ON public.medications
  FOR SELECT USING (public.is_member_of_patient(patient_id));

CREATE POLICY "medications_insert_caregiver" ON public.medications
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.care_teams ct
      WHERE ct.patient_id = medications.patient_id
        AND ct.profile_id = auth.uid()
        AND ct.role IN ('admin', 'caregiver')
        AND ct.accepted_at IS NOT NULL
    )
    AND created_by = auth.uid()
  );

CREATE POLICY "medications_update_caregiver" ON public.medications
  FOR UPDATE USING (
    EXISTS (
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

CREATE POLICY "medications_delete_caregiver" ON public.medications
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.care_teams ct
      WHERE ct.patient_id = medications.patient_id
        AND ct.profile_id = auth.uid()
        AND ct.role IN ('admin', 'caregiver')
        AND ct.accepted_at IS NOT NULL
    )
  );

-- MEDICATION_SCHEDULES
DROP POLICY IF EXISTS "medication_schedules_via_care_team" ON public.medication_schedules;
DROP POLICY IF EXISTS "medication_schedules_select_member" ON public.medication_schedules;
DROP POLICY IF EXISTS "medication_schedules_write_caregiver" ON public.medication_schedules;

CREATE POLICY "medication_schedules_select_member" ON public.medication_schedules
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.medications m
      WHERE m.id = medication_schedules.medication_id
        AND public.is_member_of_patient(m.patient_id)
    )
  );

CREATE POLICY "medication_schedules_insert_caregiver" ON public.medication_schedules
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.medications m
      JOIN public.care_teams ct ON ct.patient_id = m.patient_id
      WHERE m.id = medication_schedules.medication_id
        AND ct.profile_id = auth.uid()
        AND ct.role IN ('admin', 'caregiver')
        AND ct.accepted_at IS NOT NULL
    )
  );

CREATE POLICY "medication_schedules_update_caregiver" ON public.medication_schedules
  FOR UPDATE USING (
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

CREATE POLICY "medication_schedules_delete_caregiver" ON public.medication_schedules
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.medications m
      JOIN public.care_teams ct ON ct.patient_id = m.patient_id
      WHERE m.id = medication_schedules.medication_id
        AND ct.profile_id = auth.uid()
        AND ct.role IN ('admin', 'caregiver')
        AND ct.accepted_at IS NOT NULL
    )
  );

-- MEDICATION_LOGS
DROP POLICY IF EXISTS "medication_logs_via_care_team" ON public.medication_logs;
DROP POLICY IF EXISTS "medication_logs_select_member" ON public.medication_logs;
DROP POLICY IF EXISTS "medication_logs_insert_basic_plus" ON public.medication_logs;
DROP POLICY IF EXISTS "medication_logs_update_basic_plus" ON public.medication_logs;

CREATE POLICY "medication_logs_select_member" ON public.medication_logs
  FOR SELECT USING (public.is_member_of_patient(patient_id));

CREATE POLICY "medication_logs_insert_basic_plus" ON public.medication_logs
  FOR INSERT WITH CHECK (public.can_write_care_data(patient_id));

CREATE POLICY "medication_logs_update_basic_plus" ON public.medication_logs
  FOR UPDATE USING (public.can_write_care_data(patient_id))
  WITH CHECK (public.can_write_care_data(patient_id));

CREATE POLICY "medication_logs_delete_basic_plus" ON public.medication_logs
  FOR DELETE USING (public.can_write_care_data(patient_id));
