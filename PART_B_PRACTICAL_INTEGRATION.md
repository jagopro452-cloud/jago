# Part B: Practical Integration Checklist

## Pre-Integration Setup

### 1. Backup Current Code
```bash
git status
git add -A
git commit -m "Before Phase 2 Part B Flutter modifications"
git branch -b part-b-flutter-work
```

### 2. Verify File Locations

```bash
# Customer app files
ls -la flutter_apps/customer_app/lib/screens/booking/booking_screen.dart
ls -la flutter_apps/customer_app/lib/screens/tracking/tracking_screen.dart
ls -la flutter_apps/customer_app/lib/services/socket_service.dart

# Driver app files  
ls -la flutter_apps/driver_app/lib/screens/history/
ls -la flutter_apps/driver_app/lib/services/socket_service.dart
ls -la flutter_apps/driver_app/lib/screens/home/home_screen.dart

# Create missing directories if needed
mkdir -p flutter_apps/customer_app/lib/controllers
mkdir -p flutter_apps/customer_app/lib/services
mkdir -p flutter_apps/driver_app/lib/screens/history
mkdir -p flutter_apps/driver_app/lib/services
```

### 3. Run Setup Script

```bash
bash scripts/implement-flutter-hardening.sh
```

Verify output:
```
✓ Booking timeout controller created
✓ Boost fare service created
✓ Driver app ping response handler created
✓ No-show history screen created
```

---

## CUSTOMER APP: Booking Timeout Integration

### Task C1: Add Timeout Controller Import to booking_controller.dart

**File:** `flutter_apps/customer_app/lib/controllers/booking_controller.dart`

**Location:** At the top with other imports

**Add:**
```dart
import 'booking_search_timeout_controller.dart';  // ← ADD THIS
```

**Verify:**
- File compiles without import errors
- IDE recognizes BookingSearchTimeoutController class

---

### Task C2: Initialize Timeout Controller in Booking Flow

**File:** `flutter_apps/customer_app/lib/controllers/booking_controller.dart`

**Location:** In the main BookingController class

**Find this method:**
```dart
Future<void> bookRide({
  required String pickupLocation,
  required String dropLocation,
  required double estimatedFare,
  // ... other params
}) async {
```

**Inside this method, AFTER the `POST /api/app/customer/book-ride` API call succeeds:**

```dart
Future<void> bookRide({
  required String pickupLocation,
  required String dropLocation,
  required double estimatedFare,
}) async {
  try {
    isLoading.value = true;
    
    final response = await apiService.post(
      '/api/app/customer/book-ride',
      {
        'pickupLocation': pickupLocation,
        'dropLocation': dropLocation,
        'estimatedFare': estimatedFare,
      },
    );
    
    if (response.statusCode == 200) {
      final trip = response.body['trip'];
      currentTripId.value = trip['id'];
      currentTripStatus.value = 'searching';
      
      // ← ADD THIS BLOCK:
      // Start timeout monitor for search
      Get.find<BookingSearchTimeoutController>().startSearchTimeoutMonitor(
        trip['id'],         // tripId
        estimatedFare,      // initialFare
      );
      // ← END BLOCK
      
      // Navigate to tracking screen
      Get.toNamed('/tracking', arguments: {'tripId': trip['id']});
    }
  } catch (e) {
    Get.snackbar('Error', 'Booking failed: $e');
  } finally {
    isLoading.value = false;
  }
}
```

**Verify:**
- [ ] Controller finds GetX service without error
- [ ] Trip ID and fare passed as parameters
- [ ] No compilation errors

---

### Task C3: Add Timeout UI to booking_screen.dart

**File:** `flutter_apps/customer_app/lib/screens/booking/booking_screen.dart`

**Location:** In the search progress section (where "Searching for drivers..." text appears)

**Find this code block:**
```dart
Padding(
  padding: EdgeInsets.all(16),
  child: Text('Searching for drivers...'),
)
```

**Replace with:**
```dart
Obx(() {
  final controller = Get.find<BookingSearchTimeoutController>();
  
  return Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        LinearProgressIndicator(
          value: 1 - (controller.searchTimeoutCounter.value / 120),
          minHeight: 6,
        ),
        SizedBox(height: 8),
        Text(
          'Searching for drivers... ${controller.searchTimeoutCounter.value}s',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        if (controller.showTimeoutWarning.value)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'No drivers nearby. Try boosting the fare!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    ),
  );
})
```

**Verify:**
- [ ] Progress bar animates 0 → 1 over 120 seconds
- [ ] Timer counts down every second
- [ ] Warning text appears at 90s
- [ ] No errors in emulator console

---

### Task C4: Handle Booking Cancellation

**File:** `flutter_apps/customer_app/lib/controllers/booking_controller.dart`

**Location:** In cancel booking method

**Find and modify:**
```dart
Future<void> cancelBooking() async {
  try {
    // ← ADD THIS:
    Get.find<BookingSearchTimeoutController>().cancelBooking();
    // ← END
    
    await apiService.post('/api/app/customer/book-ride/cancel', {
      'tripId': currentTripId.value,
    });
    
    Get.offNamed('/home');
  } catch (e) {
    Get.snackbar('Error', 'Cancel failed: $e');
  }
}
```

**Verify:**
- [ ] Timer stops when booking cancelled
- [ ] No orphaned timers in memory (check with profiler)

---

## CUSTOMER APP: Boost Fare Integration

### Task C5: Add Boost Fare Button to tracking_screen.dart

**File:** `flutter_apps/customer_app/lib/screens/tracking/tracking_screen.dart`

**Location:** In the main trip tracking UI section (after driver accepted, still searching)

**Find this section:**
```dart
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Trip Tracking')),
    body: SingleChildScrollView(
      child: Column(
        children: [
          // Map or trip details here
          
          // ← ADD BOOST BUTTON HERE:
          Obx(() {
            final trip = tripController.currentTrip.value;
            
            if (trip?.currentStatus == 'searching')
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showBoostFareModal,
                  icon: Icon(Icons.trending_up),
                  label: Text('BOOST FARE TO FIND DRIVER'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              );
            return SizedBox.shrink();
          }),
          // ← END BOOST BUTTON
        ],
      ),
    ),
  );
}
```

**Verify:**
- [ ] Button appears only when trip status is 'searching'
- [ ] Button disappears when driver accepts
- [ ] Button styling matches app design

---

### Task C6: Add Boost Fare Modal Logic

**File:** `flutter_apps/customer_app/lib/screens/tracking/tracking_screen.dart`

**Location:** Add method at end of TrackingScreen class

**Add:**
```dart
void _showBoostFareModal() {
  final currentFare = tripController.currentTrip.value?.fare ?? 0.0;
  
  Get.bottomSheet(
    Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, size: 48, color: Colors.amber),
          SizedBox(height: 16),
          Text(
            'Boost Your Fare',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'No driver accepted yet. Increase the fare to attract nearby drivers.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Text(
            'Current Fare: ₹${currentFare.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildBoostButton('+10%', 0.1, currentFare),
              _buildBoostButton('+20%', 0.2, currentFare),
              _buildBoostButton('+30%', 0.3, currentFare),
              _buildBoostButton('+50%', 0.5, currentFare),
            ],
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.back(),
              child: Text('Continue Waiting'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    ),
    backgroundColor: Colors.white,
  );
}

Widget _buildBoostButton(String label, double percentage, double currentFare) {
  final newFare = currentFare * (1 + percentage);
  
  return Column(
    children: [
      ElevatedButton(
        onPressed: () => _applyBoostFare(percentage),
        child: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      Text(
        '₹${newFare.toStringAsFixed(0)}',
        style: TextStyle(fontSize: 10, color: Colors.grey),
      ),
    ],
  );
}

Future<void> _applyBoostFare(double percentage) async {
  try {
    final tripId = tripController.currentTrip.value?.id;
    
    final response = await apiService.post(
      '/api/app/customer/trip/$tripId/boost-fare',
      {'boostPercentage': percentage},
    );
    
    if (response.statusCode == 200) {
      final newFare = response.body['newFare'];
      
      // Update local state
      tripController.currentFare.value = newFare;
      
      Get.back();
      Get.snackbar(
        'Success!',
        'Fare boosted to ₹$newFare. Drivers can see your trip now!',
        colorText: Colors.white,
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      );
    }
  } catch (e) {
    Get.snackbar('Error', 'Could not boost fare: $e');
  }
}
```

**Verify:**
- [ ] Modal appears when button tapped
- [ ] Shows 4 boost percentage options
- [ ] Shows new fare for each option
- [ ] API call succeeds and returns 200
- [ ] UI updates with new fare
- [ ] Snackbar confirms success

---

### Task C7: Add Socket Listeners for Hardening Events

**File:** `flutter_apps/customer_app/lib/services/socket_service.dart`

**Location:** In the socket initialization (usually after connection established)

**Find where socket listeners are set up:**
```dart
void _setupSocketListeners() {
  socket?.on('driver_assigned', (data) {
    // handle driver assigned
  });
  
  // ← ADD HARDENING LISTENERS HERE:
  _setupHardeningListeners();
  // ← END
}

void _setupHardeningListeners() {
  // Search timeout warning
  socket?.on('trip:search_timeout_warning', (data) {
    final secondsRemaining = data['secondsRemaining'] ?? 0;
    Get.snackbar(
      'Search Timeout Warning',
      'No drivers found. Auto-cancelling in $secondsRemaining seconds.',
      duration: Duration(seconds: 3),
      icon: Icon(Icons.warning, color: Colors.orange),
    );
  });
  
  // Fare boost confirmation
  socket?.on('trip:fare_boosted', (data) {
    final newFare = data['newFare'] ?? 0.0;
    Get.snackbar(
      'Boost Applied!',
      'New fare: ₹$newFare. Searching for drivers...',
      duration: Duration(seconds: 2),
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  });
  
  // No-show penalty
  socket?.on('trip:no_show_penalty_applied', (data) {
    final penalty = data['penaltyAmount'] ?? 0.0;
    final reason = data['reason'] ?? 'Unknown reason';
    Get.snackbar(
      'No-Show Penalty',
      '₹$penalty deducted: $reason',
      duration: Duration(seconds: 4),
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  });
  
  // Account ban
  socket?.on('account:ban_applied', (data) {
    final banReason = data['reason'] ?? 'Policy violation';
    final banUntil = data['banUntil'] ?? 'Unknown';
    Get.snackbar(
      'Account Restricted',
      '$banReason\nBan until: $banUntil',
      duration: Duration(seconds: 5),
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  });
}
```

**Verify:**
- [ ] Socket listeners registered on connect
- [ ] Snackbars display for each event
- [ ] No socket errors in logcat
- [ ] Listeners persist after reconnection

---

## DRIVER APP: Ping Response Integration

### Task D1: Add Socket Listeners in driver socket_service.dart

**File:** `flutter_apps/driver_app/lib/services/socket_service.dart`

**Location:** In socket initialization

**Find where socket listeners are set up, add:**

```dart
void _setupSocketListeners() {
  socket?.on('onNewTrip', (data) {
    // existing code
  });
  
  // ← ADD HARDENING LISTENERS HERE:
  _setupHardeningListeners();
  // ← END
}

void _setupHardeningListeners() {
  // FIX #1: Respond to system ping (ghost driver prevention)
  socket?.on('system:ping_request', (data) {
    final tripId = data['tripId'] ?? 'unknown';
    
    // Immediately respond to confirm driver is online
    socket?.emit('system:ping_response', {
      'tripId': tripId,
      'respondedAt': DateTime.now().toIso8601String(),
    });
    
    print('[SOCKET] Ping response sent for trip $tripId at ${DateTime.now()}');
  });
  
  // No-show penalty notification
  socket?.on('trip:no_show_recorded', (data) {
    final tripId = data['tripId'] ?? 'Unknown';
    final penalty = data['penaltyAmount'] ?? 0.0;
    final reason = data['reason'] ?? 'No-show recorded';
    
    Get.snackbar(
      'No-Show Recorded',
      '₹$penalty deducted: $reason',
      duration: Duration(seconds: 4),
      backgroundColor: Color(0xFFD32F2F),
      colorText: Color(0xFFFFFFFF),
    );
  });
  
  // Account lock warning
  socket?.on('account:locked', (data) {
    final reason = data['reason'] ?? 'Account locked';
    
    Get.snackbar(
      'Account Locked',
      reason,
      duration: Duration(seconds: 5),
      backgroundColor: Color(0xFFD32F2F),
      colorText: Color(0xFFFFFFFF),
    );
    
    // Force logout after delay
    Future.delayed(Duration(seconds: 2), () {
      Get.offAllNamed('/login');
    });
  });
  
  // Fare update from customer boost
  socket?.on('trip:fare_updated', (data) {
    final tripId = data['tripId'] ?? 'Unknown';
    final newFare = data['newFare'] ?? 0.0;
    
    // Update current trip if matching
    if (tripController.currentTrip.value?.id == tripId) {
      tripController.currentTrip.value?.fare = newFare;
    }
    
    Get.snackbar(
      'Fare Updated!',
      'Customer boosted fare to ₹$newFare',
      duration: Duration(seconds: 2),
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  });
}
```

**Verify:**
- [ ] Ping listener logs in logcat when triggered
- [ ] Response emitted within 100ms
- [ ] Other listeners show appropriate notifications
- [ ] Account lock forces logout

---

### Task D2: Add No-Show History Navigation

**File:** `flutter_apps/driver_app/lib/screens/home/home_screen.dart` or `profile_screen.dart`

**Location:** In the main menu/profile list

**Find the menu ListTile section:**
```dart
ListView(
  children: [
    ListTile(
      leading: Icon(Icons.person),
      title: Text('Profile'),
      onTap: () => Get.toNamed('/profile'),
    ),
    // ← ADD THIS:
    ListTile(
      leading: Icon(Icons.history, color: Colors.red),
      title: Text('No-Show History'),
      subtitle: Text('View penalties and violations'),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => Get.toNamed('/no-show-history'),
    ),
    // ← END
  ],
)
```

**Verify:**
- [ ] Menu item appears in profile/home
- [ ] Tapping navigates to no-show-history screen
- [ ] Icon and text visible

---

### Task D3: Add Route for No-Show History

**File:** `flutter_apps/driver_app/lib/routes/app_routes.dart` or wherever routes are defined

**Location:** In the routes list

**Add:**
```dart
static const String noShowHistory = '/no-show-history';

GetPage(
  name: noShowHistory,
  page: () => NoShowHistoryScreen(),
  transition: Transition.cupertino,
),
```

**Verify:**
- [ ] Route compiles without errors
- [ ] Navigation works without errors

---

### Task D4: Verify No-Show History Screen File

**File:** `flutter_apps/driver_app/lib/screens/history/no_show_history_screen.dart`

**Location:** Verify created by setup script

**Check:**
```bash
ls -la flutter_apps/driver_app/lib/screens/history/no_show_history_screen.dart
```

**Modifications needed:**
1. Update API endpoint path if different:
   ```dart
   final response = await apiService.get('/api/app/driver/no-show-history');
   ```

2. Update JSON field names if different from backend:
   ```dart
   tripId: json['trip_id'] ?? 'Unknown',  // Adjust to match your JSON
   ```

3. Update color scheme to match app branding

**Verify:**
- [ ] File exists
- [ ] No import errors when opening file
- [ ] Compiles without errors

---

## Combined Testing Checklist

### Emulator Pre-Tests

Before running full flows:

```bash
# Customer app
cd flutter_apps/customer_app
flutter clean
flutter pub get
flutter analyze

# Driver app
cd ../driver_app
flutter clean
flutter pub get
flutter analyze
```

**Verify:**
- [ ] No analyzer warnings
- [ ] Zero null safety issues
- [ ] All imports resolve

---

### Test Flow 1: Customer Booking Timeout (15 mins)

**Setup:**
- Start both backend and emulators
- Log in as customer
- Backend configured with NO drivers available

**Steps:**
1. [ ] Open booking screen
2. [ ] Enter pickup and destination
3. [ ] Click "Book Ride"
4. [ ] Watch timer count down from 120
5. [ ] At 90 seconds, warning dialog should appear
6. [ ] Dialog shows "BOOST FARE" button
7. [ ] Click "BOOST FARE" in dialog
8. [ ] Select +20% boost
9. [ ] See confirmation: "Fare boosted to ₹XXX"
10. [ ] Timer continues, warning disappears
11. [ ] At 120 seconds, auto-cancel notification appears
12. [ ] Redirected to home screen

**Pass criteria:** All steps complete without errors

---

### Test Flow 2: Customer Boost During Tracking (15 mins)

**Setup:**
- Same as Flow 1, but book successfully

**Steps:**
1. [ ] After booking, tracking screen appears
2. [ ] See timer and progress bar
3. [ ] See "BOOST FARE TO FIND DRIVER" button
4. [ ] Click button
5. [ ] Bottom sheet appears with 4 options
6. [ ] Choose +30% boost
7. [ ] Button shows new fare (30% higher)
8. [ ] API call succeeds
9. [ ] Green snackbar: "Fare boosted to ₹XXX"
10. [ ] Bottom sheet closes
11. [ ] Tracking shows updated fare

**Pass criteria:** All steps complete, fare updates in tracking

---

### Test Flow 3: Driver Ping Response (20 mins)

**Setup:**
- Start driver app
- Log in as driver
- Add fake trip in backend (or use test script)

**Steps:**
1. [ ] Driver accepts outstation offer
2. [ ] Trip shown in driver app
3. [ ] Open logcat: `adb logcat | grep SOCKET`
4. [ ] Backend sends ping_request (every 5 seconds)
5. [ ] Driver app logs: `[SOCKET] Ping response sent for trip`
6. [ ] Response timestamp within 100ms of request
7. [ ] Let trip run for 60 seconds
8. [ ] Verify 12+ ping requests/responses
9. [ ] Trip still active (not ghost-cancelled)
10. [ ] No socket errors in logcat

**Pass criteria:** Ping response within 1 second, consistently

---

### Test Flow 4: Driver No-Show History (10 mins)

**Setup:**
- Driver app open
- Create 2-3 no-show records in test database (or use script)

**Steps:**
1. [ ] Go to home/profile
2. [ ] Click "No-Show History"
3. [ ] Screen loads (no errors)
4. [ ] Summary card shows:
   - [ ] Total no-shows (e.g., 2)
   - [ ] Total penalties (e.g., ₹200)
5. [ ] Below shows list of no-shows:
   - [ ] Trip ID
   - [ ] Date/time recorded
   - [ ] Reason
   - [ ] Penalty amount
6. [ ] Back button returns to previous screen
7. [ ] No crashes or ANRs

**Pass criteria:** Screen loads, data displays, no errors

---

### Test Flow 5: Socket Notifications (10 mins)

**Setup:**
- Both apps running
- Socket connected to same backend

**Steps:**

**Customer side:**
1. [ ] Book a ride
2. [ ] Socket receives search_timeout_warning at 90s
3. [ ] See snackbar: "Search Timeout Warning"
4. [ ] Boost fare
5. [ ] Socket receives fare_boosted event
6. [ ] See snackbar: "Boost Applied!"

**Driver side:**
1. [ ] Driver in trip
2. [ ] Backend sends ping_request
3. [ ] Driver responds (automatic)
4. [ ] No notification (response is transparent)
5. [ ] If no-show, receive trip:no_show_recorded
6. [ ] See snackbar: "No-Show Recorded"

**Pass criteria:** All snackbars appear correctly

---

### APK Build Test (20 mins)

```bash
# Clean builds
cd flutter_apps/customer_app
flutter clean
flutter build apk --release -v 2>&1 | tail -50

cd ../driver_app
flutter clean
flutter build apk --release -v 2>&1 | tail -50
```

**Verify:**
- [ ] No errors during build
- [ ] APK files created:
  ```bash
  ls -lh flutter_apps/customer_app/build/app/outputs/apk/release/app-release.apk
  ls -lh flutter_apps/driver_app/build/app/outputs/apk/release/app-release.apk
  ```
- [ ] APK size ~50-90 MB each
- [ ] Both APKs installable on test device

---

## Commit Strategy

After each component works:

```bash
# After C1-C3 (customer timeout)
git add flutter_apps/customer_app/lib
git commit -m "feat(flutter): Phase 2 Part B - Customer booking timeout warning"

# After C4-C6 (customer boost)
git add flutter_apps/customer_app/lib
git commit -m "feat(flutter): Phase 2 Part B - Customer boost fare feature"

# After C7 (customer socket)
git add flutter_apps/customer_app/lib
git commit -m "feat(flutter): Phase 2 Part B - Customer hardening socket listeners"

# After D1 (driver ping)
git add flutter_apps/driver_app/lib
git commit -m "feat(flutter): Phase 2 Part B - Driver ping response handler (FIX #1)"

# After D2-D4 (driver history)
git add flutter_apps/driver_app/lib
git commit -m "feat(flutter): Phase 2 Part B - Driver no-show history screen"

# After all working
git commit -m "feat(flutter): Phase 2 Part B complete - Full hardening integration"
```

---

## Troubleshooting Guide

### Issue: "BookingSearchTimeoutController not found"

**Check:**
```bash
grep -r "class BookingSearchTimeoutController" flutter_apps/
```

**Fix:**
- Run setup script again: `bash scripts/implement-flutter-hardening.sh`
- Manually create file if missing

---

### Issue: Timer fires rapidly (many times per second)

**Cause:** Multiple timer instances created

**Fix:**
```dart
// In controller init
_searchTimeoutTimer?.cancel();  // Stop any existing timer
_searchTimeoutTimer = Timer.periodic(...);  // Create new one
```

---

### Issue: Boost fare API returns 404

**Check:**
```bash
grep -n "boost-fare" server/routes.ts
```

**Location should be around line 9825-9875**

**If not found:**
- Part A integration incomplete
- Run `npm run check` in backend to verify no errors
- Manually add endpoint if missing

---

### Issue: No-show history screen shows blank

**Check:**
```bash
# Does API endpoint exist?
grep -n "no-show-history" server/routes.ts

# Does driver have no-show records?
curl -H "Authorization: Bearer <token>" http://localhost:5000/api/app/driver/no-show-history
```

**Fix:**
- Create test records in database
- Verify API returns proper JSON structure
- Check field names match screen expectations

---

### Issue: Socket listeners not working

**Check:**
1. Socket connected: `print(socket?.connected)`
2. Listeners registered: `print('Listeners set up')`
3. Backend emitting events: Check backend logs

**Fix:**
```dart
socket?.on('connect', (_) {
  print('Socket connected, setting up listeners');
  _setupHardeningListeners();
});
```

---

## Performance Checklist

Before delivery:

- [ ] Booking timeout doesn't block UI (use Timer.periodic, not Thread.sleep)
- [ ] No memory leaks (timers cancelled on exit)
- [ ] No unnecessary rebuilds (use Obx only for reactive variables)
- [ ] Socket listeners don't duplicate (check for multiple setups)
- [ ] APK size < 100MB

---

## Documentation Update

After all done:

1. Update `README.md`:
   ```markdown
   ## Phase 2 Hardening Features

   ### Customer App
   - Booking timeout warning at 90 seconds
   - Fare boost option (+10% to +50%)

   ### Driver App
   - Auto-response to system ping checks
   - No-show history and penalty tracking
   ```

2. Update `CHANGELOG.md`:
   ```
   ## [2.0.0] - Phase 2 Complete
   - Added booking timeout warning UI
   - Added boost fare feature
   - Added ping response handler (FIX #1)
   - Added no-show history screen
   ```

---

**Ready to start? Begin with Task C1 and work through sequentially.**

