-- Hardening: helpers RLS sao usados apenas em policies, nao via RPC.
-- accept_care_invite permanece para authenticated.

REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_member_of_patient(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_patient_admin(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_write_care_data(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_manage_care_team(uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION public.handle_new_user() FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.is_member_of_patient(uuid) FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.is_patient_admin(uuid) FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.can_write_care_data(uuid) FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.can_manage_care_team(uuid) FROM anon, authenticated;

REVOKE ALL ON FUNCTION public.accept_care_invite(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.accept_care_invite(uuid) TO authenticated;
