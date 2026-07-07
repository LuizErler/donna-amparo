# Edge Functions — push (#122)

## Secrets (Supabase Dashboard → Edge Functions → Secrets)

| Secret | Descricao |
|--------|-----------|
| `FIREBASE_SERVICE_ACCOUNT` | JSON da conta de servico Firebase (FCM HTTP v1) |
| `CRON_SECRET` | (opcional) Header `x-cron-secret` para o cron |

`SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY` sao injetados automaticamente.

### Gerar service account

1. Firebase Console → Project Settings → Service accounts
2. **Generate new private key** → salvar JSON
3. Colar o conteudo inteiro em `FIREBASE_SERVICE_ACCOUNT`

## Migration 012

Aplique `supabase/migrations/012_notification_jobs_workers.sql` no SQL Editor.

Cria:
- `claim_pending_notification_jobs`
- `enqueue_notification_job` / `cancel_notification_jobs_by_source`
- `insert_notification_inbox`

## Deploy

```bash
npx supabase@latest login
npx supabase@latest link --project-ref ufbyjvkuluyaxgqoubpm
npx supabase@latest secrets set FIREBASE_SERVICE_ACCOUNT="$(cat firebase-sa.json)"
npx supabase@latest secrets set CRON_SECRET="seu-segredo-cron"
npx supabase@latest functions deploy process-notification-jobs
npx supabase@latest functions deploy send-push
```

## Cron (a cada minuto)

Supabase Dashboard → Edge Functions → `process-notification-jobs` → **Schedules**  
Ou HTTP cron com header:

```
POST https://<project-ref>.supabase.co/functions/v1/process-notification-jobs
x-cron-secret: <CRON_SECRET>
```

## Teste manual — job na fila

Substitua UUIDs no SQL Editor:

```sql
SELECT public.enqueue_notification_job(
  p_patient_id := '<patient_uuid>',
  p_profile_id := '<profile_uuid>',
  p_type := 'ping',
  p_fire_at := now(),
  p_payload := '{"title":"Teste","body":"Job manual","route":"alertas"}'::jsonb,
  p_source_type := 'manual',
  p_source_id := 'test-1'
);
```

Depois invoque `process-notification-jobs` (cron ou POST manual).

## Teste direto — send-push

Com JWT de usuario autenticado (ou service role em dev):

```bash
curl -X POST "https://<project-ref>.supabase.co/functions/v1/send-push" \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"profile_id":"<uuid>","title":"Ping","body":"Teste","data":{"route":"alertas"}}'
```

## Fluxo

```
enqueue_notification_job (app / SQL)
  → notification_jobs (pending)
  → process-notification-jobs (cron)
  → FCM + insert_notification_inbox
  → job status sent/failed
```

Proximo plug-in: **#101** consultas (criar jobs nos offsets).
