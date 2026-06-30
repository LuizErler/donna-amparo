-- Corrige migration 002: helpers RLS precisam de EXECUTE para authenticated.
-- anon permanece sem acesso (nao exposto via RPC anon).

GRANT EXECUTE ON FUNCTION public.is_member_of_patient(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_patient_admin(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_write_care_data(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_manage_care_team(uuid) TO authenticated;

-- Onboarding: criador pode ler paciente antes do care_team existir.
DROP POLICY IF EXISTS "patients_select_creator" ON public.patients;
CREATE POLICY "patients_select_creator" ON public.patients
  FOR SELECT USING (created_by = auth.uid());
