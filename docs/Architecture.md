# RentNear — Architecture Document

## 1. Overview

RentNear is a hyperlocal peer-to-peer rental platform built with **Flutter** (frontend) and **Supabase** (backend). The architecture follows **Clean Architecture** principles with a modular, feature-based folder structure. This ensures the codebase is scalable, testable, and easy to extend by a small team.

---

## 2. Architectural Philosophy

### Clean Architecture

All code is organized into layers with a strict one-direction dependency flow:

```
UI (Presentation) → Domain (Business Logic) → Data (Repository) → External (Supabase / FCM)
```

- **UI Layer** never talks directly to Supabase.
- **Domain Layer** contains all business rules and use cases.
- **Data Layer** handles all API calls, local cache, and mappers.
- **External Layer** is Supabase, Firebase, and any third-party SDK.

### Modular Feature-Based Structure

Each feature (auth, listings, rentals, requests, notifications) is fully self-contained. Teams can work on features in parallel without conflicts.

---

## 3. Tech Stack

| Layer | Technology | Rationale |
|---|---|---|
| Frontend | Flutter (Dart) | Single codebase, fast UI, iOS + Android from one repo |
| Backend | Supabase | Auth + DB + Storage + Realtime, zero DevOps overhead |
| Database | PostgreSQL via Supabase | Relational, scalable, migration support, PostGIS ready |
| Auth | Supabase Auth | Email / OTP / Google Sign-In, production-ready |
| Local Cache | Hive + SQLite | Offline support for listings and rental history |
| State Management | Riverpod | Reactive, testable, minimal boilerplate |
| Navigation | GoRouter | Declarative routing, deep-link support |
| Push Notifications | Firebase Cloud Messaging (FCM) | Geo-based alerts and request broadcast |
| Analytics | Firebase Analytics | Track user behavior and key events |
| Crash Reporting | Firebase Crashlytics | Production error monitoring |
| Secure Storage | flutter_secure_storage | Store auth tokens and keys safely |
| Hosting / CDN | Supabase Storage + Cloudflare | Item images and media assets |

---

## 4. Folder Structure

```
lib/
├── core/
│   ├── constants/            # App-wide constants (radii, limits, category list)
│   ├── errors/               # Custom exceptions and failure classes
│   ├── theme/                # Colors, typography, spacing, dark mode
│   ├── utils/                # Date helpers, distance calculator, formatters
│   └── widgets/              # Shared reusable UI widgets
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/  # Supabase auth calls
│   │   │   ├── models/       # UserModel (JSON ↔ Entity mapper)
│   │   │   └── repositories/ # AuthRepositoryImpl
│   │   ├── domain/
│   │   │   ├── entities/     # User entity
│   │   │   ├── repositories/ # AuthRepository (abstract interface)
│   │   │   └── usecases/     # LoginUseCase, SignupUseCase, LogoutUseCase
│   │   └── presentation/
│   │       ├── pages/        # LoginPage, SignupPage, OTPPage
│   │       ├── widgets/      # AuthFormField, SocialLoginButton
│   │       └── providers/    # AuthNotifier (Riverpod)
│   │
│   ├── listings/             # Add item, view listings, edit item
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── rentals/              # Booking flow, rental status, history
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── requests/             # Geo-broadcast rental requests
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── notifications/        # FCM handling, in-app alerts
│   ├── profile/              # User profile, ratings, earnings summary
│   └── home/                 # Home feed, search, category filter
│
├── services/
│   ├── supabase_service.dart     # Supabase client initialization
│   ├── fcm_service.dart          # Firebase push notification wrapper
│   ├── location_service.dart     # GPS access and radius calculations
│   └── analytics_service.dart   # Firebase Analytics wrapper
│
├── routes/
│   └── app_router.dart           # GoRouter route definitions
│
└── main.dart
```

---

## 5. Dependency Flow (Detailed)

```
Presentation (Riverpod Providers / Widgets)
        ↓
    Use Cases (Domain Layer)
        ↓
    Repository Interface (Domain Layer)
        ↓
    Repository Implementation (Data Layer)
        ↓
    Remote DataSource → Supabase
    Local DataSource  → Hive / SQLite
```

Rules:
- Providers call Use Cases only — never Data Layer directly.
- Use Cases call Repository abstractions — never concrete implementations.
- Data Layer implements repositories and calls Supabase.
- UI has zero direct Supabase dependency.

---

## 6. Key Architectural Decisions

### Location and Geo-Radius Logic
- User location stored as PostGIS `geography` type in Supabase.
- Radius filter (default 500m, user-adjustable to 100m or 1km) computed using `ST_DWithin` spatial query in Supabase.
- Flutter sends `lat/lng` on every search and request broadcast.

### Geo-Broadcast Notification Flow
```
User posts rental request
    → Supabase Edge Function triggered
    → Query users within 500m who own matching category item
    → Dispatch FCM notification via Firebase Admin SDK
    → Recipient opens notification → views request in-app
```

### Offline Support Strategy
- Home listings cached in Hive on first load.
- Rental history stored in SQLite for offline viewing.
- On reconnect → sync latest data from Supabase and refresh cache.
- Posting requests and completing bookings require live internet connection.

### Security Principles
- All database access controlled via Supabase Row Level Security (RLS).
- No direct table access from Flutter — all calls go through Supabase Auth context.
- Auth tokens stored in `flutter_secure_storage`, never in SharedPreferences.
- No API keys hardcoded in source — loaded via `.env` file excluded from version control.

---

## 7. External Integrations

| Service | Purpose |
|---|---|
| Supabase Auth | User login, OTP, session management |
| Supabase Storage | Item photo upload and retrieval |
| Supabase Realtime | Live rental status and chat updates |
| Supabase Edge Functions | Geo-broadcast notification dispatch logic |
| Firebase FCM | Push notification delivery to devices |
| Firebase Analytics | Track user sessions, events, funnels |
| Firebase Crashlytics | Capture runtime crashes and errors |
| PostGIS via Supabase | Spatial radius queries for nearby items |

---

## 8. Scalability Notes

- Supabase free tier handles full MVP load.
- Key indexes: `user_id`, `category`, `location (geography)`, `availability`, `created_at`.
- Images served via Supabase Storage CDN (Cloudflare-backed) — no separate CDN needed initially.
- Edge Functions handle notification dispatch logic — Flutter client stays lightweight.
- Upgrade path: Supabase Pro plan when usage grows — zero code changes required.
