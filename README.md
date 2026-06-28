# Donna Amparo

> Cuidado familiar inteligente — acompanhe a saude de quem voce ama.

Donna Amparo e um aplicativo mobile e web desenvolvido em Flutter, voltado para familias que cuidam de pessoas idosas ou que precisam de acompanhamento continuo de saude. Com uma interface calorosa e intuitiva, centraliza medicamentos, consultas, hidratacao e comunicacao familiar em um so lugar.

---

## Funcionalidades

- **Inicio** — Visao geral do dia: proximo medicamento, progresso de hidratacao, proxima consulta e pendencias da familia
- **Medicamentos** — Lista de doses organizada por periodo (Manha / Tarde / Noite) com confirmacao interativa e barra de progresso diaria
- **Consultas** — Agenda medica com proximas consultas em destaque e historico completo com anotacoes medicas
- **Calendario** — Visao mensal agregando consultas, horarios de medicamentos e outros compromissos
- **Alertas** — Pendencias e itens resolvidos com filtros por categoria (Medicamentos, Consultas, Vitais, Hidratacao, Familia)
- **Perfil** (menu superior) — Dados do cuidador, circulo familiar, notificacoes, privacidade e preferencias de sistema (tema claro / escuro)

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

## Diagrama Entidade-Relacionamento

```mermaid
erDiagram
    AUTH_USERS {
        uuid id PK
        string email
    }
    PROFILES {
        uuid id PK
        string full_name
        string email
        string phone
        string avatar_url
        datetime created_at
        datetime last_seen_at
    }
    PATIENTS {
        uuid id PK
        string full_name
        date date_of_birth
        string blood_type
        string allergies
        string primary_diagnosis
        string emergency_contact
        uuid created_by FK
        datetime created_at
    }
    CARE_TEAMS {
        int id PK
        uuid profile_id FK
        uuid patient_id FK
        string role
        uuid invited_by FK
        datetime accepted_at
        datetime created_at
    }
    MEDICATIONS {
        int id PK
        uuid patient_id FK
        string name
        string dosage
        string frequency
        string schedule_time
        date start_date
        date end_date
        string instructions
        uuid created_by FK
        datetime created_at
    }
    MEDICATION_LOGS {
        uuid id PK
        int medication_id FK
        uuid patient_id FK
        boolean taken
        string skipped_reason
        datetime taken_at
        uuid taken_by FK
        string notes
        datetime created_at
    }
    VITAL_SIGNS {
        int id PK
        uuid patient_id FK
        string type
        string value
        string unit
        string notes
        uuid recorded_by FK
        datetime recorded_at
    }
    APPOINTMENTS {
        int id PK
        uuid patient_id FK
        string title
        string doctor
        string specialty
        string location
        datetime appointment_date
        string visit_type
        string notes
        boolean reminder_24h
        boolean notify_team
        uuid created_by FK
        datetime created_at
    }
    ACTIVITY_LOGS {
        int id PK
        uuid patient_id FK
        uuid profile_id FK
        string type
        string title
        string subtitle
        string notes
        datetime created_at
    }

    AUTH_USERS ||--|| PROFILES : "1-1"
    PROFILES ||--o{ CARE_TEAMS : "profile_id"
    PROFILES ||--o{ ACTIVITY_LOGS : "profile_id"
    PROFILES ||--o{ PATIENTS : "created_by"
    PATIENTS ||--o{ CARE_TEAMS : "patient_id"
    PATIENTS ||--o{ MEDICATIONS : "patient_id"
    PATIENTS ||--o{ MEDICATION_LOGS : "patient_id"
    PATIENTS ||--o{ VITAL_SIGNS : "patient_id"
    PATIENTS ||--o{ APPOINTMENTS : "patient_id"
    PATIENTS ||--o{ ACTIVITY_LOGS : "patient_id"
    MEDICATIONS ||--o{ MEDICATION_LOGS : "medication_id"
    PROFILES ||--o{ MEDICATION_LOGS : "taken_by"
    PROFILES ||--o{ VITAL_SIGNS : "recorded_by"
```


## Licenca

MIT © 2026 Donna Amparo
