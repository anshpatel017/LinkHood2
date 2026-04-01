# RentNear — User Stories & Acceptance Criteria

---

## Epic 1: Authentication & Onboarding

### US-1.1 — Email + OTP Signup
**As a** new user,  
**I want to** sign up using my email and receive an OTP,  
**So that** I can verify my identity and access the platform.

**Acceptance Criteria:**
- [ ] User enters a valid email address
- [ ] Supabase Auth sends a 6-digit OTP to the email
- [ ] User enters OTP and is authenticated
- [ ] Auth token is persisted securely via `flutter_secure_storage`
- [ ] Invalid OTP shows inline error; max 3 retries
- [ ] Session is restored on app relaunch without re-login

### US-1.2 — Login (Returning User)
**As a** returning user,  
**I want to** log back in with my email + OTP,  
**So that** I can resume using the app without re-registering.

**Acceptance Criteria:**
- [ ] Email field pre-fills if user logged in before
- [ ] OTP is sent and verified as in US-1.1
- [ ] User is navigated to Home Feed on success

### US-1.3 — Inventory Onboarding
**As a** first-time user,  
**I want to** select items I own from a checklist,  
**So that** the app can match me with nearby borrowers.

**Acceptance Criteria:**
- [ ] Checklist screen shown after first successful login only
- [ ] Categories displayed: Power drill, Ladder, Vacuum cleaner, Projector, Extension cable, Gardening tools, Pressure washer
- [ ] Selected items saved to `user_inventory` table
- [ ] User can skip and fill later via Profile
- [ ] Minimum 0 items required (skip allowed)

---

## Epic 2: Home Feed & Discovery

### US-2.1 — Browse Nearby Listings
**As a** borrower,  
**I want to** see available items near me on the home feed,  
**So that** I can find things I need to rent.

**Acceptance Criteria:**
- [ ] Home feed loads listings within 500m of user's GPS location
- [ ] Each card shows: item photo, title, price/day, distance, owner rating
- [ ] Feed loads in < 1.5 seconds on 4G
- [ ] "Available Today" badge shown on instant-availability items
- [ ] Empty state displayed if no listings are found nearby

### US-2.2 — Search Items
**As a** borrower,  
**I want to** search for items by keyword,  
**So that** I can quickly find exactly what I need.

**Acceptance Criteria:**
- [ ] Search bar is accessible from home feed
- [ ] Results filter listings by title or description match
- [ ] Search results respect geo-radius filter
- [ ] No results → show "No items found" with a prompt to post a geo-broadcast request

### US-2.3 — Filter by Category
**As a** borrower,  
**I want to** filter listings by category,  
**So that** I can narrow down to relevant items.

**Acceptance Criteria:**
- [ ] Horizontal category filter tabs shown below search bar
- [ ] Tapping a category filters the feed immediately
- [ ] "All" tab shows unfiltered results
- [ ] Active filter tab is visually highlighted

### US-2.4 — Offline Home Feed
**As a** user without internet,  
**I want to** view previously loaded listings,  
**So that** I can browse items even offline.

**Acceptance Criteria:**
- [ ] Last-fetched listings are cached in Hive
- [ ] Offline feed displays cache with an "Offline mode" banner
- [ ] On reconnect, feed auto-refreshes with live data

---

## Epic 3: Item Listing Management

### US-3.1 — Create a Listing
**As a** lender,  
**I want to** list an item for rent,  
**So that** neighbors can find and rent it.

**Acceptance Criteria:**
- [ ] Form fields: Photo (required), Title (required), Category (required), Price/day (required), Description (optional), Availability toggle
- [ ] Photo uploaded to Supabase Storage
- [ ] Location auto-set from user's GPS
- [ ] Item appears on home feed within 5 seconds of creation
- [ ] Listing creation completes in under 2 minutes
- [ ] Earnings estimate shown: "You could earn ₹X/month"

### US-3.2 — Edit / Toggle Listing
**As a** lender,  
**I want to** edit my listing or toggle its availability,  
**So that** I can keep my items up-to-date.

**Acceptance Criteria:**
- [ ] Edit button visible only to listing owner
- [ ] All fields are editable
- [ ] Toggling availability immediately hides/shows item on home feed
- [ ] Changes saved to Supabase with `updated_at` timestamp

### US-3.3 — Delete Listing
**As a** lender,  
**I want to** delete my listing,  
**So that** I can remove items I no longer want to rent out.

**Acceptance Criteria:**
- [ ] Confirmation dialog before deletion
- [ ] Only owner can delete
- [ ] Listing removed from feed immediately
- [ ] Active rentals for this item are NOT auto-cancelled (prevent data loss)

---

## Epic 4: Rental Request Flow

### US-4.1 — Request to Rent an Item
**As a** borrower,  
**I want to** select dates and request to rent an item,  
**So that** I can initiate a rental.

**Acceptance Criteria:**
- [ ] Date picker allows selecting start and end date
- [ ] Cost breakdown shown: total_days × price_per_day
- [ ] Rental agreement displayed before confirmation
- [ ] User must tap "I Agree" to proceed
- [ ] Request creates a `rentals` row with status = `pending`
- [ ] Borrower cannot request their own listing

### US-4.2 — Accept or Reject a Rental Request
**As a** lender,  
**I want to** accept or reject incoming rental requests,  
**So that** I can control who rents my items.

**Acceptance Criteria:**
- [ ] Push notification received on new request
- [ ] Request details shown: borrower name, rating, dates, total cost
- [ ] Accept → status changes to `accepted`; borrower notified
- [ ] Reject → status changes to `cancelled`; borrower notified
- [ ] Lender can only act on requests for their own listings

### US-4.3 — Track Rental Status
**As a** borrower or lender,  
**I want to** see the real-time status of my rentals,  
**So that** I always know where things stand.

**Acceptance Criteria:**
- [ ] My Rentals dashboard has two tabs: Renting | Lending
- [ ] Each rental card: item, counterparty name, dates, cost, status
- [ ] Status labels: Pending, Accepted, Active, Completed, Cancelled
- [ ] Realtime updates via Supabase Realtime (WebSocket subscription)

---

## Epic 5: Geo-Broadcast Requests

### US-5.1 — Post a Geo-Broadcast Request
**As a** borrower,  
**I want to** broadcast a request for an item I need,  
**So that** nearby lenders who own it get notified.

**Acceptance Criteria:**
- [ ] Form fields: Category (required), Duration (required), Budget/day (optional), Description (optional)
- [ ] Request saved to `requests` table with user's location
- [ ] Supabase Edge Function triggered to find matching users within 500m
- [ ] FCM notification sent to matching inventory owners
- [ ] Rate limit: max 3 requests/day per user
- [ ] Request auto-expires after 48 hours

### US-5.2 — Respond to a Geo-Broadcast
**As a** lender,  
**I want to** respond to a nearby borrower's request,  
**So that** I can offer my item for rent.

**Acceptance Criteria:**
- [ ] Push notification links to the request detail screen
- [ ] Lender can share their existing listing in response
- [ ] Request status changes to `fulfilled` once a rental is initiated

---

## Epic 6: Ratings & Reviews

### US-6.1 — Rate After Rental
**As a** user who completed a rental,  
**I want to** rate and review the other party,  
**So that** the community maintains trust.

**Acceptance Criteria:**
- [ ] Rating prompt shown after rental status → `completed`
- [ ] 1–5 star selection (required)
- [ ] Optional short text review
- [ ] Rating saved to `ratings` table
- [ ] User's `rating_avg` and `rating_count` updated
- [ ] One rating per party per rental (enforced by unique constraint)

---

## Epic 7: User Profile

### US-7.1 — View My Profile
**As a** user,  
**I want to** see my profile with stats,  
**So that** I can track my activity and reputation.

**Acceptance Criteria:**
- [ ] Shows: name, photo, star rating, verification badges
- [ ] Lists: owned items, rental history count, estimated monthly earnings
- [ ] Edit profile button for name and photo

### US-7.2 — View Other User's Profile
**As a** borrower or lender,  
**I want to** view the other party's profile,  
**So that** I can assess trustworthiness.

**Acceptance Criteria:**
- [ ] Accessible from item detail and rental card
- [ ] Shows: name, photo, rating, verification badges, listed items
- [ ] "Verified Neighbor" badge for users with 3+ completed rentals

---

## Epic 8: Notifications

### US-8.1 — Receive Push Notifications
**As a** user,  
**I want to** get push notifications for important events,  
**So that** I don't miss rental activity.

**Acceptance Criteria:**
- [ ] Notification received for: new request, accept/reject, reminder, return due, geo-broadcast, rating prompt
- [ ] Tapping notification deep-links to relevant screen
- [ ] FCM token stored in `users.fcm_token` and rotated on session refresh

### US-8.2 — View In-App Notifications
**As a** user,  
**I want to** see a list of all my notifications,  
**So that** I can review past activity.

**Acceptance Criteria:**
- [ ] Notification list screen shows title, body, time, read/unread status
- [ ] Tapping marks as read
- [ ] Unread count badge shown on nav bar icon

---

## Epic 9: Safety & Reporting

### US-9.1 — Report an Issue
**As a** renter or lender in an active rental,  
**I want to** report a problem,  
**So that** the platform can assist.

**Acceptance Criteria:**
- [ ] Report button visible on all active rental screens
- [ ] Form: issue type (dropdown), description (text), optional photo
- [ ] Report saved to `reports` table with status = `open`
- [ ] Confirmation shown to user after submission
