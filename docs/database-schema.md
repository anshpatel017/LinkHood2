# RentNear — Database Schema

---

## 1. Overview

RentNear uses **PostgreSQL** via **Supabase** with the **PostGIS** extension enabled for spatial queries. All tables use UUID primary keys, timestamptz for datetime fields, and Row Level Security (RLS) policies for access control.

---

## 2. Entity Relationship Diagram

```
┌──────────┐     1:N     ┌──────────┐     1:N     ┌──────────┐
│  users   │────────────▶│ listings │────────────▶│ rentals  │
│          │             │          │             │          │
│  id (PK) │             │  id (PK) │             │  id (PK) │
│  email   │             │ owner_id │◀─ FK ──────│listing_id│
│  phone   │             │  title   │             │borrower_id│◀─ FK
│  location│             │ location │             │ lender_id │◀─ FK
│  fcm_tkn │             │  price   │             │  status   │
│  rating  │             │ category │             │  dates    │
└──────┬───┘             └──────────┘             └─────┬────┘
       │                                                │
       │  1:N     ┌───────────────┐                     │ 1:2
       ├────────▶│user_inventory │                     │
       │         │               │              ┌──────▼────┐
       │         │  user_id (FK) │              │  ratings   │
       │         │  category     │              │            │
       │         └───────────────┘              │ rental_id  │
       │                                        │ rater_id   │
       │  1:N     ┌──────────────┐              │rated_user  │
       ├────────▶│ requests     │              │  score     │
       │         │ (geo-bcast)  │              └────────────┘
       │         │ requester_id │
       │         │  category    │                    1:N
       │         │  location    │              ┌────────────┐
       │         └──────────────┘              │  reports   │
       │                                       │            │
       │  1:N     ┌──────────────┐             │ rental_id  │
       └────────▶│notifications │             │reporter_id │
                  │              │             │ issue_type │
                  │  user_id     │             └────────────┘
                  │  title/body  │
                  │  type        │
                  └──────────────┘
```

---

## 3. Table Definitions

### 3.1 `users`
```sql
CREATE TABLE users (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email             TEXT UNIQUE NOT NULL,
  phone             TEXT,
  full_name         TEXT NOT NULL,
  avatar_url        TEXT,
  location          GEOGRAPHY(POINT, 4326),
  area_name         TEXT,
  fcm_token         TEXT,
  is_phone_verified BOOLEAN DEFAULT FALSE,
  rating_avg        DECIMAL(3,2) DEFAULT 0.0,
  rating_count      INTEGER DEFAULT 0,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_location ON users USING GIST(location);
```

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | UUID | PK, auto-gen | Supabase auth UID |
| email | TEXT | UNIQUE, NOT NULL | Login identifier |
| phone | TEXT | nullable | For trust verification |
| full_name | TEXT | NOT NULL | Display name |
| avatar_url | TEXT | nullable | Supabase Storage URL |
| location | GEOGRAPHY | GIST index | User's home/GPS coordinate |
| area_name | TEXT | nullable | Human-readable area label |
| fcm_token | TEXT | nullable | Firebase Cloud Messaging token |
| is_phone_verified | BOOLEAN | default false | Trust badge eligibility |
| rating_avg | DECIMAL(3,2) | default 0.0 | Computed average rating |
| rating_count | INTEGER | default 0 | Total ratings received |
| created_at | TIMESTAMPTZ | default NOW() | Registration timestamp |

---

### 3.2 `listings`
```sql
CREATE TABLE listings (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id        UUID REFERENCES users(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  description     TEXT,
  category        TEXT NOT NULL,
  price_per_day   DECIMAL(10,2) NOT NULL,
  deposit_amount  DECIMAL(10,2) DEFAULT 0,
  image_urls      TEXT[],
  location        GEOGRAPHY(POINT, 4326),
  area_name       TEXT,
  is_available    BOOLEAN DEFAULT TRUE,
  is_instant      BOOLEAN DEFAULT FALSE,
  view_count      INTEGER DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_listings_location  ON listings USING GIST(location);
CREATE INDEX idx_listings_category  ON listings(category);
CREATE INDEX idx_listings_available ON listings(is_available);
CREATE INDEX idx_listings_owner     ON listings(owner_id);
```

---

### 3.3 `rentals`
```sql
CREATE TABLE rentals (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id    UUID REFERENCES listings(id),
  borrower_id   UUID REFERENCES users(id),
  lender_id     UUID REFERENCES users(id),
  start_date    DATE NOT NULL,
  end_date      DATE NOT NULL,
  total_days    INTEGER GENERATED ALWAYS AS (end_date - start_date) STORED,
  total_cost    DECIMAL(10,2) NOT NULL,
  status        TEXT DEFAULT 'pending',
  pickup_note   TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_rentals_borrower ON rentals(borrower_id);
CREATE INDEX idx_rentals_lender   ON rentals(lender_id);
CREATE INDEX idx_rentals_status   ON rentals(status);
```

**Status values:** `pending` → `accepted` → `active` → `completed` | `cancelled` | `disputed`

---

### 3.4 `requests` (Geo-Broadcast)
```sql
CREATE TABLE requests (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id    UUID REFERENCES users(id),
  category        TEXT NOT NULL,
  description     TEXT,
  budget_per_day  DECIMAL(10,2),
  duration_days   INTEGER NOT NULL,
  location        GEOGRAPHY(POINT, 4326),
  area_name       TEXT,
  status          TEXT DEFAULT 'open',
  expires_at      TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '48 hours'),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_requests_location ON requests USING GIST(location);
CREATE INDEX idx_requests_status   ON requests(status);
```

**Status values:** `open` → `fulfilled` | `expired` | `cancelled`

---

### 3.5 `user_inventory`
```sql
CREATE TABLE user_inventory (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  category    TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, category)
);

CREATE INDEX idx_inventory_user     ON user_inventory(user_id);
CREATE INDEX idx_inventory_category ON user_inventory(category);
```

---

### 3.6 `ratings`
```sql
CREATE TABLE ratings (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rental_id     UUID REFERENCES rentals(id),
  rater_id      UUID REFERENCES users(id),
  rated_user_id UUID REFERENCES users(id),
  score         INTEGER CHECK (score BETWEEN 1 AND 5),
  review_text   TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(rental_id, rater_id)
);
```

---

### 3.7 `reports`
```sql
CREATE TABLE reports (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rental_id   UUID REFERENCES rentals(id),
  reporter_id UUID REFERENCES users(id),
  issue_type  TEXT NOT NULL,
  description TEXT,
  image_urls  TEXT[],
  status      TEXT DEFAULT 'open',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
```

---

### 3.8 `notifications`
```sql
CREATE TABLE notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  type        TEXT NOT NULL,
  payload     JSONB,
  is_read     BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, is_read);
```

---

## 4. Row Level Security (RLS) Policies

```sql
-- USERS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view all profiles"     ON users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile"    ON users FOR UPDATE USING (auth.uid() = id);

-- LISTINGS
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view listings"         ON listings FOR SELECT USING (true);
CREATE POLICY "Owners can insert own listings"   ON listings FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Owners can update own listings"   ON listings FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "Owners can delete own listings"   ON listings FOR DELETE USING (auth.uid() = owner_id);

-- RENTALS
ALTER TABLE rentals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Rental parties can view"          ON rentals FOR SELECT USING (
  auth.uid() = borrower_id OR auth.uid() = lender_id
);
CREATE POLICY "Borrower can create rental"       ON rentals FOR INSERT WITH CHECK (auth.uid() = borrower_id);
CREATE POLICY "Parties can update status"        ON rentals FOR UPDATE USING (
  auth.uid() = lender_id OR auth.uid() = borrower_id
);

-- REQUESTS
ALTER TABLE requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view open requests"    ON requests FOR SELECT USING (status = 'open');
CREATE POLICY "Owner can manage request"         ON requests FOR ALL USING (auth.uid() = requester_id);

-- USER_INVENTORY
ALTER TABLE user_inventory ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own inventory"     ON user_inventory FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own inventory"   ON user_inventory FOR ALL USING (auth.uid() = user_id);

-- RATINGS
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view ratings"          ON ratings FOR SELECT USING (true);
CREATE POLICY "Rater can insert rating"          ON ratings FOR INSERT WITH CHECK (auth.uid() = rater_id);

-- REPORTS
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Reporter can create report"       ON reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);
CREATE POLICY "Reporter can view own reports"    ON reports FOR SELECT USING (auth.uid() = reporter_id);

-- NOTIFICATIONS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);
```

---

## 5. Stored SQL Functions

### `get_nearby_listings`
```sql
CREATE OR REPLACE FUNCTION get_nearby_listings(lat FLOAT, lng FLOAT, radius_meters INT)
RETURNS SETOF listings AS $$
  SELECT *
  FROM listings
  WHERE ST_DWithin(
    location::geography,
    ST_MakePoint(lng, lat)::geography,
    radius_meters
  )
  AND is_available = TRUE
  ORDER BY
    ST_Distance(location::geography, ST_MakePoint(lng, lat)::geography) ASC,
    created_at DESC;
$$ LANGUAGE sql STABLE;
```

### `get_nearby_inventory_users`
```sql
CREATE OR REPLACE FUNCTION get_nearby_inventory_users(
  lat FLOAT, lng FLOAT, radius_meters INT, item_category TEXT
)
RETURNS TABLE(user_id UUID, fcm_token TEXT) AS $$
  SELECT u.id AS user_id, u.fcm_token
  FROM users u
  JOIN user_inventory i ON i.user_id = u.id
  WHERE i.category = item_category
    AND ST_DWithin(
      u.location::geography,
      ST_MakePoint(lng, lat)::geography,
      radius_meters
    )
    AND u.fcm_token IS NOT NULL;
$$ LANGUAGE sql STABLE;
```

---

## 6. Index Summary

| Table | Column(s) | Type | Purpose |
|---|---|---|---|
| users | location | GIST | Spatial proximity queries |
| listings | location | GIST | Nearby listing discovery |
| listings | category | B-tree | Category filter |
| listings | is_available | B-tree | Availability filter |
| listings | owner_id | B-tree | Owner lookup |
| rentals | borrower_id | B-tree | Borrower's rental list |
| rentals | lender_id | B-tree | Lender's rental list |
| rentals | status | B-tree | Status-based queries |
| requests | location | GIST | Geo-broadcast radius |
| requests | status | B-tree | Active request filter |
| user_inventory | user_id | B-tree | Inventory lookup |
| user_inventory | category | B-tree | Category matching |
| notifications | user_id, is_read | B-tree (composite) | Unread notification fetch |

---

## 7. Migration Strategy

All schema changes managed via **Supabase CLI**:

```bash
supabase migration new <description>   # Create migration file
supabase db reset                       # Apply locally
supabase db push                        # Push to production
```

- Files stored in `supabase/migrations/`
- Naming: `YYYYMMDDHHMMSS_description.sql`
- **Never edit production schema directly** — always via migration files
