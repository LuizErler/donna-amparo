-- Auditoria do circulo familiar (care_teams + convites)
-- Rode no Supabase SQL Editor apos alterar papel ou remover membro no app.

-- 1) Visao geral: membros por paciente (papel, aceite, perfil)
SELECT
  p.full_name AS paciente,
  pr.full_name AS membro,
  pr.email,
  ct.role,
  ct.accepted_at,
  ct.created_at,
  ct.profile_id,
  ct.patient_id
FROM public.care_teams ct
JOIN public.patients p ON p.id = ct.patient_id
JOIN public.profiles pr ON pr.id = ct.profile_id
ORDER BY p.full_name, ct.created_at;

-- 2) Filtrar por e-mail do membro (troque o valor)
-- SELECT ... WHERE pr.email ILIKE '%rodri@rodri.com%';

-- 3) Convites (pendentes e aceitos)
SELECT
  p.full_name AS paciente,
  ci.role,
  ci.token,
  ci.expires_at,
  ci.accepted_at,
  ci.accepted_by,
  inviter.email AS convidado_por,
  ci.created_at
FROM public.care_invites ci
JOIN public.patients p ON p.id = ci.patient_id
LEFT JOIN auth.users inviter ON inviter.id = ci.invited_by
ORDER BY ci.created_at DESC;

-- 4) Contagem de admins por paciente (deve ser >= 1)
SELECT
  p.full_name AS paciente,
  COUNT(*) FILTER (WHERE ct.role = 'admin' AND ct.accepted_at IS NOT NULL) AS admins_ativos,
  COUNT(*) FILTER (WHERE ct.accepted_at IS NOT NULL) AS membros_ativos
FROM public.patients p
LEFT JOIN public.care_teams ct ON ct.patient_id = p.id
GROUP BY p.id, p.full_name
ORDER BY p.full_name;
