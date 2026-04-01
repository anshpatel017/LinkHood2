# RentNear — Scoring Engine Specification

---

## 1. Overview

The RentNear scoring engine computes and manages several numeric scores that drive trust, discovery, and engagement across the platform. These scores are used for:

- **User trust & reputation** (displayed on profiles and item cards)
- **Listing ranking** (ordering items in the home feed)
- **Geo-broadcast matching priority** (ordering which lenders get notified first)
- **Verified Neighbor badge** eligibility

---

## 2. User Trust Score (Rating System)

### 2.1 Rating Collection
- Collected **after every completed rental** from both borrower and lender
- Scale: **1–5 stars** (integer)
- Optional: short text review
- Constraint: one rating per party per rental (`UNIQUE(rental_id, rater_id)`)

### 2.2 Rating Computation

**Fields on `users` table:**
| Field | Type | Description |
|---|---|---|
| `rating_avg` | `DECIMAL(3,2)` | Running weighted average |
| `rating_count` | `INTEGER` | Total ratings received |

**Update formula (on new rating insert):**
```
new_avg = ((old_avg × old_count) + new_score) / (old_count + 1)
new_count = old_count + 1
```

**SQL trigger (recommended):**
```sql
CREATE OR REPLACE FUNCTION update_user_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE users
  SET rating_avg = (
    SELECT ROUND(AVG(score)::numeric, 2)
    FROM ratings
    WHERE rated_user_id = NEW.rated_user_id
  ),
  rating_count = (
    SELECT COUNT(*)
    FROM ratings
    WHERE rated_user_id = NEW.rated_user_id
  )
  WHERE id = NEW.rated_user_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_user_rating
AFTER INSERT ON ratings
FOR EACH ROW
EXECUTE FUNCTION update_user_rating();
```

### 2.3 Rating Display Rules
| Context | Display |
|---|---|
| Profile page | Star average (e.g., ★ 4.5) + total count |
| Listing cards | Owner rating shown inline |
| Rental request detail | Borrower's rating shown to lender |
| Minimum display threshold | Rating shown only after 1+ ratings received |

---

## 3. Verified Neighbor Badge

### 3.1 Eligibility Criteria
A user earns the **"Verified Neighbor"** badge when ALL conditions are met:

| Criterion | Threshold |
|---|---|
| Completed rentals (as lender or borrower) | ≥ 3 |
| Average rating | ≥ 3.5 |
| Phone or email verified | `is_phone_verified = true` OR email verified |
| Open reports against user | 0 |

### 3.2 Badge Computation
```sql
CREATE OR REPLACE FUNCTION is_verified_neighbor(user_uuid UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM users u
    WHERE u.id = user_uuid
      AND u.rating_count >= 3
      AND u.rating_avg >= 3.5
      AND u.is_phone_verified = TRUE
      AND NOT EXISTS (
        SELECT 1 FROM reports r
        JOIN rentals rt ON r.rental_id = rt.id
        WHERE (rt.borrower_id = user_uuid OR rt.lender_id = user_uuid)
          AND r.status = 'open'
      )
  );
$$ LANGUAGE sql STABLE;
```

### 3.3 Display
- Green checkmark badge on profile and listing cards
- Badge text: "Verified Neighbor"
- Tooltip: "This user has 3+ successful rentals, a high rating, and a verified identity"

---

## 4. Listing Ranking Score

### 4.1 Purpose
Determines the order of listings in the home feed when multiple items are at similar distances.

### 4.2 Ranking Factors

| Factor | Weight | Source |
|---|---|---|
| Distance from user | Primary sort | PostGIS `ST_Distance` |
| Recency (created_at) | Secondary sort | `listings.created_at` DESC |
| Is instant available | Boost | `is_instant = true` items first |
| Owner rating | Tiebreaker | Higher `users.rating_avg` ranked first |

### 4.3 Ranking Query
```sql
CREATE OR REPLACE FUNCTION get_ranked_nearby_listings(
  lat FLOAT, lng FLOAT, radius_meters INT
)
RETURNS TABLE(
  listing_id UUID, title TEXT, category TEXT,
  price_per_day DECIMAL, image_urls TEXT[],
  owner_name TEXT, owner_rating DECIMAL,
  is_instant BOOLEAN, distance_meters FLOAT
) AS $$
  SELECT
    l.id AS listing_id,
    l.title,
    l.category,
    l.price_per_day,
    l.image_urls,
    u.full_name AS owner_name,
    u.rating_avg AS owner_rating,
    l.is_instant,
    ST_Distance(
      l.location::geography,
      ST_MakePoint(lng, lat)::geography
    ) AS distance_meters
  FROM listings l
  JOIN users u ON l.owner_id = u.id
  WHERE ST_DWithin(
    l.location::geography,
    ST_MakePoint(lng, lat)::geography,
    radius_meters
  )
  AND l.is_available = TRUE
  ORDER BY
    l.is_instant DESC,
    distance_meters ASC,
    u.rating_avg DESC,
    l.created_at DESC;
$$ LANGUAGE sql STABLE;
```

---

## 5. Geo-Broadcast Matching Priority

### 5.1 Purpose
When a borrower posts a geo-broadcast request, the system selects nearby lenders who own that item category. Matching priority determines who gets notified first.

### 5.2 Priority Factors

| Priority | Factor | Rationale |
|---|---|---|
| 1 | Distance (closest first) | Hyperlocal preference |
| 2 | Has active listing in category | Already a proven lender |
| 3 | User rating (higher first) | Trust signal |
| 4 | Verified Neighbor badge | Extra trust |

### 5.3 Matching Query
```sql
CREATE OR REPLACE FUNCTION get_broadcast_targets(
  lat FLOAT, lng FLOAT, radius_meters INT, item_category TEXT
)
RETURNS TABLE(
  user_id UUID, fcm_token TEXT, distance_meters FLOAT,
  has_active_listing BOOLEAN, user_rating DECIMAL
) AS $$
  SELECT
    u.id AS user_id,
    u.fcm_token,
    ST_Distance(
      u.location::geography,
      ST_MakePoint(lng, lat)::geography
    ) AS distance_meters,
    EXISTS (
      SELECT 1 FROM listings l
      WHERE l.owner_id = u.id
        AND l.category = item_category
        AND l.is_available = TRUE
    ) AS has_active_listing,
    u.rating_avg AS user_rating
  FROM users u
  JOIN user_inventory i ON i.user_id = u.id
  WHERE i.category = item_category
    AND ST_DWithin(
      u.location::geography,
      ST_MakePoint(lng, lat)::geography,
      radius_meters
    )
    AND u.fcm_token IS NOT NULL
  ORDER BY
    has_active_listing DESC,
    distance_meters ASC,
    u.rating_avg DESC;
$$ LANGUAGE sql STABLE;
```

---

## 6. Earnings Estimate Score

### 6.1 Purpose
Shown on the Add Listing screen to motivate lenders: *"You could earn ₹X/month at this price."*

### 6.2 Calculation
```
estimated_monthly_earnings = price_per_day × average_rental_days_per_month
```

**MVP default:** `average_rental_days_per_month = 8` (conservative assumption)

### 6.3 Display Logic
```dart
String getEarningsEstimate(double pricePerDay) {
  const avgRentalDaysPerMonth = 8;
  final estimate = pricePerDay * avgRentalDaysPerMonth;
  return 'You could earn ₹${estimate.toStringAsFixed(0)}/month';
}
```

**Post-MVP enhancement:** Replace the static assumption with actual community rental data as it accumulates.

---

## 7. Rate Limiting Score

### 7.1 Geo-Broadcast Request Limit
- **Limit:** 3 geo-broadcast requests per user per day
- **Enforcement:** Client-side check + server-side validation in Edge Function

### 7.2 Check Query
```sql
SELECT COUNT(*) FROM requests
WHERE requester_id = $user_id
  AND created_at >= NOW() - INTERVAL '24 hours';
```

### 7.3 Client-Side Guard
```dart
Future<bool> canPostRequest(String userId) async {
  final count = await supabase
    .from('requests')
    .select('id')
    .eq('requester_id', userId)
    .gte('created_at', DateTime.now().subtract(Duration(days: 1)).toIso8601String());
  return (count as List).length < 3;
}
```

---

## 8. Score Summary Table

| Score | Stored | Computed | Display Location | Update Trigger |
|---|---|---|---|---|
| User Rating (avg) | `users.rating_avg` | DB trigger | Profile, listing cards, rental details | On rating insert |
| User Rating (count) | `users.rating_count` | DB trigger | Profile | On rating insert |
| Verified Neighbor | Computed at query time | SQL function | Profile, listing cards | — |
| Listing Rank | Computed at query time | SQL function | Home feed order | — |
| Broadcast Priority | Computed at query time | SQL function | Edge Function dispatch | — |
| Earnings Estimate | Computed client-side | Dart function | Add Listing screen | — |
| Daily Request Count | Computed at query time | SQL count | Post Request screen | — |
