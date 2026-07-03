-- Lembretes configuraveis (estilo Calendario iOS) em vez de reminder_24h / notify_team.

ALTER TABLE public.appointments
  ADD COLUMN IF NOT EXISTS reminder_offsets_minutes integer[] NOT NULL DEFAULT '{1440}',
  ADD COLUMN IF NOT EXISTS team_notify_offsets_minutes integer[] NOT NULL DEFAULT '{}';

UPDATE public.appointments
SET
  reminder_offsets_minutes = CASE
    WHEN reminder_24h IS TRUE THEN ARRAY[1440]::integer[]
    ELSE ARRAY[]::integer[]
  END,
  team_notify_offsets_minutes = CASE
    WHEN notify_team IS TRUE THEN ARRAY[1440]::integer[]
    ELSE ARRAY[]::integer[]
  END
WHERE reminder_24h IS NOT NULL OR notify_team IS NOT NULL;

ALTER TABLE public.appointments
  DROP COLUMN IF EXISTS reminder_24h,
  DROP COLUMN IF EXISTS notify_team;

COMMENT ON COLUMN public.appointments.reminder_offsets_minutes IS
  'Minutos antes de appointment_date para alertas pessoais (ex.: 1440 = 1 dia).';
COMMENT ON COLUMN public.appointments.team_notify_offsets_minutes IS
  'Minutos antes de appointment_date para avisar o circulo de cuidado.';
