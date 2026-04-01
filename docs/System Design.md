# RentNear — System Design Document

## 1. System Overview

RentNear is a hyperlocal mobile-first rental marketplace. The system supports:
- Location-based item discovery within a configurable radius
- Peer-to-peer rental request and acceptance workflow
- Geo-broadcast demand notifications
- Real-time rental status updates
- Offline-capable listing browsing

**Scale target (MVP):** 1–5 societies, ~500 concurrent users, ~1,000 listings

---

## 2. High-Level Architecture Diagram

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

## 3. Database Schema

### Table: `users`
```sql
CREATE TABLE users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email           TEXT UNIQUE NOT NULL,
  phone           TEXT,
  full_name       TEXT NOT NULL,
  avatar_url      TEXT,
  location        GEOGRAPHY(POINT, 4326),
  area_name       TEXT,
  fcm_token       TEXT,
  is_phone_verified BOOLEAN DEFAULT FALSE,
  rating_avg      DECIMAL(3,2) DEFAULT 0.0,
  rating_count    INTEGER DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_location ON users USING GIST(location);
```

### Table: `listings`
```sql
CREATE TABLE listings (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id        UUID REFERENCES users(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  description     TEXT,
  category        TEXT NOT NULL,        -- 'tools', 'electronics', etc.
  price_per_day   DECIMAL(10,2) NOT NULL,
  deposit_amount  DECIMAL(10,2) DEFAULT 0,
  image_urls      TEXT[],
  location        GEOGRAPHY(POINT, 4326),
  area_name       TEXT,
  is_available    BOOLEAN DEFAULT TRUE,
  is_instant      BOOLEAN DEFAULT FALSE, -- "Available Today" badge
  view_count      INTEGER DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_listings_location ON listings USING GIST(location);
CREATE INDEX idx_listings_category ON listings(category);
CREATE INDEX idx_listings_available ON listings(is_available);
CREATE INDEX idx_listings_owner ON listings(owner_id);
```

### Table: `rentals`
```sql
CREATE TABLE rentals (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id      UUID REFERENCES listings(id),
  borrower_id     UUID REFERENCES users(id),
  lender_id       UUID REFERENCES users(id),
  start_date      DATE NOT NULL,
  end_date        DATE NOT NULL,
  total_days      INTEGER GENERATED ALWAYS AS (end_date - start_date) STORED,
  total_cost      DECIMAL(10,2) NOT NULL,
  status          TEXT DEFAULT 'pending',
  -- Status values: pending, accepted, active, completed, cancelled, disputed
  pickup_note     TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_rentals_borrower ON rentals(borrower_id);
CREATE INDEX idx_rentals_lender ON rentals(lender_id);
CREATE INDEX idx_rentals_status ON rentals(status);
```

### Table: `requests` (Geo-Broadcast)
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
  -- Status values: open, fulfilled, expired, cancelled
  expires_at      TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '48 hours'),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_requests_location ON requests USING GIST(location);
CREATE INDEX idx_requests_status ON requests(status);
```

### Table: `user_inventory`
```sql
CREATE TABLE user_inventory (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  category    TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, category)
);

CREATE INDEX idx_inventory_user ON user_inventory(user_id);
CREATE INDEX idx_inventory_category ON user_inventory(category);
```

### Table: `ratings`
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

### Table: `reports`
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

### Table: `notifications`
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
-- Users: read public profiles, write own row only
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view all profiles" ON users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);

-- Listings: public read, owner write
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view available listings" ON listings FOR SELECT USING (true);
CREATE POLICY "Owners can insert own listings" ON listings FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Owners can update own listings" ON listings FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "Owners can delete own listings" ON listings FOR DELETE USING (auth.uid() = owner_id);

-- Rentals: visible to borrower and lender only
ALTER TABLE rentals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Rental parties can view" ON rentals FOR SELECT USING (
  auth.uid() = borrower_id OR auth.uid() = lender_id
);
CREATE POLICY "Borrower can create rental" ON rentals FOR INSERT WITH CHECK (auth.uid() = borrower_id);
CREATE POLICY "Lender can update status" ON rentals FOR UPDATE USING (
  auth.uid() = lender_id OR auth.uid() = borrower_id
);

-- Requests: public read, owner write
ALTER TABLE requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view open requests" ON requests FOR SELECT USING (status = 'open');
CREATE POLICY "Owner can manage request" ON requests FOR ALL USING (auth.uid() = requester_id);
```

---

## 5. Supabase Edge Function — Geo-Broadcast Dispatcher

```typescript
// supabase/functions/broadcast_request/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { requestId, lat, lng, category, radiusMeters = 500 } = await req.json()

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // Find users within radius who have this category in their inventory
  const { data: targetUsers } = await supabase.rpc('get_nearby_inventory_users', {
    lat, lng,
    radius_meters: radiusMeters,
    item_category: category,
  })

  let sent = 0
  for (const user of targetUsers ?? []) {
    if (!user.fcm_token) continue

    await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Authorization': `key=${Deno.env.get('FCM_SERVER_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        to: user.fcm_token,
        notification: {
          title: 'A neighbor needs your help!',
          body: `Someone nearby needs a ${category} for rent.`,
        },
        data: { requestId, type: 'geo_request' },
      }),
    })
    sent++
  }

  // Save notification records
  await supabase.from('notifications').insert(
    (targetUsers ?? []).map((u: any) => ({
      user_id: u.user_id,
      title: 'A neighbor needs your help!',
      body: `Someone nearby needs a ${category} for rent.`,
      type: 'geo_request',
      payload: { requestId },
    }))
  )

  return new Response(JSON.stringify({ sent }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

---

## 6. Nearby Listings SQL Function

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

## 7. Realtime — Rental Status Updates

```dart
// Flutter: subscribe to rental status changes
final subscription = supabase
  .from('rentals')
  .stream(primaryKey: ['id'])
  .eq('borrower_id', currentUserId)
  .listen((List<Map<String, dynamic>> data) {
    ref.read(rentalNotifierProvider.notifier).updateFromStream(data);
  });
```

---

## 8. Offline Strategy

| Data | Storage | Sync Strategy |
|---|---|---|
| Home feed listings | Hive | Load on first fetch, refresh on reconnect |
| Rental history | SQLite | Append on completion, full sync on login |
| User profile | Hive | Cache on login, invalidate on update |
| Active rentals | In-memory | Always fetch live — no offline write |
| Notifications | Hive | Cache last 50, clear on read |

Connectivity detection:
```dart
import 'package:connectivity_plus/connectivity_plus.dart';

final isOnline = await Connectivity().checkConnectivity() != ConnectivityResult.none;
if (!isOnline) {
  return ref.read(listingCacheProvider).getCachedListings();
}
```

---

## 9. Image Upload Flow

```dart
Future<String> uploadListingImage(File imageFile, String userId) async {
  final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
  final path = 'listings/$fileName';

  await supabase.storage
    .from('listing-images')
    .upload(path, imageFile, fileOptions: const FileOptions(
      contentType: 'image/jpeg',
      upsert: false,
    ));

  return supabase.storage.from('listing-images').getPublicUrl(path);
}
```

---

## 10. Notification Types and Triggers

| Event | Trigger | Recipient |
|---|---|---|
| `rental_request` | Borrower creates rental | Lender |
| `rental_accepted` | Lender accepts | Borrower |
| `rental_rejected` | Lender rejects | Borrower |
| `rental_reminder` | 1 day before start | Borrower |
| `return_due` | Return date reached | Borrower + Lender |
| `geo_request` | Geo-broadcast posted | Nearby matching users |
| `rating_prompt` | Rental marked complete | Both parties |
| `report_received` | Issue reported | Lender (if damage claim) |

---

## 11. Migrations Strategy

All schema changes managed via Supabase CLI:

```bash
# Install Supabase CLI
npm install -g supabase

# Login and link project
supabase login
supabase link --project-ref your_project_ref

# Create new migration
supabase migration new add_listings_table

# Apply locally
supabase db reset

# Push to production
supabase db push
```

Migration files stored in: `supabase/migrations/`  
Each file named: `YYYYMMDDHHMMSS_description.sql`

Never edit production schema directly — always through migration files.

---

## 12. Security Summary

| Area | Control |
|---|---|
| API access | Supabase RLS on all tables |
| Auth tokens | Supabase JWT, rotated automatically |
| Local storage | flutter_secure_storage only |
| Image access | Supabase Storage bucket policies |
| API keys | Dart define at build time, never in code |
| Edge Functions | Service role key, never exposed to client |
| Input validation | All fields validated client + server side |
| Rate limiting | Request broadcast limited to 3/day per user |

---

## 13. App Publishing Checklist

### Android
- [ ] Generate release keystore (`keytool`)
- [ ] Configure `key.properties` in android folder
- [ ] Set version name and code in `pubspec.yaml`
- [ ] Build: `flutter build appbundle --release`
- [ ] Upload to Google Play Console (Internal Testing → Production)
- [ ] Fill store listing: description, screenshots, privacy policy URL
- [ ] Review time: 1–3 days

### iOS
- [ ] Apple Developer account ($99/year)
- [ ] Create App ID in Apple Developer portal
- [ ] Generate Distribution Certificate and Provisioning Profile
- [ ] Configure in Xcode: Bundle ID, signing
- [ ] Archive: `flutter build ipa --release`
- [ ] Upload via Xcode Organizer or Transporter
- [ ] TestFlight beta (optional, recommended)
- [ ] Submit for App Store Review (1–5 days)

### Required Assets
- App icon: 1024×1024 PNG (no alpha, no rounded corners)
- Splash screen: Android 9-patch + iOS LaunchScreen.storyboard
- Screenshots: Phone sizes (6.7" for iPhone, Pixel 6 for Android)
- Short description (80 chars), Full description (4000 chars)
- Privacy Policy URL (required by both stores)
- Support email address
- App category: Lifestyle or Shopping

### Estimated Costs
| Item | Cost |
|---|---|
| Google Play Developer Account | $25 one-time |
| Apple Developer Program | $99/year |
| Supabase (MVP) | Free tier |
| Firebase (MVP) | Free Spark plan |
| Domain + Privacy Policy hosting | ~$10/year |
| **Total for launch** | **~$135 first year** |
