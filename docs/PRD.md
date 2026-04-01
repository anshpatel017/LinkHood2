# RentNear — Product Requirements Document (PRD)

**Version:** 1.0  
**Status:** MVP  
**Platform:** iOS + Android (Flutter)  
**Target Launch:** 4 weeks from kick-off

---

## 1. Product Vision

**RentNear** is a hyperlocal peer-to-peer rental platform that allows people in the same residential area to rent useful items from each other for short durations — instead of buying items they will rarely use.

**One-line pitch:**  
*"Rent what you need from people near you — cheaper, faster, and smarter."*

**Long-term vision:**  
A structured hyperlocal asset utilization network — turning idle household items into community-shared resources, with data that maps neighborhood demand and supply at scale.

---

## 2. Problem Statement

People frequently need items for just 1–7 days (a power drill, a ladder, a vacuum cleaner) but:

- Buying is wasteful and expensive for one-time use.
- Rental shops are inconvenient and far away.
- Asking neighbors directly causes social awkwardness.
- WhatsApp groups are noisy, unstructured, and have no availability tracking.

**RentNear solves this by creating a structured, searchable, trust-based rental layer inside neighborhoods.**

---

## 3. Target Users

### Primary User — Lender
- Resident in an apartment society or gated community
- Owns tools or utility items used rarely
- Wants to earn passive income from idle items
- Values trust and clear agreements

### Primary User — Borrower
- Resident in the same area
- Needs an item urgently for 1–7 days
- Wants a faster and less awkward option than asking around
- New residents who don't know neighbors yet

### MVP Target Geography
- One residential society or apartment complex
- Single city pilot
- Expand after validation

---

## 4. MVP Category Focus

**Primary:** Tools & Utility Equipment

Examples:
- Power drill
- Ladder
- Extension cable (heavy-duty)
- Vacuum cleaner
- Pressure washer
- Gardening tools
- Projector

**Excluded from MVP (added post-validation):**
- Clothes
- Electronics (laptop, phone)
- Vehicles
- Party items

---

## 5. Core Features

### 5.1 Authentication
- Email + OTP login via Supabase Auth
- Google Sign-In (optional, Phase 2)
- Phone verification for trust badge
- Session persistence with secure token storage

### 5.2 Onboarding — Inventory Checklist
- On first login, show category checklist: "What do you own?"
- Examples: Power drill, Ladder, Vacuum cleaner, Projector, Extension cable
- Selected items are saved to `user_inventory` table
- Used for smart geo-broadcast matching

### 5.3 Home Feed
- Location-based item cards (within 500m default)
- Search bar (item name / keyword)
- Category filter tabs
- Distance shown on each card
- "Available Today" quick filter toggle
- Offline-capable (Hive cache)

### 5.4 Item Listing
- Fields: Photo, Title, Category, Price per day, Short description, Availability toggle
- Listing time target: under 2 minutes
- Owner can set "Instant Available" badge
- Earnings estimate shown: "You could earn ₹X/month at this price"

### 5.5 Item Detail Page
- Large image
- Price per day
- Description
- Owner profile and rating
- Availability calendar
- Rental duration selector
- Cost estimate (auto-calculated)
- "Request to Rent" CTA button

### 5.6 Rental Request Flow
- Borrower selects dates
- Sees cost breakdown (days × price/day)
- Confirms request
- Lender receives push notification
- Lender accepts or rejects
- Both see status update in My Rentals

### 5.7 Geo-Broadcast Request
- Borrower posts: "I need a [category] for [duration] — budget ₹X"
- App sends FCM notification to users within 500m who own that category
- Daily limit: 3 requests per user
- Lender can respond by sharing their existing listing or confirming availability

### 5.8 My Rentals Dashboard
- Tabs: Renting | Lending
- Status labels: Pending, Accepted, Active, Completed, Cancelled
- Each card shows: item, lender/borrower name, dates, cost

### 5.9 Profile
- Name, profile photo
- Star rating (average)
- Verification badges (phone, email)
- Listed items
- Rental history count
- Estimated monthly earnings

### 5.10 Ratings & Reviews
- Post-rental prompt for both parties
- 1–5 star rating
- Optional short text review
- Rating visible on profile and item cards

### 5.11 Rental Agreement Display
- Auto-shown before confirming request
- Includes: duration, price, deposit note, return date, damage responsibility, late return clause
- User must tap "I Agree" to proceed

### 5.12 Push Notifications (FCM)
- New rental request received
- Request accepted / rejected
- Rental starting tomorrow (reminder)
- Return due today
- Geo-broadcast request nearby
- Rating reminder after completion

### 5.13 Report Issue
- Button visible on all Active rental screens
- Fields: Issue type, description, optional photo
- Stored in `reports` table for manual review

---

## 6. MVP Screen List

| Screen | Purpose |
|---|---|
| Splash | Branding and app load |
| Login / Signup | Email + OTP authentication |
| Onboarding — Inventory | What items do you own checklist |
| Home Feed | Search and browse nearby listings |
| Item Detail | Full listing view with booking CTA |
| Request Flow | Date selection, cost estimate, confirm |
| My Rentals | Renting and Lending tabs with status |
| Add / Edit Listing | Create or update a listing |
| Profile | User info, rating, history |
| Notifications | In-app notification list |
| Post Request | Geo-broadcast request form |
| Settings | Account, location, notifications |

---

## 7. Must-Have vs Nice-to-Have

### Must-Have (MVP — 4 Weeks)
- User auth (email + OTP)
- Inventory onboarding
- Listing creation
- Location-based home feed
- Rental request and acceptance flow
- Geo-broadcast request with FCM
- My Rentals dashboard
- Ratings after rental
- Rental agreement display
- Report issue button
- Offline listing cache
- Firebase Crashlytics

### Nice-to-Have (Post-MVP)
- In-app payments (Razorpay)
- In-app chat
- Dark mode
- Google Sign-In
- Referral and invite system
- Wallet and earnings payout
- Multi-language support
- Admin moderation dashboard
- AI-based pricing suggestions
- Delivery coordination

---

## 8. 4-Week Milestone Plan

### Week 1 — Foundation
- Flutter project setup with Clean Architecture
- Supabase project created — tables, RLS, Auth configured
- Supabase schema: `users`, `listings`, `rentals`, `requests`
- Firebase initialized (Analytics, Crashlytics, FCM)
- Auth screens: Login, OTP, Onboarding inventory checklist
- GoRouter navigation skeleton
- Core theme, constants, shared widgets

### Week 2 — Core Features
- Home feed with location-based listing cards
- Add Listing screen (form + photo upload to Supabase Storage)
- Item Detail page
- Rental Request flow (date selection → confirm → notify)
- Lender accept/reject screen
- My Rentals dashboard (both tabs, status display)
- Offline cache: Hive for home feed
- Basic unit tests for domain use cases

### Week 3 — Production Hardening
- Geo-broadcast request feature + Edge Function
- FCM integration (all notification types)
- Rating and review flow
- Rental agreement screen
- Report issue flow
- Row Level Security audit on all tables
- Performance: const widgets, image optimization, lazy loading
- Crashlytics integration and manual crash testing
- Edge case handling (no listings, empty state, network error)

### Week 4 — Store Readiness
- App icon (1024×1024), splash screen
- App versioning and build numbers
- Production signing (Android keystore, iOS certificates)
- Release build testing on physical devices (iOS + Android)
- Privacy Policy page + URL
- App Store and Play Store listing assets (screenshots, description)
- Beta testing: TestFlight (iOS) + Internal Testing (Android)
- Bug fixes from beta feedback
- Final submission to both stores

---

## 9. Non-Functional Requirements

| Requirement | Target |
|---|---|
| App launch time | Under 2 seconds on mid-range device |
| Home feed load | Under 1.5 seconds on 4G |
| Listing creation time | Under 2 minutes for new user |
| Crash rate | Below 0.5% of sessions |
| Accessibility | Semantic labels, contrast ratio AA, scalable text |
| Offline capability | Home feed viewable without internet |
| API response time | Under 800ms for all primary queries |

---

## 10. Trust and Safety Requirements

- Phone or email verification required before listing or renting
- Rental agreement acceptance mandatory before booking
- Damage responsibility clause displayed clearly
- Report issue available on every active rental
- Platform acts as mediator only — no insurance in MVP
- Ratings system active from day one
- Verified Neighbor badge visible on profiles with 3+ completed rentals

---

## 11. Success Criteria for MVP Validation

The MVP is considered validated when, within the first pilot community:

- 30 or more items are actively listed
- 15 or more rentals are completed successfully
- Average user rating is 4.0 or above
- No critical trust incident (theft, dispute, unresolved damage)
- At least 5 users have completed more than one rental (repeat usage)

If these are not met within 60 days of launch, a pivot or category change is warranted.

---

## 12. Out of Scope (MVP)

- Multi-city or multi-society support
- Payment processing inside app
- Delivery or logistics coordination
- Insurance or damage guarantee
- Subscription plans
- Business or commercial listings
- Any feature requiring more than 2 weeks of isolated development
