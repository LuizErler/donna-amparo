-- Migration 008: modo intervalo em dias (a cada X dias com data ancora)
ALTER TABLE public.medications
  ADD COLUMN IF NOT EXISTS interval_days int,
  ADD COLUMN IF NOT EXISTS anchor_date date;

ALTER TABLE public.medications
  DROP CONSTRAINT IF EXISTS medications_schedule_mode_check;

ALTER TABLE public.medications
  ADD CONSTRAINT medications_schedule_mode_check
  CHECK (schedule_mode IN ('fixed_times', 'interval', 'interval_days'));

ALTER TABLE public.medications
  DROP CONSTRAINT IF EXISTS medications_interval_check;

ALTER TABLE public.medications
  ADD CONSTRAINT medications_interval_check
  CHECK (
    (
      schedule_mode = 'fixed_times'
      AND interval_hours IS NULL
      AND interval_days IS NULL
      AND anchor_time IS NULL
      AND anchor_date IS NULL
    )
    OR (
      schedule_mode = 'interval'
      AND interval_hours IS NOT NULL
      AND interval_hours > 0
      AND anchor_time IS NOT NULL
      AND interval_days IS NULL
      AND anchor_date IS NULL
    )
    OR (
      schedule_mode = 'interval_days'
      AND interval_days IS NOT NULL
      AND interval_days > 0
      AND anchor_date IS NOT NULL
      AND anchor_time IS NOT NULL
      AND interval_hours IS NULL
    )
  );

COMMENT ON COLUMN public.medications.interval_days IS
  'Intervalo em dias corridos (modo interval_days)';
COMMENT ON COLUMN public.medications.anchor_date IS
  'Data da primeira dose no ciclo (modo interval_days)';
