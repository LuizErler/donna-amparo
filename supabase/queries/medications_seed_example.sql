-- Exemplo de seed para testes locais (SQL Editor)
-- Substitua :patient_id e :user_id pelos UUIDs reais.

-- INSERT INTO public.medications (patient_id, name, dosage, instructions, created_by)
-- VALUES (
--   :patient_id,
--   'Losartana',
--   '50 mg',
--   'Com agua, apos refeicao',
--   :user_id
-- )
-- RETURNING id;

-- INSERT INTO public.medication_schedules (medication_id, time_of_day)
-- VALUES
--   (:medication_id, '08:00'),
--   (:medication_id, '20:00');
