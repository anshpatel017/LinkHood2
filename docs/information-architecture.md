# RentNear — Information Architecture

---

## 1. Navigation Model

RentNear uses a **bottom navigation bar** as its primary navigation pattern with a persistent **GoRouter** routing hierarchy.

```
Bottom Navigation Bar
├── Home (Feed)
├── My Rentals
├── Post Request (+)
├── Notifications
└── Profile
```

---

## 2. Screen Map & Hierarchy

```
App Launch
│
├── Splash Screen
│   └── Auth Check
│       ├── Authenticated → Home Feed
│       └── Not Authenticated → Login
│
├── Auth Flow (unauthenticated)
│   ├── Login Screen (Email)
│   ├── OTP Verification Screen
│   ├── Signup Screen (Name, Photo)
│   └── Onboarding — Inventory Checklist (first login only)
│
├── Home Feed (Tab 1)
│   ├── Search Bar → Search Results
│   ├── Category Filter Tabs
│   ├── Listing Card → Item Detail Page
│   │   ├── Owner Profile (tap) → User Profile
│   │   ├── Availability Calendar
│   │   └── "Request to Rent" → Rental Request Flow
│   │       ├── Date Selection
│   │       ├── Cost Breakdown
│   │       ├── Rental Agreement Display
│   │       └── Confirmation
│   └── "Available Today" Toggle
│
├── My Rentals (Tab 2)
│   ├── Renting Tab
│   │   └── Rental Card → Rental Detail
│   │       ├── Status Timeline
│   │       ├── Report Issue
│   │       └── Rate & Review (post-completion)
│   └── Lending Tab
│       └── Rental Card → Rental Detail
│           ├── Accept / Reject (if pending)
│           ├── Status Timeline
│           ├── Report Issue
│           └── Rate & Review (post-completion)
│
├── Post Request (Tab 3 — FAB / Center Action)
│   └── Geo-Broadcast Request Form
│       ├── Category Selector
│       ├── Duration Input
│       ├── Budget Input (optional)
│       └── Submit → FCM Dispatch
│
├── Notifications (Tab 4)
│   └── Notification List
│       └── Tap → Deep-link to relevant screen
│
├── Profile (Tab 5)
│   ├── User Info (Name, Photo, Rating, Badges)
│   ├── My Listings
│   │   └── Listing Card → Item Detail
│   ├── Rental History Count
│   ├── Estimated Monthly Earnings
│   ├── Edit Profile
│   ├── Edit Inventory Checklist
│   └── Settings
│       ├── Location Preferences
│       ├── Notification Preferences
│       └── Logout
│
└── Shared Screens
    ├── Add Listing → Form + Photo Upload
    ├── Edit Listing → Pre-filled Form
    └── Other User Profile (read-only)
```

---

## 3. Content Taxonomy

### Item Categories (MVP)
```
Tools & Utility Equipment
├── Power Tools          (drill, jigsaw, sander)
├── Access Equipment     (ladder, step stool)
├── Cleaning Equipment   (vacuum cleaner, pressure washer)
├── Garden & Outdoor     (gardening tools, leaf blower)
├── Heavy-Duty Electrical (extension cable, generator)
└── AV Equipment         (projector, speakers)
```

### Rental Status Flow
```
pending → accepted → active → completed
   │                    │
   └→ cancelled         └→ disputed
```

### Request Status Flow
```
open → fulfilled
  │
  ├→ expired (auto after 48h)
  └→ cancelled
```

---

## 4. Data Objects & Relationships

```
User ──┬── owns ──→ Listings (1:many)
       ├── has ──→ User Inventory (1:many categories)
       ├── borrows ──→ Rentals (as borrower, 1:many)
       ├── lends ──→ Rentals (as lender, 1:many)
       ├── posts ──→ Requests (1:many)
       ├── rates ──→ Ratings (1:many)
       ├── reports ──→ Reports (1:many)
       └── receives ──→ Notifications (1:many)

Listing ──→ Rentals (1:many)

Rental ──→ Ratings (1:2, one per party)
Rental ──→ Reports (1:many)
```

---

## 5. User Flow Diagrams

### Borrower Journey
```
Register → Set Location → Browse Home Feed
  → Search / Filter → View Item Detail
  → Select Dates → See Cost Estimate
  → Read Rental Agreement → Tap "I Agree"
  → Send Request → Wait for Acceptance
  → Coordinate Pickup (external)
  → Use Item → Return Item
  → Rate Lender → Done
```

### Lender Journey
```
Register → Complete Inventory Checklist
  → Add Item Listing (photo + details)
  → Receive Request Notification
  → Review Request (borrower profile, dates)
  → Accept or Reject
  → Coordinate Pickup
  → Receive Item Back
  → Rate Borrower → View Earnings
```

### Geo-Broadcast Flow
```
Borrower: Post Request (category + duration + budget)
  → Supabase Edge Function queries users within 500m
  → FCM notification to matching inventory owners
  → Lender views request → responds with listing
  → Borrower selects → standard rental flow begins
```

---

## 6. Key Interaction Patterns

| Pattern | Implementation |
|---|---|
| **Bottom Nav** | 5 tabs, persistent across all main screens |
| **Pull-to-Refresh** | Home feed, My Rentals, Notifications |
| **Infinite Scroll** | Home feed listings loaded in pages |
| **Swipe Actions** | Accept/Reject on rental cards (Lending tab) |
| **Deep Linking** | Push notifications link to specific screens via GoRouter |
| **Modals / Sheets** | Rental agreement, date picker, cost breakdown |
| **Empty States** | Custom illustrations for: no listings, no rentals, no notifications |
| **Offline Banner** | Persistent banner when viewing cached data |

---

## 7. Location Model

| Parameter | Value |
|---|---|
| Default radius | 500 meters |
| User-adjustable radii | 100m, 500m, 1km |
| Geo data type | PostGIS `GEOGRAPHY(POINT, 4326)` |
| Query method | `ST_DWithin` spatial query on Supabase |
| Location source | Device GPS via `geolocator` package |
