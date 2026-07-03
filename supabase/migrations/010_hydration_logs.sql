-- =============================================
-- Donna Amparo — Registros de hidratacao
-- Migration 010
--
-- Depende de: patients, care_teams, helpers RLS (001)
-- Papeis:
--   admin/caregiver/caregiver_basic — INSERT (can_write_care_data)
--   observer                        — somente leitura
-- =============================================

CREATE TABLE public.hydration_logs (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id   uuid NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  recorded_at  timestamptz NOT NULL DEFAULT now(),
  recorded_by  uuid NOT NULL REFERENCES auth.users(id),
  notes        text,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS hydration_logs_patient_recorded_idx
  ON public.hydration_logs (patient_id, recorded_at DESC);

COMMENT ON TABLE public.hydration_logs IS
  'Registro de hidratacao do paciente (timestamp por evento).';

ALTER TABLE public.hydration_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "hydration_logs_select_member" ON public.hydration_logs
  FOR SELECT USING (public.is_member_of_patient(patient_id));

CREATE POLICY "hydration_logs_insert_basic_plus" ON public.hydration_logs
  FOR INSERT WITH CHECK (
    public.can_write_care_data(patient_id)
    AND recorded_by = auth.uid()
  );
