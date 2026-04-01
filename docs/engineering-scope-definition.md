# RentNear — Engineering Scope Definition

---

## 1. Project Overview

| Attribute | Value |
|---|---|
| Product | RentNear — Hyperlocal P2P Rental Platform |
| Platform | iOS + Android (single Flutter codebase) |
| Backend | Supabase (Auth, PostgreSQL, Storage, Realtime, Edge Functions) |
| Target MVP Duration | 4 weeks |
| Team Size | 1–3 developers |
| Scale Target (MVP) | 1–5 societies, ~500 concurrent users, ~1,000 listings |

---

## 2. MVP Feature Scope — In-Scope

### Core Features (Must Ship)

| # | Feature | Complexity | Estimated Effort |
|---|---|---|---|
| 1 | Email + OTP Authentication | Medium | 2–3 days |
| 2 | Inventory Onboarding Checklist | Low | 1 day |
| 3 | Home Feed (location-based, filterable) | High | 3–4 days |
| 4 | Add / Edit / Delete Listing | Medium | 2–3 days |
| 5 | Item Detail Page | Medium | 1–2 days |
| 6 | Rental Request Flow (dates, cost, confirm) | High | 3–4 days |
| 7 | Request Accept/Reject for Lender | Medium | 1–2 days |
| 8 | My Rentals Dashboard (Renting + Lending tabs) | Medium | 2–3 days |
| 9 | Geo-Broadcast Request + Edge Function | High | 3–4 days |
| 10 | Push Notifications (FCM integration) | Medium | 2–3 days |
| 11 | Ratings & Reviews (post-rental) | Medium | 1–2 days |
| 12 | User Profile (stats, badges, history) | Medium | 1–2 days |
| 13 | Rental Agreement Display | Low | 0.5 day |
| 14 | Report Issue | Low | 0.5 day |
| 15 | Offline Cache (Hive + SQLite) | Medium | 2 days |

**Total estimated dev effort:** ~20–28 working days

---

### Infrastructure Work (Must Complete)

| # | Task | Effort |
|---|---|---|
| 1 | Flutter project setup (Clean Architecture scaffold) | 1 day |
| 2 | Supabase project setup (tables, RLS, functions) | 1–2 days |
| 3 | Firebase setup (FCM, Analytics, Crashlytics) | 0.5 day |
| 4 | GoRouter navigation skeleton | 0.5 day |
| 5 | Core theme, constants, shared widgets | 1 day |
| 6 | CI/CD pipeline (GitHub Actions) | 0.5 day |
| 7 | App store submission prep (icons, screenshots, signing) | 2 days |

---

## 3. Out-of-Scope (MVP)

The following features are explicitly **excluded** from the MVP scope. They will be evaluated post-validation.

| Feature | Reason for Exclusion |
|---|---|
| In-app payments (Razorpay/Stripe) | Regulatory complexity; MVP uses offline payments |
| In-app chat | Not critical for MVP flow; coordination via external messaging |
| Dark mode | Nice-to-have; no impact on core value proposition |
| Google Sign-In | Adds OAuth complexity; email + OTP covers auth needs |
| Referral / Invite system | Premature for single-society pilot |
| Wallet & earnings payout | Requires payment integration |
| Multi-language support | Single-city pilot in one language |
| Admin moderation dashboard | Manual review via Supabase dashboard for MVP |
| AI-based pricing suggestions | Insufficient data at launch |
| Delivery coordination | Out of scope; pickup is in-person |
| Insurance / damage guarantee | Legal complexity beyond MVP |
| Multi-city / multi-society | Validate single society first |
| Business / commercial listings | Consumer P2P only for MVP |

---

## 4. Technical Boundaries

### Client (Flutter)
- **Minimum SDK:** Flutter 3.x stable
- **Target platforms:** Android 6.0+ (API 23), iOS 14.0+
- **Architecture:** Clean Architecture with feature-based modules
- **State management:** Riverpod only (no BLoC, no GetX)
- **Navigation:** GoRouter only
- **No web app** — mobile-only for MVP

### Backend (Supabase)
- **Tier:** Free plan (sufficient for MVP load)
- **Database:** PostgreSQL 15+ with PostGIS extension
- **Auth:** Supabase Auth (email + OTP)
- **Storage:** Supabase Storage for listing images
- **Edge Functions:** Deno runtime (TypeScript)
- **No custom backend server** — Supabase handles all backend needs

### Firebase
- **FCM:** Push notifications only
- **Analytics:** Event tracking
- **Crashlytics:** Crash reporting
- **No Firestore, no RTDB** — all data lives in Supabase

---

## 5. Engineering Constraints

| Constraint | Detail |
|---|---|
| Single codebase | One Flutter repo for iOS + Android |
| No server maintenance | Supabase managed; zero DevOps |
| RLS-first security | All table access controlled by Row Level Security |
| No API keys in code | All secrets via `--dart-define` or `.env` |
| Offline-first for reads | Home feed and rental history cached locally |
| Online-only for writes | Posting requests and completing bookings require network |
| Rate limiting | Max 3 geo-broadcast requests per user per day |

---

## 6. Dependency Matrix

### External Service Dependencies

| Service | Dependency Level | Fallback |
|---|---|---|
| Supabase Auth | Critical (no auth = no app) | None |
| Supabase PostgreSQL | Critical (all data) | Local cache for reads |
| Supabase Storage | High (listing images) | Placeholder images |
| Supabase Realtime | Medium (live status) | Pull-to-refresh |
| Firebase FCM | High (notifications) | In-app notification tab |
| Firebase Analytics | Low (tracking) | App works without it |
| Firebase Crashlytics | Low (monitoring) | App works without it |
| GPS / Location | High (core feature) | Manual area selection |

### Package Dependencies (Flutter)

| Package | Version | Purpose |
|---|---|---|
| `supabase_flutter` | latest | Supabase SDK |
| `flutter_riverpod` | latest | State management |
| `go_router` | latest | Navigation |
| `hive` + `hive_flutter` | latest | Local cache |
| `sqflite` | latest | SQLite for rental history |
| `flutter_secure_storage` | latest | Secure token storage |
| `firebase_core` | latest | Firebase initialization |
| `firebase_messaging` | latest | FCM |
| `firebase_analytics` | latest | Analytics |
| `firebase_crashlytics` | latest | Crash reporting |
| `geolocator` | latest | GPS access |
| `image_picker` | latest | Photo selection |
| `cached_network_image` | latest | Image caching |
| `intl` | latest | Date/currency formatting |
| `connectivity_plus` | latest | Network detection |

---

## 7. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Low user adoption in pilot | Medium | High | Pre-launch community engagement |
| GPS accuracy issues indoors | Medium | Medium | Allow manual area selection fallback |
| Supabase free tier limits | Low | Medium | Monitor usage; upgrade to Pro if needed |
| Trust issues (damage/theft) | Low | High | Rental agreement + ratings + reports |
| App store rejection | Low | Medium | Follow all store guidelines from day 1 |
| Feature creep | High | High | Strict MVP scope; say no to nice-to-haves |
