# RentNear — Monorepo Structure

---

## 1. Overview

RentNear is organized as a **single-repository** project containing the Flutter mobile app, Supabase backend (migrations + Edge Functions), CI/CD configuration, and shared assets. The Flutter codebase follows **Clean Architecture** with a feature-based modular structure.

---

## 2. Top-Level Repository Structure

```
rentnear/
│
├── lib/                          # Flutter application source code
│   ├── core/                     # Shared app-wide code
│   ├── features/                 # Feature modules (Clean Architecture)
│   ├── services/                 # External service wrappers
│   ├── routes/                   # GoRouter navigation
│   └── main.dart                 # App entrypoint
│
├── assets/                       # Static assets
│   ├── images/                   # App logo, placeholders, illustrations
│   └── icons/                    # Category and UI icons
│
├── test/                         # Unit and widget tests
│   ├── core/                     # Tests for shared utilities
│   └── features/                 # Tests mirror feature structure
│       ├── auth/
│       ├── listings/
│       ├── rentals/
│       └── ...
│
├── integration_test/             # End-to-end integration tests
│   ├── auth_flow_test.dart
│   ├── rental_flow_test.dart
│   └── ...
│
├── supabase/                     # Supabase backend
│   ├── migrations/               # SQL schema migration files
│   │   ├── 20260301000000_create_users.sql
│   │   ├── 20260301000001_create_listings.sql
│   │   ├── 20260301000002_create_rentals.sql
│   │   ├── 20260301000003_create_requests.sql
│   │   ├── 20260301000004_create_user_inventory.sql
│   │   ├── 20260301000005_create_ratings.sql
│   │   ├── 20260301000006_create_reports.sql
│   │   ├── 20260301000007_create_notifications.sql
│   │   ├── 20260301000008_create_rls_policies.sql
│   │   └── 20260301000009_create_functions.sql
│   ├── functions/                # Supabase Edge Functions
│   │   └── broadcast_request/
│   │       └── index.ts
│   ├── seed.sql                  # Optional seed data for development
│   └── config.toml               # Supabase project config
│
├── .github/                      # GitHub Actions CI/CD
│   └── workflows/
│       └── ci.yml
│
├── docs/                         # Project documentation (this folder)
│   ├── product-requirements.md
│   ├── user-stories-and-acceptance.md
│   ├── information-architecture.md
│   ├── system-architecture.md
│   ├── database-schema.md
│   ├── api-contracts.md
│   ├── monorepo-structure.md
│   ├── scoring-engine-spec.md
│   ├── engineering-scope-definition.md
│   ├── development-phases.md
│   ├── environment-and-devops.md
│   └── testing-strategy.md
│
├── pubspec.yaml                  # Flutter dependencies
├── pubspec.lock                  # Dependency lock file
├── analysis_options.yaml         # Dart analyzer configuration
├── .env.example                  # Environment variable template
├── .gitignore                    # Git ignore rules
├── README.md                     # Project README
└── LICENSE                       # License file
```

---

## 3. Flutter Source (`lib/`) — Detailed

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart          # Radius defaults, limits, rate limits
│   │   ├── category_constants.dart     # Item category list and labels
│   │   └── api_constants.dart          # Supabase table names, function names
│   │
│   ├── errors/
│   │   ├── exceptions.dart             # Custom exception classes
│   │   └── failures.dart               # Failure sealed classes for use cases
│   │
│   ├── theme/
│   │   ├── app_colors.dart             # Color palette
│   │   ├── app_typography.dart         # Text styles
│   │   ├── app_spacing.dart            # Spacing constants (paddings, margins)
│   │   └── app_theme.dart              # ThemeData builder
│   │
│   ├── utils/
│   │   ├── date_helpers.dart           # Date formatting utilities
│   │   ├── distance_calculator.dart    # Distance display (e.g., "300m away")
│   │   ├── validators.dart             # Input validation helpers
│   │   └── currency_formatter.dart     # Price formatting (₹X/day)
│   │
│   └── widgets/
│       ├── app_button.dart             # Reusable primary/secondary buttons
│       ├── app_text_field.dart         # Styled text input
│       ├── loading_indicator.dart      # Full-screen loading overlay
│       ├── error_widget.dart           # Error state display
│       ├── empty_state_widget.dart     # No data illustrations
│       └── rating_stars.dart           # Star rating display component
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── login_usecase.dart
│   │   │       ├── signup_usecase.dart
│   │   │       ├── verify_otp_usecase.dart
│   │   │       └── logout_usecase.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── login_page.dart
│   │       │   ├── signup_page.dart
│   │       │   ├── otp_page.dart
│   │       │   └── onboarding_inventory_page.dart
│   │       ├── widgets/
│   │       │   ├── auth_form_field.dart
│   │       │   └── social_login_button.dart
│   │       └── providers/
│   │           └── auth_notifier.dart
│   │
│   ├── listings/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── listing_remote_datasource.dart
│   │   │   │   └── listing_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── listing_model.dart
│   │   │   └── repositories/
│   │   │       └── listing_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── listing.dart
│   │   │   ├── repositories/
│   │   │   │   └── listing_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_nearby_listings_usecase.dart
│   │   │       ├── create_listing_usecase.dart
│   │   │       ├── update_listing_usecase.dart
│   │   │       └── delete_listing_usecase.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── add_listing_page.dart
│   │       │   └── edit_listing_page.dart
│   │       ├── widgets/
│   │       │   ├── listing_card.dart
│   │       │   └── category_filter_tabs.dart
│   │       └── providers/
│   │           └── listings_notifier.dart
│   │
│   ├── rentals/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── my_rentals_page.dart
│   │       │   ├── rental_detail_page.dart
│   │       │   ├── rental_request_page.dart
│   │       │   └── rental_agreement_page.dart
│   │       ├── widgets/
│   │       │   ├── rental_card.dart
│   │       │   └── status_badge.dart
│   │       └── providers/
│   │           └── rentals_notifier.dart
│   │
│   ├── requests/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── post_request_page.dart
│   │       ├── widgets/
│   │       │   └── request_card.dart
│   │       └── providers/
│   │           └── requests_notifier.dart
│   │
│   ├── notifications/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── notifications_page.dart
│   │       └── providers/
│   │           └── notifications_notifier.dart
│   │
│   ├── profile/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── profile_page.dart
│   │       │   ├── edit_profile_page.dart
│   │       │   └── other_user_profile_page.dart
│   │       └── providers/
│   │           └── profile_notifier.dart
│   │
│   └── home/
│       └── presentation/
│           ├── pages/
│           │   ├── home_page.dart
│           │   └── item_detail_page.dart
│           ├── widgets/
│           │   ├── search_bar.dart
│           │   └── home_listing_card.dart
│           └── providers/
│               └── home_notifier.dart
│
├── services/
│   ├── supabase_service.dart           # Supabase client initialization
│   ├── fcm_service.dart                # Firebase push notification wrapper
│   ├── location_service.dart           # GPS access and distance calculations
│   └── analytics_service.dart          # Firebase Analytics wrapper
│
├── routes/
│   └── app_router.dart                 # GoRouter route definitions
│
└── main.dart                           # App entry point
```

---

## 4. Key Configuration Files

| File | Purpose |
|---|---|
| `pubspec.yaml` | Flutter dependencies and assets |
| `analysis_options.yaml` | Dart linter rules |
| `.env.example` | Template for environment variables |
| `supabase/config.toml` | Supabase project configuration |
| `.github/workflows/ci.yml` | CI/CD pipeline |
| `.gitignore` | Excludes `.env`, build outputs, platform junk |

---

## 5. Naming Conventions

| Item | Convention | Example |
|---|---|---|
| Dart files | snake_case | `listing_model.dart` |
| Classes | PascalCase | `ListingModel` |
| Providers | camelCase | `listingsNotifierProvider` |
| SQL migrations | `YYYYMMDDHHMMSS_desc.sql` | `20260301000000_create_users.sql` |
| Edge Functions | snake_case directories | `broadcast_request/` |
| Test files | `*_test.dart` | `auth_repository_test.dart` |
| Feature folders | snake_case | `features/listings/` |
