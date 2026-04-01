# RentNear — System Architecture

---

## 1. Architecture Overview

RentNear follows **Clean Architecture** principles with a modular, feature-based structure. The system is built as a **Flutter mobile app** (iOS + Android) backed by **Supabase** (BaaS) and **Firebase** services.

**Scale target (MVP):** 1–5 societies, ~500 concurrent users, ~1,000 listings

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App (Client)                  │
│                                                          │
│  Home │ Listings │ Rentals │ Requests │ Profile          │
│                                                          │
│  Riverpod State  │  GoRouter  │  Hive Cache              │
└────────────────────────┬────────────────────────────────┘
                         │ HTTPS / WSS
         ┌───────────────▼──────────────────┐
         │           Supabase               │
         │                                  │
         │  ┌──────────┐  ┌──────────────┐  │
         │  │  Auth    │  │  PostgreSQL  │  │
         │  │ (JWT)    │  │  + PostGIS   │  │
         │  └──────────┘  └──────────────┘  │
         │  ┌──────────┐  ┌──────────────┐  │
         │  │ Storage  │  │  Realtime    │  │
         │  │ (Images) │  │  (WebSocket) │  │
         │  └──────────┘  └──────────────┘  │
         │  ┌──────────────────────────────┐ │
         │  │     Edge Functions           │ │
         │  │  (Geo-broadcast dispatcher)  │ │
         │  └──────────────────────────────┘ │
         └───────────────┬──────────────────┘
                         │
         ┌───────────────▼──────────────────┐
         │         Firebase Services        │
         │  FCM  │  Analytics  │ Crashlytics │
         └──────────────────────────────────┘
```

---

## 2. Clean Architecture Layers

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

### Layer Rules

| Rule | Description |
|---|---|
| **UI → Domain only** | Providers call Use Cases — never Data Layer directly |
| **Domain is abstract** | Use Cases call Repository interfaces — never concrete implementations |
| **Data implements** | Data Layer implements repositories and calls Supabase |
| **No leaking** | UI has zero direct Supabase dependency |

---

## 3. Technology Stack

| Layer | Technology | Rationale |
|---|---|---|
| Frontend | Flutter (Dart) | Single codebase, fast UI, iOS + Android |
| Backend | Supabase | Auth + DB + Storage + Realtime, zero DevOps |
| Database | PostgreSQL + PostGIS | Relational, spatial queries, migration support |
| Auth | Supabase Auth | Email/OTP/Google, production-ready |
| Local Cache | Hive + SQLite | Offline support for listings and rental history |
| State Mgmt | Riverpod | Reactive, testable, minimal boilerplate |
| Navigation | GoRouter | Declarative routing, deep-link support |
| Push Notify | Firebase FCM | Geo-based alerts and request broadcast |
| Analytics | Firebase Analytics | User behavior and funnel tracking |
| Crash Report | Firebase Crashlytics | Production error monitoring |
| Secure Storage | flutter_secure_storage | Auth tokens and keys |
| Image CDN | Supabase Storage | Cloudflare-backed CDN |

---

## 4. Feature Modules

Each feature is self-contained with its own data/domain/presentation layers:

```
features/
├── auth/             # Signup, Login, OTP, Onboarding
├── listings/         # Add, view, edit, delete items
├── rentals/          # Booking flow, status, history
├── requests/         # Geo-broadcast rental requests
├── notifications/    # FCM handling, in-app alerts
├── profile/          # User profile, ratings, earnings
└── home/             # Feed, search, category filter
```

### Module Structure (per feature)
```
feature_name/
├── data/
│   ├── datasources/   # Supabase API calls
│   ├── models/        # JSON ↔ Entity mappers
│   └── repositories/  # Repository implementations
├── domain/
│   ├── entities/      # Pure business objects
│   ├── repositories/  # Abstract interfaces
│   └── usecases/      # Business logic operations
└── presentation/
    ├── pages/         # Screen widgets
    ├── widgets/       # Feature-specific UI components
    └── providers/     # Riverpod state notifiers
```

---

## 5. External Integrations

| Service | Purpose | Communication |
|---|---|---|
| Supabase Auth | User login, OTP, session management | HTTPS (REST) |
| Supabase PostgreSQL | All persistent data | HTTPS (PostgREST) |
| Supabase Realtime | Live rental status, chat updates | WSS (WebSocket) |
| Supabase Storage | Item photo upload and retrieval | HTTPS (S3-compatible) |
| Supabase Edge Functions | Geo-broadcast notification dispatch | HTTPS (Deno runtime) |
| Firebase FCM | Push notification delivery | HTTPS (Firebase SDK) |
| Firebase Analytics | Session/event/funnel tracking | Firebase SDK |
| Firebase Crashlytics | Runtime crash capture | Firebase SDK |
| PostGIS | Spatial radius queries for nearby items | Via Supabase SQL functions |

---

## 6. Communication Flows

### Rental Request Flow
```
Flutter Client                    Supabase                     Firebase
      │                              │                              │
      │── POST /rentals ────────────▶│                              │
      │   (borrower_id, dates, cost) │                              │
      │                              │── Insert rentals row ───────▶│
      │                              │── Trigger notification ─────▶│
      │                              │                    FCM Push ─┤
      │◀── 201 Created ─────────────│                              │
      │                              │                              │
      │◀── Realtime (status update) ─│ (lender accepts/rejects)    │
```

### Geo-Broadcast Flow
```
Flutter Client          Supabase Edge Function         Firebase FCM
      │                         │                          │
      │── POST /requests ──────▶│                          │
      │                         │── rpc: get_nearby_       │
      │                         │   inventory_users ──┐    │
      │                         │                     │    │
      │                         │◀── user list ───────┘    │
      │                         │                          │
      │                         │── POST FCM (per user) ──▶│
      │                         │                          │── Push
      │◀── 200 OK ─────────────│                          │
```

---

## 7. Offline Strategy

| Data | Storage | Sync Strategy |
|---|---|---|
| Home feed listings | Hive | Cache on first fetch, refresh on reconnect |
| Rental history | SQLite | Append on completion, full sync on login |
| User profile | Hive | Cache on login, invalidate on update |
| Active rentals | In-memory | Always fetch live — no offline write |
| Notifications | Hive | Cache last 50, clear on read |

**Connectivity detection:**
```dart
final isOnline = await Connectivity().checkConnectivity() != ConnectivityResult.none;
if (!isOnline) {
  return ref.read(listingCacheProvider).getCachedListings();
}
```

---

## 8. Security Architecture

| Area | Control |
|---|---|
| API access | Supabase RLS on all tables |
| Auth tokens | Supabase JWT, rotated automatically |
| Local storage | `flutter_secure_storage` only for sensitive data |
| Image access | Supabase Storage bucket policies |
| API keys | `--dart-define` at build time, never in source code |
| Edge Functions | Service role key, never exposed to client |
| Input validation | All fields validated client-side + server-side |
| Rate limiting | Geo-broadcast limited to 3/day per user |
| HTTPS | Enforced on all Supabase calls (default) |

---

## 9. Scalability Path

| Concern | MVP Approach | Scale Approach |
|---|---|---|
| Hosting | Supabase free tier | Supabase Pro plan (zero code changes) |
| Database | PostgreSQL with key indexes | Connection pooling, read replicas |
| Images | Supabase Storage (Cloudflare CDN) | Same — auto-scales |
| Notifications | Edge Function + FCM | Queue-based dispatcher |
| Key Indexes | `user_id`, `category`, `location`, `availability`, `created_at` | Partial indexes, materialized views |
