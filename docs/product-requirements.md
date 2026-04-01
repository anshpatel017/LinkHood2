# RentNear — Product Requirements

**Version:** 1.0 · **Status:** MVP · **Platform:** iOS + Android (Flutter) · **Target Launch:** 4 weeks from kick-off

---

## 1. Product Vision

**RentNear** is a hyperlocal peer-to-peer rental platform that allows people in the same residential area to rent useful items from each other for short durations — instead of buying items they will rarely use.

**One-line pitch:** *"Rent what you need from people near you — cheaper, faster, and smarter."*

**Long-term vision:** A structured hyperlocal asset utilization network — turning idle household items into community-shared resources, with data that maps neighborhood demand and supply at scale.

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
- New residents who don't yet know their neighbors

### MVP Target Geography
- One residential society or apartment complex
- Single city pilot → expand after validation

---

## 4. MVP Category Focus

**Primary:** Tools & Utility Equipment

| Category | Example Items |
|---|---|
| Power Tools | Power drill, jigsaw |
| Access Equipment | Ladder, step stool |
| Cleaning Equipment | Vacuum cleaner, pressure washer |
| Garden & Outdoor | Gardening tools, leaf blower |
| Heavy-Duty Electrical | Extension cable (heavy-duty) |
| AV Equipment | Projector, speakers |

**Excluded from MVP:** Clothes, electronics (laptop/phone), vehicles, party items.

---

## 5. Core Feature Requirements

### 5.1 Authentication
| Requirement | Detail |
|---|---|
| Primary Auth | Email + OTP via Supabase Auth |
| Session Persistence | Secure token storage via `flutter_secure_storage` |
| Phone Verification | Required for trust badge on profile |
| Google Sign-In | Post-MVP (Phase 2) |

### 5.2 Onboarding — Inventory Checklist
- On first login, present a category checklist: "What do you own?"
- Selected items saved to `user_inventory` table
- Used for smart geo-broadcast matching later

### 5.3 Home Feed
- Location-based item cards within 500m (default radius)
- Search bar (item name / keyword)
- Category filter tabs
- Distance shown on each card
- "Available Today" quick filter toggle
- Offline-capable (Hive cache)

### 5.4 Item Listing Creation
- **Fields:** Photo, Title, Category, Price/day, Short description, Availability toggle
- Listing completion target: under 2 minutes
- Owner can set "Instant Available" badge
- Earnings estimate: "You could earn ₹X/month at this price"

### 5.5 Item Detail Page
- Large image, price/day, full description
- Owner profile card with rating
- Availability calendar
- Rental duration selector with auto-calculated cost estimate
- "Request to Rent" CTA button

### 5.6 Rental Request & Acceptance Flow
1. Borrower selects dates → sees cost breakdown (days × price/day)
2. Borrower confirms request
3. Lender receives push notification
4. Lender accepts or rejects
5. Both parties see status update in My Rentals

### 5.7 Geo-Broadcast Request
- Borrower posts: "I need a [category] for [duration] — budget ₹X"
- FCM notification sent to users within 500m who own that category
- **Rate limit:** 3 requests/day per user
- Lender can respond by sharing listing or confirming availability

### 5.8 My Rentals Dashboard
- **Tabs:** Renting | Lending
- **Status labels:** Pending → Accepted → Active → Completed / Cancelled
- Each card: item name, counterparty name, dates, cost

### 5.9 User Profile
- Name, photo, star rating (average)
- Verification badges (phone, email)
- Listed items, rental history count
- Estimated monthly earnings

### 5.10 Ratings & Reviews
- Post-rental prompt for both parties
- 1–5 star rating + optional short text review
- Rating visible on profile and item cards

### 5.11 Rental Agreement Display
- Auto-shown before confirming rental request
- Covers: duration, price, deposit note, return date, damage responsibility, late return clause
- User must tap "I Agree" to proceed

### 5.12 Push Notifications (FCM)
| Event | Description |
|---|---|
| New rental request | Lender notified |
| Request accepted/rejected | Borrower notified |
| Rental starting tomorrow | Reminder to borrower |
| Return due today | Both parties |
| Geo-broadcast request nearby | Matching lenders |
| Rating reminder | After completion |

### 5.13 Report Issue
- Available on all active rental screens
- Fields: Issue type, description, optional photo
- Stored in `reports` table for manual review

---

## 6. MVP Screen List

| # | Screen | Purpose |
|---|---|---|
| 1 | Splash | Branding and app load |
| 2 | Login / Signup | Email + OTP authentication |
| 3 | Onboarding — Inventory | Item ownership checklist |
| 4 | Home Feed | Browse nearby listings |
| 5 | Item Detail | Full listing view + booking CTA |
| 6 | Request Flow | Date selection, cost estimate, confirm |
| 7 | My Rentals | Renting / Lending tabs with status |
| 8 | Add / Edit Listing | Create or update a listing |
| 9 | Profile | User info, rating, history |
| 10 | Notifications | In-app notification list |
| 11 | Post Request | Geo-broadcast request form |
| 12 | Settings | Account, location, notifications |

---

## 7. Non-Functional Requirements

| Requirement | Target |
|---|---|
| App launch time | < 2 seconds on mid-range device |
| Home feed load | < 1.5 seconds on 4G |
| Listing creation time | < 2 minutes for new user |
| Crash rate | < 0.5% of sessions |
| Accessibility | Semantic labels, contrast AA, scalable text |
| Offline capability | Home feed viewable without internet |
| API response time | < 800ms for all primary queries |

---

## 8. Trust & Safety Requirements

- Phone or email verification required before listing or renting
- Rental agreement acceptance mandatory before booking
- Damage responsibility clause displayed clearly
- Report issue available on every active rental
- Platform acts as mediator only — no insurance in MVP
- Ratings system active from day one
- **Verified Neighbor** badge: visible on profiles with 3+ completed rentals

---

## 9. Success Criteria

The MVP is validated when, within the first pilot community:

| Metric | Target |
|---|---|
| Active listings | 30+ |
| Completed rentals | 15+ |
| Average user rating | 4.0+ |
| Critical trust incidents | 0 |
| Repeat users (2+ rentals) | 5+ |
| Repeat rental rate | > 20% |
| Critical crashes | 0 |

**Pivot trigger:** If not met within 60 days of launch.

---

## 10. Out of Scope (MVP)

- Multi-city or multi-society support
- In-app payment processing
- Delivery or logistics coordination
- Insurance or damage guarantee
- Subscription plans
- Business or commercial listings
- In-app chat, dark mode, referral system
- AI pricing suggestions, admin dashboard
- Any feature requiring > 2 weeks of isolated development
