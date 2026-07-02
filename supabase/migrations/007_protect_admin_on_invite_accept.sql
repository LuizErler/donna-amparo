-- Migration 007: impede convite de rebaixar Cuidador Admin no mesmo paciente.
-- Regra: se o usuario ja e admin do paciente, accept_care_invite falha (convite nao e consumido).

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

  IF EXISTS (
    SELECT 1
    FROM public.care_teams ct
    WHERE ct.profile_id = auth.uid()
      AND ct.patient_id = v_invite.patient_id
      AND ct.role = 'admin'
      AND ct.accepted_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'Voce ja e Cuidador Admin deste paciente';
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

REVOKE ALL ON FUNCTION public.accept_care_invite(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.accept_care_invite(uuid) TO authenticated;
