-- Auditoria: medicamentos, horarios, periodo e doses
-- Substitua o UUID do paciente conforme necessario.

SELECT
  p.full_name AS paciente,
  m.id AS medication_id,
  m.name,
  m.dosage,
  m.instructions,
  m.is_active,
  m.schedule_mode,
  m.interval_hours,
  m.anchor_time,
  m.start_date,
  m.end_date,
  ms.id AS schedule_id,
  ms.time_of_day,
  ml.id AS log_id,
  ml.scheduled_for,
  ml.taken,
  ml.taken_at,
  pr.full_name AS taken_by_name
FROM public.medications m
JOIN public.patients p ON p.id = m.patient_id
LEFT JOIN public.medication_schedules ms ON ms.medication_id = m.id
LEFT JOIN public.medication_logs ml
  ON ml.medication_id = m.id
 AND ml.scheduled_time = ms.time_of_day
 AND ml.scheduled_for = CURRENT_DATE
LEFT JOIN public.profiles pr ON pr.id = ml.taken_by
WHERE m.patient_id = 'COLE_O_UUID_DO_PACIENTE_AQUI'
ORDER BY m.is_active DESC, m.name, ms.time_of_day;
