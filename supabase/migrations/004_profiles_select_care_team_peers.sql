-- Membros do mesmo paciente podem ler perfis uns dos outros (lista do circulo familiar).

DROP POLICY IF EXISTS "profiles_select_care_team_peers" ON public.profiles;
CREATE POLICY "profiles_select_care_team_peers" ON public.profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1
      FROM public.care_teams mine
      JOIN public.care_teams peer ON peer.patient_id = mine.patient_id
      WHERE mine.profile_id = auth.uid()
        AND peer.profile_id = profiles.id
        AND mine.accepted_at IS NOT NULL
        AND peer.accepted_at IS NOT NULL
    )
  );
