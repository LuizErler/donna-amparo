-- Migration 006: modo intervalo em medications
ALTER TABLE public.medications
  ADD COLUMN IF NOT EXISTS schedule_mode text NOT NULL DEFAULT 'fixed_times',
  ADD COLUMN IF NOT EXISTS interval_hours int,
  ADD COLUMN IF NOT EXISTS anchor_time time;

ALTER TABLE public.medications
  DROP CONSTRAINT IF EXISTS medications_schedule_mode_check;

ALTER TABLE public.medications
  ADD CONSTRAINT medications_schedule_mode_check
  CHECK (schedule_mode IN ('fixed_times', 'interval'));

ALTER TABLE public.medications
  DROP CONSTRAINT IF EXISTS medications_interval_check;

ALTER TABLE public.medications
  ADD CONSTRAINT medications_interval_check
  CHECK (
    (schedule_mode = 'fixed_times' AND interval_hours IS NULL)
    OR (
      schedule_mode = 'interval'
      AND interval_hours IS NOT NULL
      AND interval_hours > 0
      AND anchor_time IS NOT NULL
    )
  );

COMMENT ON COLUMN public.medications.schedule_mode IS
  'fixed_times = horarios fixos; interval = a cada X horas';
