# Push notifications (FCM) — setup

## 1. Firebase Console

1. Crie um projeto em [Firebase Console](https://console.firebase.google.com/)
2. Adicione app **Android** (`com.example.meu_app` ou o applicationId final)
3. Adicione app **iOS** (bundle id do Xcode)
4. Ative **Cloud Messaging**
5. iOS: envie a chave **APNs** (.p8) em Project Settings → Cloud Messaging

## 2. Credenciais no app (dart-define)

Copie os valores do Firebase para `dart_defines.local.json`:

```json
{
  "FIREBASE_API_KEY": "...",
  "FIREBASE_APP_ID": "...",
  "FIREBASE_MESSAGING_SENDER_ID": "...",
  "FIREBASE_PROJECT_ID": "...",
  "FIREBASE_IOS_BUNDLE_ID": "com.example.meuApp"
}
```

Ou rode:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

e transcreva os valores para os defines (evita commitar `google-services.json`).

Para Android, copie também `google-services.json` para `android/app/` (ver `google-services.json.example`).
O plugin Gradle só é aplicado quando esse arquivo existir — sem ele o app compila, mas push nativo não funciona.

## 3. Supabase

Aplique a migration `011_push_notifications_platform.sql`.

## 4. Testar token

1. `flutter run --dart-define-from-file=dart_defines.local.json`
2. Faça login
3. Aceite permissão de notificação
4. Verifique linha em `device_tokens` no Supabase SQL Editor

## 5. Push de teste (Firebase Console)

Project → Messaging → New campaign → Send test message  
Cole o token FCM do passo 4.

Payload sugerido (deep link):

```json
{
  "route": "alertas"
}
```

## Próximas fases

- Edge Functions `send-push` + `process-notification-jobs` (#122)
- Plug-in consultas (#101)
