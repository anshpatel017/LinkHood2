# RentNear — Development Phases

---

## Phase Overview

| Phase | Duration | Focus |
|---|---|---|
| **Phase 1** | Week 1 | Foundation & Auth |
| **Phase 2** | Week 2 | Core Features |
| **Phase 3** | Week 3 | Production Hardening |
| **Phase 4** | Week 4 | Store Readiness & Launch |

---

## Phase 1 — Foundation & Auth (Week 1)

### Goals
- Project scaffolding and architecture setup
- Backend schema deployed to Supabase
- Authentication flow working end-to-end
- Navigation skeleton with core theme

### Deliverables

| # | Task | Owner | Est. | Status |
|---|---|---|---|---|
| 1.1 | Create Flutter project with Clean Architecture scaffold | Dev | 0.5d | ⬜ |
| 1.2 | Set up `pubspec.yaml` with all MVP dependencies | Dev | 0.5d | ⬜ |
| 1.3 | Create Supabase project | Dev | 0.5d | ⬜ |
| 1.4 | Write and apply SQL migrations: `users`, `listings`, `rentals`, `requests`, `user_inventory`, `ratings`, `reports`, `notifications` | Dev | 1d | ⬜ |
| 1.5 | Apply RLS policies on all tables | Dev | 0.5d | ⬜ |
| 1.6 | Create SQL functions: `get_nearby_listings`, `get_nearby_inventory_users` | Dev | 0.5d | ⬜ |
| 1.7 | Initialize Firebase (Analytics, Crashlytics, FCM) | Dev | 0.5d | ⬜ |
| 1.8 | Implement Supabase Auth: Login, OTP, Session persistence | Dev | 1.5d | ⬜ |
| 1.9 | Build auth screens: LoginPage, OTPPage, SignupPage | Dev | 1d | ⬜ |
| 1.10 | Build Onboarding Inventory Checklist screen | Dev | 0.5d | ⬜ |
| 1.11 | GoRouter navigation skeleton (all routes defined) | Dev | 0.5d | ⬜ |
| 1.12 | Core theme: colors, typography, spacing, shared widgets | Dev | 0.5d | ⬜ |

### Exit Criteria
- [ ] User can sign up, receive OTP, verify, and log in
- [ ] Auth token persisted; session restored on relaunch
- [ ] Onboarding checklist saves to `user_inventory`
- [ ] All database tables created with RLS enabled
- [ ] Navigation between all placeholder screens works

---

## Phase 2 — Core Features (Week 2)

### Goals
- Home feed with location-based discovery
- Full listing CRUD
- Complete rental request and acceptance flow
- My Rentals dashboard with real-time updates

### Deliverables

| # | Task | Owner | Est. | Status |
|---|---|---|---|---|
| 2.1 | Implement location service (GPS access + permission handling) | Dev | 0.5d | ⬜ |
| 2.2 | Build Home Feed page with nearby listing cards | Dev | 1.5d | ⬜ |
| 2.3 | Category filter tabs and search bar | Dev | 0.5d | ⬜ |
| 2.4 | Add Listing screen (form + photo upload to Supabase Storage) | Dev | 1d | ⬜ |
| 2.5 | Edit Listing screen | Dev | 0.5d | ⬜ |
| 2.6 | Item Detail page (full info, owner card, availability) | Dev | 1d | ⬜ |
| 2.7 | Rental Request flow: date picker → cost breakdown → confirm | Dev | 1.5d | ⬜ |
| 2.8 | Lender accept/reject screen | Dev | 0.5d | ⬜ |
| 2.9 | My Rentals dashboard: Renting + Lending tabs, status display | Dev | 1.5d | ⬜ |
| 2.10 | Supabase Realtime subscription for rental status updates | Dev | 0.5d | ⬜ |
| 2.11 | Offline cache: Hive for home feed listings | Dev | 0.5d | ⬜ |
| 2.12 | Basic unit tests for domain use cases | Dev | 0.5d | ⬜ |

### Exit Criteria
- [ ] Home feed loads listings within 500m of user's location
- [ ] User can create a listing with photo in under 2 minutes
- [ ] Borrower can request an item; lender can accept/reject
- [ ] My Rentals shows correct status for both parties
- [ ] Offline feed displays cached listings

---

## Phase 3 — Production Hardening (Week 3)

### Goals
- Geo-broadcast request feature live
- All notification types working
- Ratings and reporting flows complete
- Security audit and performance optimization

### Deliverables

| # | Task | Owner | Est. | Status |
|---|---|---|---|---|
| 3.1 | Build Post Request screen (geo-broadcast form) | Dev | 0.5d | ⬜ |
| 3.2 | Deploy Supabase Edge Function: `broadcast_request` | Dev | 1d | ⬜ |
| 3.3 | FCM integration: all notification types wired | Dev | 1.5d | ⬜ |
| 3.4 | In-app notification list screen | Dev | 0.5d | ⬜ |
| 3.5 | Notification deep-linking via GoRouter | Dev | 0.5d | ⬜ |
| 3.6 | Rating & review flow (post-rental prompt) | Dev | 1d | ⬜ |
| 3.7 | Rating trigger to update `users.rating_avg` | Dev | 0.5d | ⬜ |
| 3.8 | Rental Agreement display screen | Dev | 0.5d | ⬜ |
| 3.9 | Report Issue flow | Dev | 0.5d | ⬜ |
| 3.10 | User Profile screen (stats, badges, listed items) | Dev | 0.5d | ⬜ |
| 3.11 | RLS audit: verify all policies on all tables | Dev | 0.5d | ⬜ |
| 3.12 | Performance: const widgets, image optimization, lazy loading | Dev | 0.5d | ⬜ |
| 3.13 | Crashlytics integration and manual crash tests | Dev | 0.5d | ⬜ |
| 3.14 | Edge case handling: empty states, no internet, error screens | Dev | 0.5d | ⬜ |

### Exit Criteria
- [ ] Geo-broadcast sends notifications to matching nearby users
- [ ] All 8 notification types trigger correctly
- [ ] Post-rental rating updates user's average
- [ ] "Verified Neighbor" badge appears for eligible users
- [ ] Zero RLS policy gaps identified in audit
- [ ] All edge cases have graceful handling

---

## Phase 4 — Store Readiness & Launch (Week 4)

### Goals
- App polished and production-ready
- Store listing assets prepared
- Beta testing complete
- Submitted to App Store and Play Store

### Deliverables

| # | Task | Owner | Est. | Status |
|---|---|---|---|---|
| 4.1 | Design app icon (1024×1024 PNG) | Design/Dev | 0.5d | ⬜ |
| 4.2 | Create splash screen (Android + iOS) | Dev | 0.5d | ⬜ |
| 4.3 | Set version name and build number in `pubspec.yaml` | Dev | 0.25d | ⬜ |
| 4.4 | Android: Generate release keystore + `key.properties` | Dev | 0.25d | ⬜ |
| 4.5 | iOS: Create App ID, Distribution Certificate, Provisioning Profile | Dev | 0.5d | ⬜ |
| 4.6 | Release build: `flutter build appbundle --release` | Dev | 0.25d | ⬜ |
| 4.7 | Release build: `flutter build ipa --release` | Dev | 0.25d | ⬜ |
| 4.8 | Test release builds on physical devices (both platforms) | Dev/QA | 1d | ⬜ |
| 4.9 | Prepare Privacy Policy page + URL | Dev | 0.5d | ⬜ |
| 4.10 | Play Store listing: screenshots, description, category | Dev | 0.5d | ⬜ |
| 4.11 | App Store listing: screenshots, description, category | Dev | 0.5d | ⬜ |
| 4.12 | TestFlight beta (iOS) + Internal Testing (Android) | Dev | 0.5d | ⬜ |
| 4.13 | Collect and fix bugs from beta feedback | Dev | 1d | ⬜ |
| 4.14 | Final submission to both stores | Dev | 0.25d | ⬜ |
| 4.15 | GitHub Actions CI/CD pipeline configured and tested | Dev | 0.5d | ⬜ |

### Exit Criteria
- [ ] App passes all manual QA on physical devices
- [ ] Zero critical/high bugs open
- [ ] Beta testers confirm core flows work
- [ ] Both store submissions accepted
- [ ] CI/CD pipeline runs analyze + test + build on every push

---

## Milestone Summary

```
Week 1: Foundation & Auth
  ✓ Project scaffolded
  ✓ Supabase schema deployed
  ✓ Auth working end-to-end
  ✓ Onboarding complete

Week 2: Core Features
  ✓ Home feed with geo-filter
  ✓ Listing CRUD with photos
  ✓ Rental request & acceptance
  ✓ My Rentals dashboard

Week 3: Production Hardening
  ✓ Geo-broadcast requests + FCM
  ✓ Ratings & reviews
  ✓ Security audit passed
  ✓ Edge cases handled

Week 4: Store Readiness
  ✓ Release builds tested
  ✓ Store assets prepared
  ✓ Beta testing passed
  ✓ Submitted to stores
```

---

## Post-MVP Roadmap (Future Phases)

| Phase | Focus | Est. Timeline |
|---|---|---|
| Phase 5 | In-app payments (Razorpay) | 2 weeks |
| Phase 6 | In-app chat + media sharing | 2 weeks |
| Phase 7 | Dark mode + UI polish | 1 week |
| Phase 8 | Referral & invite system | 1 week |
| Phase 9 | Multi-society expansion | 2 weeks |
| Phase 10 | Admin dashboard | 2 weeks |
| Phase 11 | AI pricing suggestions | 2 weeks |
