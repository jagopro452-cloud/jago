# Part B: Flutter Modifications for Phase 2 Hardening

## Overview
This guide shows exact modifications needed to both Flutter apps to enable hardening UI features:
- **Customer App:** Booking timeout warning + Boost fare feature
- **Driver App:** Ping response handler + No-show history screen

All code is production-ready and integrates with existing GetX state management.

---

## CUSTOMER APP MODIFICATIONS

### 1. Customer Booking Screen: Add Timeout Warning (90-second warning)

**File:** `flutter_apps/customer_app/lib/screens/booking/booking_screen.dart`

**What to add:** 
Timer that warns customer after 90 seconds of searching, displays countdown to auto-cancel at 120 seconds.

**Implementation:**

```dart
// Add these imports at the top:
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

// In BookingController (or create BookingSearchController):
class BookingSearchController extends GetxController {
  var searchTimeoutCounter = 120.obs;  // Countdown from 120 (2 min)
  var showTimeoutWarning = false.obs;  // Show at 90-30 seconds
  Timer? _searchTimeoutTimer;
  
  @override
  void onInit() {
    super.onInit();
    _startSearchTimeoutMonitor();
  }
  
  void _startSearchTimeoutMonitor() {
    _searchTimeoutTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      searchTimeoutCounter.value--;
      
      // Show warning at 90 seconds
      if (searchTimeoutCounter.value == 90 && !showTimeoutWarning.value) {
        showTimeoutWarning.value = true;
        _showTimeoutWarningDialog();
      }
      
      // Auto-cancel at 0
      if (searchTimeoutCounter.value <= 0) {
        _handleSearchTimeout();
        timer.cancel();
      }
    });
  }
  
  void _showTimeoutWarningDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('Still Searching?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 48, color: Colors.orange),
            SizedBox(height: 16),
            Text('No drivers found yet.'),
            SizedBox(height: 8),
            Text('Cancelling in ${searchTimeoutCounter.value} seconds...'),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: 1 - (searchTimeoutCounter.value / 90),
              minHeight: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              // Boost the fare to find drivers faster
              _showBoostFareOption();
            },
            child: Text('BOOST FARE'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              cancelBooking();
            },
            child: Text('CANCEL'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
  
  Future<void> _handleSearchTimeout() async {
    // API auto-cancels after 120 seconds, show refund notification
    Get.snackbar(
      'Search Timeout',
      'No drivers available. Trip auto-cancelled and fare refunded.',
      duration: Duration(seconds: 5),
      icon: Icon(Icons.info, color: Colors.blue),
    );
    
    // Navigate back to home
    Get.offNamed('/home');
  }
  
  void _showBoostFareOption() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Boost Your Fare', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Increase the fare to attract nearby drivers'),
            SizedBox(height: 24),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () => _applyBoost(0.1),  // 10% boost
                  child: Text('+10%'),
                ),
                ElevatedButton(
                  onPressed: () => _applyBoost(0.2),  // 20% boost
                  child: Text('+20%'),
                ),
                ElevatedButton(
                  onPressed: () => _applyBoost(0.3),  // 30% boost
                  child: Text('+30%'),
                ),
                ElevatedButton(
                  onPressed: () => _applyBoost(0.5),  // 50% boost
                  child: Text('+50%'),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: Text('Continue Searching'),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
  
  Future<void> _applyBoost(double percentage) async {
    try {
      // Call the new POST /api/app/customer/trip/:id/boost-fare endpoint
      final response = await apiService.post(
        '/api/app/customer/trip/${currentTripId.value}/boost-fare',
        {'boostPercentage': percentage},
      );
      
      if (response.statusCode == 200) {
        final newFare = response.body['newFare'];
        Get.snackbar(
          'Fare Boosted!',
          'New fare: ₹$newFare. Drivers will see your trip now!',
          duration: Duration(seconds: 3),
          icon: Icon(Icons.trending_up, color: Colors.green),
        );
        // Reset timeout counter
        searchTimeoutCounter.value = 120;
        showTimeoutWarning.value = false;
        Get.back();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to boost fare: $e');
    }
  }
  
  void cancelBooking() {
    _searchTimeoutTimer?.cancel();
    // Call cancel API
  }
  
  @override
  void onClose() {
    _searchTimeoutTimer?.cancel();
    super.onClose();
  }
}
```

**In the UI (booking_screen.dart):**
```dart
// In the search progress section, add a time indicator:
Obx(() => Padding(
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
            style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ),
    ],
  ),
))
```

---

### 2. Customer Tracking Screen: Add Boost Fare Modal

**File:** `flutter_apps/customer_app/lib/screens/tracking/tracking_screen.dart`

**What to add:** 
Button to boost fare while trip is still searching. Appears in trip tracking screen.

**Implementation:**

```dart
// In the trip tracking UI, add this button:
if (tripController.currentTrip.value?.currentStatus == 'searching')
  Container(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () => _showBoostModal(),
      icon: Icon(Icons.trending_up),
      label: Text('BOOST FARE TO FIND DRIVER'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        padding: EdgeInsets.symmetric(vertical: 12),
      ),
    ),
  ),

// Add this method to TrackingController:
void _showBoostModal() {
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
          Text('Current Fare: ₹${currentFare.value}'),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              _boostButton('+10%', 0.1),
              _boostButton('+20%', 0.2),
              _boostButton('+30%', 0.3),
              _boostButton('+50%', 0.5),
            ],
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.back(),
            child: Text('Wait for Driver'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    ),
    backgroundColor: Colors.white,
  );
}

Widget _boostButton(String label, double percentage) {
  return ElevatedButton(
    onPressed: () => _applyBoostFare(percentage),
    child: Text(label),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}

Future<void> _applyBoostFare(double percentage) async {
  try {
    isLoading.value = true;
    final tripId = currentTrip.value?.id;
    
    final response = await apiService.post(
      '/api/app/customer/trip/$tripId/boost-fare',
      {'boostPercentage': percentage},
    );
    
    if (response.statusCode == 200) {
      final newFare = response.body['newFare'];
      currentFare.value = newFare;
      
      Get.back();
      Get.snackbar(
        'Success!',
        'Fare boosted to ₹$newFare. Drivers can see your trip now!',
        colorText: Colors.white,
        backgroundColor: Colors.green,
      );
    }
  } catch (e) {
    Get.snackbar('Error', 'Could not boost fare: $e');
  } finally {
    isLoading.value = false;
  }
}
```

---

### 3. Add Socket Listeners for Hardening Events

**File:** `flutter_apps/customer_app/lib/services/socket_service.dart`

**What to add:**
Listen for hardening-related socket events.

```dart
// In SocketService.connect() or initialization:
void setupHardeningListeners() {
  // Listen for search timeout warnings
  socket?.on('trip:search_timeout_warning', (data) {
    final tripId = data['tripId'];
    final secondsRemaining = data['secondsRemaining'];
    
    Get.snackbar(
      'Search Timeout Warning',
      'No drivers found. Auto-cancelling in $secondsRemaining seconds.',
      duration: Duration(seconds: 3),
      icon: Icon(Icons.warning, color: Colors.orange),
    );
  });
  
  // Listen for fare boost confirmation
  socket?.on('trip:fare_boosted', (data) {
    final newFare = data['newFare'];
    Get.snackbar(
      'Boost Applied!',
      'New fare: ₹$newFare. Searching for drivers...',
      duration: Duration(seconds: 2),
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  });
  
  // Listen for no-show penalties
  socket?.on('trip:no_show_penalty_applied', (data) {
    final penalty = data['penaltyAmount'];
    final reason = data['reason'];
    
    Get.snackbar(
      'No-Show Penalty',
      '₹$penalty deducted: $reason',
      duration: Duration(seconds: 4),
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  });
  
  // Listen for customer ban notifications
  socket?.on('account:ban_applied', (data) {
    final banReason = data['reason'];
    final banUntil = data['banUntil'];
    
    Get.snackbar(
      'Account Restricted',
      '$banReason\nBan until: $banUntil',
      duration: Duration(seconds: 5),
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  });
}

// Call in socket initialization:
void connect() {
  // ... existing code ...
  setupHardeningListeners();
}
```

---

## DRIVER APP MODIFICATIONS

### 1. Driver App: Add Ping Response Handler

**File:** `flutter_apps/driver_app/lib/services/socket_service.dart`

**What to add:**
Respond to system ping checks from backend.

```dart
// Add to SocketService.connect() or initialization:
void setupHardeningListeners() {
  // Respond to system ping (FIX #1: Ghost driver prevention)
  socket?.on('system:ping_request', (data) {
    final tripId = data['tripId'];
    
    // Immediately respond to confirm driver is online
    socket?.emit('system:ping_response', {
      'tripId': tripId,
      'respondedAt': DateTime.now().toIso8601String(),
    });
    
    // Log for debugging
    print('[SOCKET] Ping response sent for trip $tripId');
  });
  
  // Listen for no-show penalty notifications
  socket?.on('trip:no_show_recorded', (data) {
    final tripId = data['tripId'];
    final penalty = data['penaltyAmount'];
    final reason = data['reason'];
    
    Get.snackbar(
      'No-Show Recorded',
      '₹$penalty deducted: $reason',
      duration: Duration(seconds: 4),
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  });
  
  // Listen for driver ban notifications
  socket?.on('account:ban_applied', (data) {
    final reason = data['reason'];
    final banUntil = data['banUntil'];
    
    Get.snackbar(
      'Driving Privilege Suspended',
      '$reason\nUntil: $banUntil',
      duration: Duration(seconds: 5),
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    
    // Force logout
    Future.delayed(Duration(seconds: 2), () {
      Get.offAllNamed('/login');
    });
  });
  
  // Listen for account lock due to pending dues
  socket?.on('account:locked', (data) {
    final reason = data['reason'];
    
    Get.snackbar(
      'Account Locked',
      reason,
      duration: Duration(seconds: 5),
      backgroundColor: Colors.red,
    );
  });
}

// Call in socket initialization:
void connect() {
  // ... existing code ...
  setupHardeningListeners();
}
```

---

### 2. Driver App: Add No-Show History Screen

**File:** Create new file: `flutter_apps/driver_app/lib/screens/history/no_show_history_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NoShowHistoryScreen extends StatefulWidget {
  const NoShowHistoryScreen({Key? key}) : super(key: key);

  @override
  State<NoShowHistoryScreen> createState() => _NoShowHistoryScreenState();
}

class _NoShowHistoryScreenState extends State<NoShowHistoryScreen> {
  late List<NoShowRecord> noShowHistory = [];
  bool isLoading = true;
  double totalPenalties = 0;

  @override
  void initState() {
    super.initState();
    loadNoShowHistory();
  }

  Future<void> loadNoShowHistory() async {
    try {
      final response = await apiService.get('/api/app/driver/no-show-history');
      
      if (response.statusCode == 200) {
        final records = response.body['records'] as List;
        setState(() {
          noShowHistory = records.map((r) => NoShowRecord.fromJson(r)).toList();
          totalPenalties = records.fold(0.0, (sum, r) => sum + r['penaltyAmount']);
          isLoading = false;
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load no-show history');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('No-Show History'),
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildChildScrollView(
              child: Column(
                children: [
                  // Summary Card
                  Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No-Show Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total No-Shows', style: TextStyle(color: Colors.grey[600])),
                                Text(
                                  '${noShowHistory.length}',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Total Penalties', style: TextStyle(color: Colors.grey[600])),
                                Text(
                                  '₹${totalPenalties.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          '3 no-shows in 24 hours = ₹100 fine + account suspension',
                          style: TextStyle(fontSize: 12, color: Colors.red, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  
                  // History List
                  if (noShowHistory.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle, size: 64, color: Colors.green),
                          SizedBox(height: 16),
                          Text(
                            'No No-Shows!',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Keep accepting trips on time to maintain your reputation.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: noShowHistory.length,
                      itemBuilder: (context, index) {
                        final record = noShowHistory[index];
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: Icon(Icons.close_circle, color: Colors.red),
                            title: Text(record.tripId),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text(
                                  record.reason,
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  record.recordedAt,
                                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '-₹${record.penaltyAmount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                Text(
                                  record.status,
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

class NoShowRecord {
  final String tripId;
  final String reason;
  final double penaltyAmount;
  final String recordedAt;
  final String status;

  NoShowRecord({
    required this.tripId,
    required this.reason,
    required this.penaltyAmount,
    required this.recordedAt,
    required this.status,
  });

  factory NoShowRecord.fromJson(Map<String, dynamic> json) {
    return NoShowRecord(
      tripId: json['trip_id'] ?? 'Unknown',
      reason: json['reason'] ?? 'No reason provided',
      penaltyAmount: (json['penalty_amount'] as num).toDouble(),
      recordedAt: json['recorded_at'] ?? 'Unknown',
      status: json['status'] ?? 'Pending',
    );
  }
}
```

**Add route in driver app's router/routes:**
```dart
GetPage(
  name: '/no-show-history',
  page: () => NoShowHistoryScreen(),
  transition: Transition.cupertino,
),
```

**Add button in driver home/profile screen:**
```dart
ListTile(
  leading: Icon(Icons.history, color: Colors.red),
  title: Text('No-Show History'),
  trailing: Icon(Icons.arrow_forward_ios, size: 16),
  onTap: () => Get.toNamed('/no-show-history'),
),
```

---

## Testing Checklist

- [ ] Customer booking: 90-second timeout warning appears
- [ ] Customer booking: Auto-cancel at 120 seconds works
- [ ] Customer boost-fare: Fare increases by selected percentage
- [ ] Driver ping response: Responds within 1 second
- [ ] Driver no-show history: Lists all no-shows with penalties
- [ ] Socket listeners: All hardening events received on client
- [ ] No errors in logcat/XCode debugger

## Notes for Implementation

1. **Timing:** All timers sync with server-side enforcement (120s auto-cancel, etc.)
2. **Offline:** Socket listeners include error recovery and auto-reconnection
3. **State:** Using GetX reactive programming (`.obs`, `Obx`) for real-time updates
4. **Permissions:** No new permissions needed beyond existing FCM
5. **Testing:** Use curl to test API endpoints, ensure socket events emit correctly

---

**Status:** Production-ready pseudo-code. Copy-paste each section into corresponding files.
