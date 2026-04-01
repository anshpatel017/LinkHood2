# RentNear — Testing Strategy

---

## 1. Testing Philosophy

- **Test what matters** — focus on domain logic, critical user flows, and data integrity
- **Fail fast** — catch bugs before they reach production via CI/CD gates
- **Minimum coverage target:** 60% on the domain layer before store submission
- **Test pyramid:** many unit tests, fewer widget tests, minimal integration tests

```
        ╱  E2E / Integration  ╲       ← Few, slow, high confidence
       ╱──────────────────────╲
      ╱    Widget Tests        ╲      ← Moderate count
     ╱──────────────────────────╲
    ╱      Unit Tests            ╲    ← Many, fast, foundational
   ╱──────────────────────────────╲
```

---

## 2. Test Types Overview

| Test Type | Scope | Tool | Speed | CI Gate |
|---|---|---|---|---|
| **Unit Tests** | Use cases, repositories, utils, models | `flutter_test` | Fast | ✅ Yes |
| **Widget Tests** | UI components, forms, listing cards | `flutter_test` | Medium | ✅ Yes |
| **Integration Tests** | Full user flows (auth → list → rent → rate) | `integration_test` | Slow | ⬜ Manual |
| **Manual QA** | End-to-end on physical devices | Manual | Slow | ⬜ Pre-launch |
| **Security Audit** | RLS policies, auth flows | SQL + manual | Manual | ⬜ Pre-launch |

---

## 3. Unit Tests

### 3.1 What to Test

| Layer | Items | Example |
|---|---|---|
| **Use Cases** | All domain use cases | `LoginUseCase`, `CreateListingUseCase`, `GetNearbyListingsUseCase` |
| **Repositories** | Repository implementations (mocked datasources) | `ListingRepositoryImpl.getNearbyListings()` |
| **Models** | JSON ↔ Entity mappers | `UserModel.fromJson()`, `ListingModel.toJson()` |
| **Utils** | Distance calculator, date helpers, validators, formatters | `formatDistance(300)` → `"300m away"` |
| **Scoring** | Earnings estimate, rate limit check | `getEarningsEstimate(50)` → `"₹400/month"` |

### 3.2 Example Unit Test

```dart
// test/features/listings/domain/usecases/get_nearby_listings_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockListingRepository extends Mock implements ListingRepository {}

void main() {
  late GetNearbyListingsUseCase useCase;
  late MockListingRepository mockRepo;

  setUp(() {
    mockRepo = MockListingRepository();
    useCase = GetNearbyListingsUseCase(mockRepo);
  });

  test('returns nearby listings within radius', () async {
    final listings = [Listing(id: '1', title: 'Drill', pricePerDay: 50)];
    when(mockRepo.getNearbyListings(
      lat: 19.0, lng: 72.8, radiusMeters: 500,
    )).thenAnswer((_) async => listings);

    final result = await useCase(lat: 19.0, lng: 72.8, radiusMeters: 500);

    expect(result, listings);
    verify(mockRepo.getNearbyListings(
      lat: 19.0, lng: 72.8, radiusMeters: 500,
    )).called(1);
  });

  test('returns empty list when no listings nearby', () async {
    when(mockRepo.getNearbyListings(
      lat: anyNamed('lat'), lng: anyNamed('lng'),
      radiusMeters: anyNamed('radiusMeters'),
    )).thenAnswer((_) async => []);

    final result = await useCase(lat: 19.0, lng: 72.8, radiusMeters: 500);

    expect(result, isEmpty);
  });
}
```

### 3.3 Test File Structure

```
test/
├── core/
│   ├── utils/
│   │   ├── distance_calculator_test.dart
│   │   ├── date_helpers_test.dart
│   │   ├── validators_test.dart
│   │   └── currency_formatter_test.dart
│   └── errors/
│       └── failures_test.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/user_model_test.dart
│   │   │   └── repositories/auth_repository_impl_test.dart
│   │   └── domain/
│   │       └── usecases/
│   │           ├── login_usecase_test.dart
│   │           ├── signup_usecase_test.dart
│   │           └── verify_otp_usecase_test.dart
│   │
│   ├── listings/
│   │   ├── data/
│   │   │   ├── models/listing_model_test.dart
│   │   │   └── repositories/listing_repository_impl_test.dart
│   │   └── domain/
│   │       └── usecases/
│   │           ├── get_nearby_listings_usecase_test.dart
│   │           ├── create_listing_usecase_test.dart
│   │           └── delete_listing_usecase_test.dart
│   │
│   ├── rentals/
│   │   ├── data/
│   │   │   └── models/rental_model_test.dart
│   │   └── domain/
│   │       └── usecases/
│   │           ├── create_rental_usecase_test.dart
│   │           └── update_rental_status_usecase_test.dart
│   │
│   └── requests/
│       └── domain/
│           └── usecases/
│               └── create_request_usecase_test.dart
│
└── helpers/
    ├── test_data.dart          # Shared mock objects
    └── mock_providers.dart     # Mock Riverpod providers
```

---

## 4. Widget Tests

### 4.1 What to Test

| Widget | Assertions |
|---|---|
| `ListingCard` | Renders title, price, distance, owner rating, "Available Today" badge |
| `AuthFormField` | Validates email format, empty field errors |
| `RentalCard` | Displays correct status badge, counterparty name, dates |
| `CategoryFilterTabs` | Tap highlights correct tab, triggers filter callback |
| `RatingStars` | Shows correct number of filled/empty stars |
| `EmptyStateWidget` | Shows illustration and message when no data |
| `SearchBar` | Debounces input, triggers search callback |

### 4.2 Example Widget Test

```dart
// test/features/listings/presentation/widgets/listing_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ListingCard displays item info correctly', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ListingCard(
        listing: Listing(
          title: 'Power Drill',
          pricePerDay: 50,
          category: 'tools',
          isInstant: true,
          imageUrls: ['https://example.com/drill.jpg'],
        ),
        distance: '300m',
        ownerRating: 4.5,
      ),
    ));

    expect(find.text('Power Drill'), findsOneWidget);
    expect(find.text('₹50/day'), findsOneWidget);
    expect(find.text('300m'), findsOneWidget);
    expect(find.text('Available Today'), findsOneWidget);
  });
}
```

---

## 5. Integration Tests

### 5.1 Critical User Flows to Test

| # | Flow | Steps |
|---|---|---|
| 1 | **Auth Flow** | Launch → Login → OTP → Home Feed |
| 2 | **Listing Flow** | Home → Add Listing → Photo Upload → Listing appears on feed |
| 3 | **Rental Flow** | Item Detail → Select dates → Confirm → Lender sees request → Accept → Status updates |
| 4 | **Rating Flow** | Completed rental → Rate → Average updated |
| 5 | **Geo-Broadcast** | Post request → Notification sent → Lender views request |

### 5.2 Integration Test Example

```dart
// integration_test/rental_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete rental request flow', (tester) async {
    // Start app
    app.main();
    await tester.pumpAndSettle();

    // Navigate to item detail
    await tester.tap(find.byType(ListingCard).first);
    await tester.pumpAndSettle();

    // Tap "Request to Rent"
    await tester.tap(find.text('Request to Rent'));
    await tester.pumpAndSettle();

    // Select dates
    await tester.tap(find.text('Start Date'));
    await tester.pumpAndSettle();
    // ... select dates in picker

    // Confirm request
    await tester.tap(find.text('I Agree'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm Request'));
    await tester.pumpAndSettle();

    // Verify success
    expect(find.text('Request Sent!'), findsOneWidget);
  });
}
```

---

## 6. Security Testing

### 6.1 RLS Policy Audit

Test every table to ensure RLS policies are correctly enforced:

| Table | Test | Expected |
|---|---|---|
| `users` | Read any profile | ✅ Allowed |
| `users` | Update another user's profile | ❌ Denied |
| `listings` | Read any listing | ✅ Allowed |
| `listings` | Insert listing with different `owner_id` | ❌ Denied |
| `listings` | Delete another user's listing | ❌ Denied |
| `rentals` | Read rental where user is neither party | ❌ Denied |
| `rentals` | Insert rental as non-borrower | ❌ Denied |
| `requests` | Read open requests | ✅ Allowed |
| `requests` | Read expired/closed requests (other user's) | ❌ Denied |
| `notifications` | Read another user's notifications | ❌ Denied |

### 6.2 Auth Security Tests

| Test | Expected |
|---|---|
| Access API without JWT | 401 Unauthorized |
| Access API with expired JWT | 401 Unauthorized |
| Access protected route without auth | Redirect to login |
| OTP brute force (4+ attempts) | Rate limited |

---

## 7. Performance Testing

| Metric | Target | How to Measure |
|---|---|---|
| App launch time | < 2 seconds | DevTools timeline |
| Home feed load | < 1.5 seconds on 4G | Network profiling |
| Listing creation | < 2 minutes (UX time) | Manual stopwatch |
| API response p95 | < 800ms | Supabase dashboard |
| Image upload | < 3 seconds per photo | Network profiling |
| Offline feed display | < 500ms | DevTools timeline |

### Performance Checklist

- [ ] Use `const` constructors for all stateless widgets
- [ ] Lazy load listing images with `cached_network_image`
- [ ] Paginate home feed (load 20 items at a time)
- [ ] Compress images before upload (< 500KB)
- [ ] Avoid unnecessary rebuilds (use `select` in Riverpod)
- [ ] Profile memory usage — ensure no leaks in streams/subscriptions

---

## 8. Manual QA Checklist

### Pre-Launch Physical Device Testing

| # | Test Case | Android | iOS |
|---|---|---|---|
| 1 | Fresh install → signup → OTP → home feed | ⬜ | ⬜ |
| 2 | Login with existing account | ⬜ | ⬜ |
| 3 | Add listing with photo | ⬜ | ⬜ |
| 4 | Browse home feed, search, filter | ⬜ | ⬜ |
| 5 | Full rental flow (request → accept → complete) | ⬜ | ⬜ |
| 6 | Post geo-broadcast request | ⬜ | ⬜ |
| 7 | Receive push notification (all types) | ⬜ | ⬜ |
| 8 | Rate after completed rental | ⬜ | ⬜ |
| 9 | Report an issue | ⬜ | ⬜ |
| 10 | View profile (own + other user) | ⬜ | ⬜ |
| 11 | Toggle listing availability | ⬜ | ⬜ |
| 12 | Offline mode → airplane mode → view cached listings | ⬜ | ⬜ |
| 13 | Reconnect → feed auto-refreshes | ⬜ | ⬜ |
| 14 | Kill app → relaunch → session restored | ⬜ | ⬜ |
| 15 | GPS permission denied → graceful fallback | ⬜ | ⬜ |
| 16 | No listings nearby → empty state | ⬜ | ⬜ |
| 17 | Network error during request → error state | ⬜ | ⬜ |

---

## 9. CI/CD Test Gates

### Pipeline Configuration

```yaml
# Tests run on every push and PR
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze --fatal-infos    # Gate 1: Static analysis
      - run: flutter test --coverage          # Gate 2: Unit + Widget tests
```

### Gate Criteria

| Gate | Tool | Threshold | Blocks Deploy? |
|---|---|---|---|
| Static analysis | `flutter analyze` | Zero infos/warnings/errors | ✅ Yes |
| Unit tests | `flutter test` | 100% pass | ✅ Yes |
| Coverage | `flutter test --coverage` | ≥ 60% domain layer | ⚠️ Warning |
| Build | `flutter build appbundle` | Successful build | ✅ Yes |

---

## 10. Bug Severity Classification

| Severity | Definition | SLA | Example |
|---|---|---|---|
| **P0 — Critical** | App crashes, data loss, auth broken | Fix within hours | Login fails for all users |
| **P1 — High** | Core flow blocked, major UX issue | Fix within 1 day | Can't create rental request |
| **P2 — Medium** | Feature partially broken, workaround exists | Fix within 3 days | Category filter not filtering |
| **P3 — Low** | Cosmetic, minor UX, edge case | Fix in next sprint | Slight padding issue on card |
