# Donna Amparo

> Cuidado familiar inteligente — acompanhe a saude de quem voce ama.

Donna Amparo e um aplicativo mobile e web desenvolvido em Flutter, voltado para familias que cuidam de pessoas idosas ou que precisam de acompanhamento continuo de saude. Com uma interface calorosa e intuitiva, centraliza medicamentos, consultas, hidratacao e comunicacao familiar em um so lugar.

---

## Funcionalidades

- **Inicio** — Visao geral do dia: proximo medicamento, progresso de hidratacao, proxima consulta e pendencias da familia
- **Medicamentos** — Lista de doses organizada por periodo (Manha / Tarde / Noite) com confirmacao interativa e barra de progresso diaria
- **Consultas** — Agenda medica com proximas consultas em destaque e historico completo com anotacoes medicas
- **Familia** — Circulo familiar com membros, papeis (cuidador, observador) e feed de atividades em tempo real
- **Alertas** — Pendencias e itens resolvidos com filtros por categoria (Medicamentos, Consultas, Vitais, Hidratacao, Familia)
- **Configuracoes** — Perfil do usuario, alternancia de tema (claro / escuro / sistema) e preferencias gerais

---

## Tecnologias

- [Flutter](https://flutter.dev/) — Framework multiplataforma (Android, iOS, Web, Desktop)
- [Dart](https://dart.dev/) — Linguagem de programacao
- [Google Fonts](https://pub.dev/packages/google_fonts) — Tipografia Inter
- [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) — Icones do app para todas as plataformas
- Material Design 3

---

## Como rodar localmente

**Pre-requisitos:** Flutter SDK instalado ([flutter.dev/install](https://flutter.dev/install))

```bash
# Clonar o repositorio
git clone https://github.com/LuizErler/donna-amparo.git
cd donna-amparo

# Instalar dependencias
flutter pub get

# Rodar no browser
flutter run -d chrome

# Rodar no emulador Android
flutter run -d emulator-5554

# Build web para producao
flutter build web --base-href /donna-amparo/
```

---

## Estrutura do projeto

```
lib/
├── core/
│   └── theme/
│       └── app_theme.dart        # Tema global (claro e escuro)
└── features/
    ├── home/
    │   └── home_page.dart        # Tela inicial
    ├── medicamentos/
    │   └── medicamentos_page.dart # Gestao de doses diarias
    ├── consultas/
    │   └── consultas_page.dart   # Agenda medica
    ├── familia/
    │   └── familia_page.dart     # Circulo familiar
    ├── alertas/
    │   └── alertas_page.dart     # Notificacoes e pendencias
    └── configuracoes/
        └── configuracoes_page.dart # Perfil e sistema
```

---

## Identidade Visual

| Token | Valor | Uso |
|---|---|---|
| `primary` | `#C1622A` | Cor principal (terracota) |
| `background` | `#F5EDE3` | Fundo geral (bege creme) |
| `cardNormal` | `#FAF0E6` | Cards e paineis |
| `textPrimary` | `#2D1B0E` | Titulos e textos principais |
| Fonte | **Inter** (Google Fonts) | Toda a tipografia |

O app suporta **modo claro** e **modo escuro** com paleta adaptada, acessivel nas configuracoes do perfil.

---


DER:

DerDiagram
    auth_users {
        uuid id PK
        text email
    }

    profiles {
        uuid id PK,FK
        text full_name
        text email
        text phone
        text avatar_url
        timestamptz created_at
        timestamptz last_seen_at
    }

    patients {
        uuid id PK
        text full_name
        date date_of_birth
        text blood_type
        text allergies
        text primary_diagnosis
        text emergency_contact
        uuid created_by FK
        timestamptz created_at
    }

    care_teams {
        bigint id PK
        uuid profile_id FK
        uuid patient_id FK
        text role
        uuid invited_by FK
        timestamptz accepted_at
        timestamptz created_at
    }

    medications {
        bigint id PK
        uuid patient_id FK
        text name
        text dosage
        text frequency
        time[] schedule_time
        date start_date
        date end_date
        text instructions
        uuid created_by FK
        timestamptz created_at
    }

    medication_logs {
        uuid id PK
        bigint medication_id FK
        uuid patient_id FK
        boolean taken
        text skipped_reason
        timestamptz taken_at
        uuid taken_by FK
        text notes
        timestamptz created_at
    }

    vital_signs {
        bigint id PK
        uuid patient_id FK
        text type
        text value
        text unit
        text notes
        uuid recorded_by FK
        timestamptz recorded_at
    }

    appointments {
        bigint id PK
        uuid patient_id FK
        text title
        text doctor
        text specialty
        text location
        timestamptz appointment_date
        text visit_type
        text notes
        boolean reminder_24h
        boolean notify_team
        uuid created_by FK
        timestamptz created_at
    }

    activity_logs {
        bigint id PK
        uuid patient_id FK
        uuid profile_id FK
        text type
        text title
        text subtitle
        text notes
        timestamptz created_at
    }

    auth_users ||--|| profiles : "1:1"
    profiles ||--o{ care_teams : "profile_id"
    profiles ||--o{ activity_logs : "profile_id"
    profiles ||--o{ patients : "created_by"
    patients ||--o{ care_teams : "patient_id"
    patients ||--o{ medications : "patient_id"
    patients ||--o{ medication_logs : "patient_id"
    patients ||--o{ vital_signs : "patient_id"
    patients ||--o{ appointments : "patient_id"
    patients ||--o{ activity_logs : "patient_id"
    medications ||--o{ medication_logs : "medication_id"
    profiles ||--o{ medication_logs : "taken_by"
    profiles ||--o{ vital_signs : "recorded_by"


## Licenca

MIT © 2026 Donna Amparo
