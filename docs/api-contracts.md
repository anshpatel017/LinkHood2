# RentNear — API Contracts

---

## 1. Overview

RentNear communicates with Supabase via the **PostgREST** auto-generated REST API and custom **RPC functions**. All requests require a valid Supabase JWT in the `Authorization` header. The app also calls **Supabase Edge Functions** for server-side business logic.

**Base URL:** `https://<project-ref>.supabase.co`  
**Auth Header:** `Authorization: Bearer <access_token>`  
**API Key Header:** `apikey: <supabase_anon_key>`

---

## 2. Authentication API

### 2.1 Sign Up (Email + OTP)
```
POST /auth/v1/signup
```
**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "<optional>",
  "data": {
    "full_name": "John Doe"
  }
}
```
**Response (200):**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "confirmation_sent_at": "2026-01-01T00:00:00Z"
}
```

### 2.2 Verify OTP
```
POST /auth/v1/verify
```
**Request Body:**
```json
{
  "type": "signup",
  "token": "123456",
  "email": "user@example.com"
}
```
**Response (200):**
```json
{
  "access_token": "jwt_token",
  "refresh_token": "refresh_token",
  "user": { "id": "uuid", "email": "..." }
}
```

### 2.3 Login (OTP)
```
POST /auth/v1/otp
```
**Request Body:**
```json
{
  "email": "user@example.com"
}
```
**Response (200):**
```json
{
  "message_id": "msg_id"
}
```

### 2.4 Refresh Token
```
POST /auth/v1/token?grant_type=refresh_token
```
**Request Body:**
```json
{
  "refresh_token": "refresh_token"
}
```

### 2.5 Logout
```
POST /auth/v1/logout
```

---

## 3. Users API

### 3.1 Get Current User Profile
```
GET /rest/v1/users?id=eq.<user_id>&select=*
```
**Response (200):**
```json
[{
  "id": "uuid",
  "email": "user@example.com",
  "full_name": "John Doe",
  "avatar_url": "https://...",
  "location": "POINT(72.8 19.0)",
  "area_name": "Green Acres Society",
  "is_phone_verified": false,
  "rating_avg": 4.5,
  "rating_count": 12,
  "created_at": "2026-01-01T00:00:00Z"
}]
```

### 3.2 Update User Profile
```
PATCH /rest/v1/users?id=eq.<user_id>
```
**Request Body:**
```json
{
  "full_name": "Jane Doe",
  "avatar_url": "https://...",
  "location": "POINT(72.8 19.0)",
  "area_name": "Green Acres Society",
  "fcm_token": "fcm_token_string"
}
```
**Response (200):** Updated user object

---

## 4. Listings API

### 4.1 Get Nearby Listings (RPC)
```
POST /rest/v1/rpc/get_nearby_listings
```
**Request Body:**
```json
{
  "lat": 19.076,
  "lng": 72.877,
  "radius_meters": 500
}
```
**Response (200):**
```json
[{
  "id": "uuid",
  "owner_id": "uuid",
  "title": "Power Drill - Bosch",
  "description": "Heavy duty, works great",
  "category": "tools",
  "price_per_day": 50.00,
  "deposit_amount": 200.00,
  "image_urls": ["https://..."],
  "is_available": true,
  "is_instant": true,
  "view_count": 23,
  "created_at": "2026-01-01T00:00:00Z"
}]
```

### 4.2 Get Listing by ID
```
GET /rest/v1/listings?id=eq.<listing_id>&select=*,users!owner_id(full_name,avatar_url,rating_avg)
```

### 4.3 Create Listing
```
POST /rest/v1/listings
```
**Request Body:**
```json
{
  "owner_id": "uuid",
  "title": "Extension Cable 15m",
  "description": "Heavy-duty, 3-pin plug",
  "category": "electrical",
  "price_per_day": 30.00,
  "deposit_amount": 100.00,
  "image_urls": ["https://..."],
  "location": "POINT(72.877 19.076)",
  "area_name": "Green Acres",
  "is_available": true,
  "is_instant": false
}
```
**Response (201):** Created listing object

### 4.4 Update Listing
```
PATCH /rest/v1/listings?id=eq.<listing_id>
```
**Request Body:** Any mutable fields  
**RLS:** Only `owner_id = auth.uid()` permitted

### 4.5 Delete Listing
```
DELETE /rest/v1/listings?id=eq.<listing_id>
```
**RLS:** Only `owner_id = auth.uid()` permitted

---

## 5. Rentals API

### 5.1 Create Rental Request
```
POST /rest/v1/rentals
```
**Request Body:**
```json
{
  "listing_id": "uuid",
  "borrower_id": "uuid",
  "lender_id": "uuid",
  "start_date": "2026-03-10",
  "end_date": "2026-03-12",
  "total_cost": 100.00
}
```
**Response (201):** Created rental with `status: "pending"`

### 5.2 Get My Rentals (Borrower)
```
GET /rest/v1/rentals?borrower_id=eq.<user_id>&select=*,listings(title,image_urls,price_per_day),users!lender_id(full_name,avatar_url)&order=created_at.desc
```

### 5.3 Get My Rentals (Lender)
```
GET /rest/v1/rentals?lender_id=eq.<user_id>&select=*,listings(title,image_urls,price_per_day),users!borrower_id(full_name,avatar_url)&order=created_at.desc
```

### 5.4 Update Rental Status
```
PATCH /rest/v1/rentals?id=eq.<rental_id>
```
**Request Body:**
```json
{
  "status": "accepted"
}
```
**Valid transitions:**
| From | To | Actor |
|---|---|---|
| pending | accepted | lender |
| pending | cancelled | lender or borrower |
| accepted | active | lender (on pickup) |
| active | completed | lender (on return) |
| active | disputed | either party |

---

## 6. Requests API (Geo-Broadcast)

### 6.1 Create Geo-Broadcast Request
```
POST /rest/v1/requests
```
**Request Body:**
```json
{
  "requester_id": "uuid",
  "category": "tools",
  "description": "Need a power drill for wall mounting",
  "budget_per_day": 50.00,
  "duration_days": 2,
  "location": "POINT(72.877 19.076)",
  "area_name": "Green Acres"
}
```
**Response (201):** Created request  
**Rate limit:** 3 per day per user (enforced client-side + Edge Function)

### 6.2 Get Open Requests Nearby
```
GET /rest/v1/requests?status=eq.open&order=created_at.desc
```

---

## 7. Ratings API

### 7.1 Submit Rating
```
POST /rest/v1/ratings
```
**Request Body:**
```json
{
  "rental_id": "uuid",
  "rater_id": "uuid",
  "rated_user_id": "uuid",
  "score": 5,
  "review_text": "Very helpful neighbor!"
}
```
**Constraints:** `UNIQUE(rental_id, rater_id)` — one rating per party per rental

### 7.2 Get User Ratings
```
GET /rest/v1/ratings?rated_user_id=eq.<user_id>&select=*,users!rater_id(full_name,avatar_url)&order=created_at.desc
```

---

## 8. Reports API

### 8.1 Submit Issue Report
```
POST /rest/v1/reports
```
**Request Body:**
```json
{
  "rental_id": "uuid",
  "reporter_id": "uuid",
  "issue_type": "damage",
  "description": "Item returned with a crack on the handle",
  "image_urls": ["https://..."]
}
```

---

## 9. User Inventory API

### 9.1 Save Inventory
```
POST /rest/v1/user_inventory
```
**Request Body (bulk):**
```json
[
  { "user_id": "uuid", "category": "tools" },
  { "user_id": "uuid", "category": "cleaning" },
  { "user_id": "uuid", "category": "electrical" }
]
```

### 9.2 Get My Inventory
```
GET /rest/v1/user_inventory?user_id=eq.<user_id>
```

---

## 10. Notifications API

### 10.1 Get My Notifications
```
GET /rest/v1/notifications?user_id=eq.<user_id>&order=created_at.desc&limit=50
```

### 10.2 Mark as Read
```
PATCH /rest/v1/notifications?id=eq.<notification_id>
```
**Request Body:**
```json
{ "is_read": true }
```

---

## 11. Storage API (Images)

### 11.1 Upload Listing Image
```
POST /storage/v1/object/listing-images/<user_id>_<timestamp>.jpg
Content-Type: image/jpeg
```
**Response (200):**
```json
{
  "Key": "listing-images/<filename>.jpg"
}
```

### 11.2 Get Public URL
```
GET /storage/v1/object/public/listing-images/<filename>.jpg
```

---

## 12. Edge Functions

### 12.1 Geo-Broadcast Dispatcher
```
POST /functions/v1/broadcast_request
```
**Request Body:**
```json
{
  "requestId": "uuid",
  "lat": 19.076,
  "lng": 72.877,
  "category": "tools",
  "radiusMeters": 500
}
```
**Response (200):**
```json
{
  "sent": 5
}
```

---

## 13. Realtime Subscriptions

### 13.1 Rental Status Changes
```dart
supabase
  .from('rentals')
  .stream(primaryKey: ['id'])
  .eq('borrower_id', currentUserId)
  .listen((data) { /* update UI */ });
```

### 13.2 Notification Stream
```dart
supabase
  .from('notifications')
  .stream(primaryKey: ['id'])
  .eq('user_id', currentUserId)
  .listen((data) { /* update badge count */ });
```

---

## 14. Error Responses

| HTTP Code | Meaning | Example Scenario |
|---|---|---|
| 400 | Bad Request | Invalid fields, missing required data |
| 401 | Unauthorized | Expired or missing JWT |
| 403 | Forbidden | RLS policy violation |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Duplicate unique constraint (e.g., double rating) |
| 422 | Unprocessable | Check constraint violation (e.g., score out of range) |
| 500 | Server Error | Supabase/Edge Function failure |
