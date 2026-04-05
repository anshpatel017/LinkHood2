# LinkHood — Complete UI/UX Specification

> **App Name:** LinkHood (internally also called "RentNear")
> **Tagline:** "Rent what you need from neighbors"
> **Platform:** Flutter (Mobile-first, also runs on Web)
> **Total Screens:** 18 screens across 6 modules

---

## 🔐 Module 1: Authentication (5 screens)

### 1.1 Login Page (`/login`)
**Purpose:** Entry point — tabs for Sign In and Sign Up

**Layout:**
- Brand section at top: circular icon container with handshake icon + "LinkHood" title + tagline
- Tab bar with 2 tabs: **Sign In** | **Sign Up**

**Sign In Tab:**
- Email Address field (with mail icon prefix)
- Password field (with lock icon prefix + eye toggle for show/hide)
- "Sign In" button (primary, full-width)
- "Don't have an account? **Sign Up**" link at bottom

**Sign Up Tab:**
- Info banner with icon: "Create your account to start renting from neighbors!"
- Full Name field (person icon)
- Email Address field (mail icon)
- Password field (min 6 chars, lock icon + eye toggle)
- "Create Account" button (primary, full-width, with person-add icon)
- "Already have an account? **Sign In**" link at bottom

---

### 1.2 OTP Verification Page (`/otp`)
**Purpose:** Verify email with a 6-digit OTP code

- Header text: "We sent a code to {email}"
- 6 individual digit boxes (auto-focus, auto-advance)
- "Verify" button
- "Resend Code" link with cooldown timer (60s countdown)
- Back arrow to return to login

---

### 1.3 Password Setup Page (`/setup-password`)
**Purpose:** New users set their password after OTP verification

- Header: "Set your password"
- New Password field (with strength requirements)
- Confirm Password field
- "Set Password" button

---

### 1.4 Onboarding — Profile Setup (`/onboarding`)
**Purpose:** First-time user sets up their profile

- Full Name field
- Phone Number field
- Area/Location selector (text field for area name)
- Avatar upload (camera icon, circular preview)
- "Continue" button → navigates to inventory

---

### 1.5 Onboarding — Inventory Page (`/onboarding/inventory`)
**Purpose:** User selects categories of items they own (helps match them to neighbors' requests)

- Header: "What do you own?"
- Grid/list of 6 categories with checkboxes:
  - 🔧 Power Tools (drill, jigsaw, sander)
  - 🧹 Cleaning (vacuum, pressure washer, steam mop)
  - 🌱 Garden & Outdoor (gardening tools, leaf blower, lawn mower)
  - 🔌 Heavy-Duty Electrical (extension cable, generator)
  - 📽️ AV Equipment (projector, speakers, microphone)
  - 🪜 Access Equipment (ladder, step stool)
- Each category shows example items underneath
- "Finish Setup" button

---

## 🏠 Module 2: Home / Discovery (3 screens)

### 2.1 Home Page (`/home`)
**Purpose:** Main feed showing nearby items and requests

**Header:** AppBar with "RentNear" title + "+" button (Add Listing)

**Body (scrollable):**
1. **Search bar** — "Search items near you..." with search icon + clear button
2. **Category filter chips** — Horizontal scroll: All, Power Tools, Cleaning, Garden, Electrical, AV Equipment, Access Equipment
3. **Section: "Nearby Items"** — Horizontal scrolling list of item cards (180px wide, 280px tall)
   - Each card shows: image, title, price/day, owner info
4. **Section: "Nearby Requests"** — Horizontal scrolling list of request cards (280px wide)
   - Each card shows: category badge, "Needed" badge, item name, description, budget/day, duration

---

### 2.2 Item Detail Page (`/home/item/:id`)
**Purpose:** Full details of a listing

**Layout:**
- **Image slider** at top (280px height, swipeable if multiple images)
- **Title** (large text)
- **Price:** "₹XX/day" in accent color
- **Owner card:** Avatar + name + star rating
- **Description** section
- **Security Deposit** section (if applicable): "Refundable deposit of ₹XX required"
- **Report button** (flag icon in AppBar) — opens dialog: reason text field + submit
- **Bottom sticky bar:** "Request to Rent" or "Instant Rent" button

---

### 2.3 Rental Request Page (`/home/item/:id/request`)
**Purpose:** User requests to rent an item with date selection

**Layout:**
- **Item summary card:** thumbnail + title + price/day
- **Date range picker:** tap to open calendar, shows "DD/MM/YYYY — DD/MM/YYYY (X days)"
- **Cost breakdown:** Duration (X days) + Estimated Total (₹XX)
- **Pickup Note** (optional text field): "e.g. I can pick up after 5pm"
- **"Send Request" button** (full-width, with send icon)

---

## 📦 Module 3: Listings (3 screens)

### 3.1 Add Listing Page (`/add-listing`)
**Purpose:** Create a new item listing for rent

**Form fields:**
1. **Photos** (max 5) — Horizontal scroll of image thumbnails with add button + delete (X) on each
2. **Title** — "e.g. Bosch Power Drill"
3. **Category dropdown** — 6 categories with emoji labels
4. **Price per day (₹)** — Number input with rupee icon + earnings estimate below ("Earn ₹XX/month")
5. **Description** (optional) — Multi-line text
6. **Deposit amount (₹)** (optional) — Number input with security icon
7. **"Available Today" toggle** — Switch to mark as instantly available
8. **"Create Listing" button**

---

### 3.2 My Listings Page (`/profile/my-listings`)
**Purpose:** View and manage all your listings

- List of your listing cards
- Each card shows: image, title, price, status (active/inactive)
- Options to edit/delete (if implemented)

---

### 3.3 Request Detail Page (`/home/request/:id`)
**Purpose:** View full details of a neighbor's request + option to offer your item

- Request details: item name, category, description, budget, duration, dates
- Requester info: name, avatar, rating
- Action to offer help / respond

---

## 📋 Module 4: Rentals (1 screen, 2 tabs)

### 4.1 My Rentals Page (`/rentals`)
**Purpose:** Track items you've borrowed and lent

**Tabs:**
- **"As Borrower"** — Items you've rented from others
- **"As Lender"** — Items others have rented from you

**Each rental card shows:**
- Item image + title
- Rental dates (start → end)
- Status badge (pending, active, completed, cancelled)
- Other party's name
- Total cost

**Empty states:**
- Borrower: "No rentals yet — Items you rent from neighbors will show up here."
- Lender: "No items lent out — When someone rents your items, they appear here."

---

## 📢 Module 5: Requests (2 screens)

### 5.1 Post Request Page (`/request`)
**Purpose:** Broadcast a request to nearby neighbors

**Header subtitle:** "Need something? Ask your neighbors!"

**Form fields:**
1. **Category dropdown** — "What do you need?"
2. **Item Name** — "e.g. Power Drill, Ladder, Tent"
3. **Description** — "e.g. Need a power drill for hanging shelves"
4. **Budget per day (₹)** — Optional
5. **Rental Period** (date range):
   - "From Date" and "To Date" tiles with calendar icons
   - Auto-computed duration badge: "Duration: X days" (green accent)
6. **Info banner:** "This will notify neighbors within 500m who own items in this category."
7. **"Broadcast Request" button** (with send icon)

---

### 5.2 My Requests Page (`/profile/my-requests`)
**Purpose:** View all requests you've posted + incoming offers

- List of your posted requests
- Each shows: item name, category, status, number of offers received
- Ability to view offers and accept/decline

---

## 👤 Module 6: Profile & Settings (4 screens)

### 6.1 Profile Page (`/profile`)
**Purpose:** User's profile overview

**Layout:**
- **Avatar** (large, circular) — with edit icon in AppBar
- **Name** (large text)
- **Email** (secondary text)
- **Star rating** with count (e.g. ★★★★☆ 4.2 (15))
- **Stats row:** Listings | Rented Out | Borrowed (3 columns with dividers)
- **Menu items:**
  - 📥 My Requests
  - 📦 My Listings
  - ✅ My Inventory
  - 🕐 Rental History
  - ─── divider ───
  - ⚙️ Settings
  - ❓ Help & Support
  - 🚪 Sign Out (red/destructive)

---

### 6.2 Edit Profile Page (`/profile/edit`)
**Purpose:** Edit profile information

- Avatar upload/change
- Full Name field
- Phone field
- Area/Location field
- "Save Changes" button

---

### 6.3 Settings Page (`/profile/settings`)
**Purpose:** App preferences

**Sections:**
- **Preferences:**
  - Push Notifications toggle
  - Email Notifications toggle
  - Location Services toggle
- **Support:**
  - Help Center
  - Terms of Service
  - Privacy Policy
- **Footer:** "RentNear v1.0.0"

---

### 6.4 Notifications Page (`/notifications`)
**Purpose:** All alerts and updates

- AppBar with "Mark all read" button
- List of notifications (rental requests, approvals, broadcasts)
- Empty state: "No notifications — You'll receive alerts for rental requests, approvals, and neighbor broadcasts."

---

## 🧭 Navigation Structure

### Bottom Navigation Bar (5 tabs)
| Tab | Icon | Label | Route |
|-----|------|-------|-------|
| 1 | 🏠 Home | Home | `/home` |
| 2 | 📋 Receipt | Rentals | `/rentals` |
| 3 | ➕ Add Circle | Request | `/request` |
| 4 | 🔔 Bell | Alerts | `/notifications` |
| 5 | 👤 Person | Profile | `/profile` |

### Flow Diagram
```
Login → (OTP → Password Setup) → Onboarding Profile → Onboarding Inventory → Home
                                                                                 ↓
Home ─── Search/Filter ─── Item Detail ─── Request to Rent ─── My Rentals
  │                              │
  └── Nearby Requests ──── Request Detail
  │
  └── Add Listing (fab/button)

Bottom Nav: Home | Rentals | Post Request | Notifications | Profile
                                                              │
                                              Edit Profile / My Listings / 
                                              My Requests / Settings
```

---

## 🎨 Design System

### Colors
| Role | Usage |
|------|-------|
| Primary | Main brand color (purple/indigo) — buttons, links, active states |
| Accent | Secondary highlights, earnings estimates |
| Surface | Card backgrounds, input fields |
| Surface Variant | Subtle backgrounds (owner cards, info banners) |
| Error | Destructive actions (sign out, report) |
| Success | Positive states (duration badge, completed) |
| Warning | "Needed" badges on request cards |
| Info | Informational banners |

### Typography
- **H1:** App name/brand
- **H3:** Section titles, profile name
- **H4:** Sub-sections, prices
- **Body Medium:** Descriptions, regular text
- **Label Large:** Form labels, card titles
- **Caption:** Helper text, secondary info

### Components Used
- `AppButton` — Primary full-width button with icon + loading state
- `AppTextField` — Styled text field with label, hint, prefix/suffix icons
- `ListingCard` — Item card with image, title, price
- `RentalCard` — Rental status card with dates and cost
- `RatingStars` — Star display with optional count
- `EmptyStateWidget` — Empty state with icon, title, subtitle, optional action
- `FilterChip` — Category filter chips (horizontal scroll)

### Spacing
- Screen padding: 16-20px
- Vertical gaps between sections: 16-32px
- Card border radius: 12px
- Full/pill border radius for chips and badges

---

## 📱 Key User Flows

### Flow 1: New User Signup
`Open App → Login (Sign Up tab) → Enter name/email/password → Create Account → Sign In → Onboarding Profile → Onboarding Inventory → Home`

### Flow 2: Browse & Rent
`Home → Search/Filter → Tap Item → Item Detail → "Request to Rent" → Select dates → Send Request → Rentals tab`

### Flow 3: List an Item
`Home → "+" button → Add Listing → Fill form + photos → Create Listing → Home`

### Flow 4: Post a Request
`Bottom Nav "Request" → Fill form → Broadcast Request → Home (neighbors notified within 500m)`

### Flow 5: Manage Rentals
`Bottom Nav "Rentals" → "As Borrower" / "As Lender" tabs → View rental cards with status`
