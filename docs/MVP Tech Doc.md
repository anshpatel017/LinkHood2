# RentNear — MVP Technical Document

## 1. MVP Goal

Prove that at least **30 users in one residential society** can list items, request rentals, and complete transactions within the app — without disputes, crashes, or trust failures.

Success metrics:
- 30+ active listings
- 15+ completed rentals
- 4.0+ average user rating
- 0 critical crashes in production
- Repeat rental rate > 20%

---

## 2. MVP Scope (Strictly Defined)

### Must-Have Features (Non-Negotiable)

| Feature | Description |
|---|---|
| User Signup / Login | Email + OTP via Supabase Auth |
| Onboarding — Item Inventory | Ask users what items they own (checklist) on first login |
| Home Feed | Location-based listing cards with search and category filter |
| Add Listing | Photo + title + category + price/day + description + availability toggle |
| Item Detail Page | Full info, owner rating, availability calendar, "Request to Rent" button |
| Rental Request Flow | Select dates, see cost estimate, confirm request |
| Request Management | Lender accepts or rejects incoming requests |
| My Rentals Dashboard | Tabs: Renting / Lending — with status (Pending, Active, Completed) |
| Geo-Broadcast Request | Post "I need X" — notifies nearby users with that item category |
| Push Notifications | FCM alerts for requests, acceptances, and reminders |
| Ratings & Reviews | Post-rental rating for both sides |
| User Profile | Name, photo, rating, listed items, rental history |
| Rental Agreement Display | Auto-shown terms before confirming — duration, deposit note, damage clause |
| Report Issue Button | Available on all active rental screens |
| Basic Offline Cache | Hive cache for home listings, SQLite for rental history |

### Nice-to-Have (Post-MVP Only)

- In-app payment (Razorpay / Stripe)
- In-app chat with media sharing
- Dark mode
- Referral system
- Wallet / earnings payout
- Delivery coordination
- AI pricing suggestions
- Admin dashboard

---

## 3. Core User Flows

### Borrower Flow
```
Register → Set location → Browse / Search items
→ View item detail → Select rental dates
→ Send request → Wait for acceptance
→ Coordinate pickup (external / chat)
→ Return item → Rate lender
```

### Lender Flow
```
Register → Onboarding checklist (what do you own?)
→ Add item listing → Receive rental request notification
→ Accept or reject → Coordinate pickup
→ Receive item back → Rate borrower
→ View earnings summary
```

### Geo-Broadcast Request Flow
```
Borrower: Post request (category + duration + budget)
→ App queries users within 500m with matching category
→ FCM notification sent to matching lenders
→ Lender views request → Responds with their listing
```

---

## 4. Bootstrap Commands

```bash
# Create Flutter project
flutter create rentnear
cd rentnear

# Add core dependencies
flutter pub add supabase_flutter
flutter pub add flutter_riverpod
flutter pub add riverpod_annotation
flutter pub add go_router
flutter pub add hive
flutter pub add hive_flutter
flutter pub add sqflite
flutter pub add flutter_secure_storage
flutter pub add firebase_core
flutter pub add firebase_analytics
flutter pub add firebase_crashlytics
flutter pub add firebase_messaging
flutter pub add geolocator
flutter pub add image_picker
flutter pub add cached_network_image
flutter pub add intl

# Dev dependencies
flutter pub add --dev build_runner
flutter pub add --dev riverpod_generator
flutter pub add --dev hive_generator
flutter pub add --dev flutter_lints

# Run
flutter run
```

---

## 5. Supabase Initialization

```dart
// main.dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: RentNearApp()));
}
```

---

## 6. State Management Pattern (Riverpod)

```dart
// Example: Listings provider
@riverpod
class ListingsNotifier extends _$ListingsNotifier {
  @override
  Future<List<Listing>> build() async {
    return ref.read(listingRepositoryProvider).getNearbyListings(
      lat: ref.read(locationProvider).lat,
      lng: ref.read(locationProvider).lng,
      radiusMeters: 500,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => future);
  }
}
```

---

## 7. Geo-Radius Query (Supabase)

```sql
-- Supabase SQL: Get listings within 500 meters
SELECT *
FROM listings
WHERE ST_DWithin(
  location::geography,
  ST_MakePoint($lng, $lat)::geography,
  500
)
AND is_available = true
ORDER BY created_at DESC;
```

Flutter call:
```dart
final response = await supabase.rpc('get_nearby_listings', params: {
  'lat': userLat,
  'lng': userLng,
  'radius_meters': 500,
});
```

---

## 8. Push Notification — Geo-Broadcast (Edge Function)

```typescript
// Supabase Edge Function: broadcast_request.ts
Deno.serve(async (req) => {
  const { requestId, lat, lng, category } = await req.json();

  // Find users within 500m who own this category
  const { data: nearbyUsers } = await supabase
    .from('user_inventory')
    .select('user_id, fcm_token')
    .eq('category', category)
    .filter('location', 'st_dwithin', { lat, lng, radius: 500 });

  // Send FCM notification to each user
  for (const user of nearbyUsers) {
    await sendFCMNotification(user.fcm_token, {
      title: 'Someone nearby needs your help!',
      body: `A neighbor needs a ${category} for rent.`,
      data: { requestId },
    });
  }

  return new Response(JSON.stringify({ sent: nearbyUsers.length }));
});
```

---

## 9. Local Cache Strategy

```dart
// Hive — cache home listings
class ListingCache {
  static const _boxName = 'listings_cache';

  Future<void> saveListings(List<Listing> listings) async {
    final box = await Hive.openBox(_boxName);
    await box.put('home_feed', listings.map((l) => l.toJson()).toList());
  }

  Future<List<Listing>> getCachedListings() async {
    final box = await Hive.openBox(_boxName);
    final raw = box.get('home_feed') as List?;
    return raw?.map((e) => Listing.fromJson(e)).toList() ?? [];
  }
}
```

---

## 10. Security Checklist

- [ ] All Supabase tables have Row Level Security (RLS) enabled
- [ ] Users can only read/update their own profile rows
- [ ] Listing CRUD restricted to owner only
- [ ] Rental requests visible only to borrower + lender
- [ ] FCM tokens stored per user, rotated on session refresh
- [ ] No API keys in source code — use `--dart-define` or `.env`
- [ ] flutter_secure_storage for all sensitive local data
- [ ] HTTPS enforced on all Supabase calls (default)
- [ ] Input validation on all form fields (length, type, null)

---

## 11. Testing Strategy

| Test Type | Scope | Tool |
|---|---|---|
| Unit Tests | Use cases, repositories, utils | flutter_test |
| Widget Tests | Home feed, listing form, request flow | flutter_test |
| Integration Tests | Auth → List item → Request → Complete | integration_test |
| Manual QA | End-to-end on physical device | Manual |

Minimum coverage target before store submission: **60% on domain layer**.

---

## 12. Release Build Commands

```bash
# Android
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=your_url \
  --dart-define=SUPABASE_ANON_KEY=your_key

# iOS
flutter build ipa --release \
  --dart-define=SUPABASE_URL=your_url \
  --dart-define=SUPABASE_ANON_KEY=your_key
```

---

## 13. Minimal Repo Structure

```
rentnear/
├── lib/                    # All Flutter source code
├── assets/
│   ├── images/             # App logo, placeholders
│   └── icons/              # Category icons
├── test/                   # Unit and widget tests
├── integration_test/       # End-to-end tests
├── supabase/
│   ├── migrations/         # SQL migration files
│   └── functions/          # Edge Functions
├── .github/
│   └── workflows/
│       └── ci.yml          # GitHub Actions CI/CD
├── pubspec.yaml
├── .env.example
└── README.md
```

---

## 14. CI/CD — GitHub Actions

```yaml
# .github/workflows/ci.yml
name: RentNear CI

on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build appbundle --release
```
