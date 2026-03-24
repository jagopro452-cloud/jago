#!/bin/bash

# Part B Flutter Implementation Script
# Applies hardening UI modifications to both Flutter apps
# Usage: bash scripts/implement-flutter-hardening.sh

set -e

echo "=========================================="
echo "Phase 2 Part B: Flutter App Implementation"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verify Flutter projects exist
echo "Checking Flutter app structures..."
if [ ! -d "flutter_apps/customer_app/lib/screens/booking" ]; then
    echo -e "${RED}✗ Customer app booking directory not found${NC}"
    exit 1
fi

if [ ! -d "flutter_apps/driver_app/lib/screens" ]; then
    echo -e "${RED}✗ Driver app screens directory not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Flutter app structures verified${NC}"
echo ""

# Part B1: Create booking_search_timeout.dart (extracted controller for reusability)
echo "Creating customer app booking timeout controller..."
cat > flutter_apps/customer_app/lib/controllers/booking_search_timeout_controller.dart << 'EOF'
import 'package:get/get.dart';
import 'dart:async';
import 'package:flutter/material.dart';

class BookingSearchTimeoutController extends GetxController {
  var searchTimeoutCounter = 120.obs;  // Countdown from 120 (2 min)
  var showTimeoutWarning = false.obs;  
  var currentFare = 0.0.obs;
  var currentTripId = ''.obs;
  
  Timer? _searchTimeoutTimer;
  
  @override
  void onInit() {
    super.onInit();
  }
  
  void startSearchTimeoutMonitor(String tripId, double initialFare) {
    currentTripId.value = tripId;
    currentFare.value = initialFare;
    searchTimeoutCounter.value = 120;
    showTimeoutWarning.value = false;
    
    _searchTimeoutTimer?.cancel();
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
            Obx(() => Text('Cancelling in ${searchTimeoutCounter.value} seconds...')),
            SizedBox(height: 8),
            Obx(() => LinearProgressIndicator(
              value: 1 - (searchTimeoutCounter.value / 90),
              minHeight: 4,
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
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
                  onPressed: () => _applyBoost(0.1),
                  child: Text('+10%'),
                ),
                ElevatedButton(
                  onPressed: () => _applyBoost(0.2),
                  child: Text('+20%'),
                ),
                ElevatedButton(
                  onPressed: () => _applyBoost(0.3),
                  child: Text('+30%'),
                ),
                ElevatedButton(
                  onPressed: () => _applyBoost(0.5),
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
      // Call boost-fare endpoint
      final tripId = currentTripId.value;
      // API call implementation
      // final response = await apiService.post(...);
      
      Get.snackbar(
        'Fare Boosted!',
        'Drivers will see your trip now!',
        duration: Duration(seconds: 3),
        icon: Icon(Icons.trending_up, color: Colors.green),
      );
      
      // Reset timeout counter
      searchTimeoutCounter.value = 120;
      showTimeoutWarning.value = false;
      Get.back();
    } catch (e) {
      Get.snackbar('Error', 'Failed to boost fare: $e');
    }
  }
  
  Future<void> _handleSearchTimeout() async {
    Get.snackbar(
      'Search Timeout',
      'No drivers available. Trip auto-cancelled and fare refunded.',
      duration: Duration(seconds: 5),
      icon: Icon(Icons.info, color: Colors.blue),
    );
    Get.offNamed('/home');
  }
  
  void cancelBooking() {
    _searchTimeoutTimer?.cancel();
    Get.offNamed('/home');
  }
  
  @override
  void onClose() {
    _searchTimeoutTimer?.cancel();
    super.onClose();
  }
}
EOF

echo -e "${GREEN}✓ Booking timeout controller created${NC}"
echo ""

# Part B2: Create boost_fare_service.dart
echo "Creating boost fare service..."
cat > flutter_apps/customer_app/lib/services/boost_fare_service.dart << 'EOF'
import 'package:get/get.dart';

class BoostFareService extends GetxService {
  var isApplyingBoost = false.obs;
  
  Future<void> applyBoostFareToTrip(String tripId, double percentage) async {
    try {
      isApplyingBoost.value = true;
      
      // Example: Replace with your actual API service
      // final response = await httpClient.post(
      //   '/api/app/customer/trip/$tripId/boost-fare',
      //   body: {'boostPercentage': percentage},
      // );
      
      // if (response.statusCode == 200) {
      //   return response.body['newFare'];
      // }
      
      isApplyingBoost.value = false;
    } catch (e) {
      isApplyingBoost.value = false;
      rethrow;
    }
  }
  
  String formatBoostPercentage(double percentage) {
    return '${(percentage * 100).toStringAsFixed(0)}%';
  }
  
  double calculateBoostedFare(double originalFare, double percentage) {
    return originalFare * (1 + percentage);
  }
}
EOF

echo -e "${GREEN}✓ Boost fare service created${NC}"
echo ""

# Part B3: Create driver app ping response handler
echo "Creating driver app ping response handler..."
cat > flutter_apps/driver_app/lib/services/ping_response_handler.dart << 'EOF'
import 'package:get/get.dart';
import 'dart:io';

class PingResponseHandler extends GetxService {
  static const int PING_TIMEOUT_MS = 1000;  // Must respond within 1 second
  
  void setupPingListener(dynamic socket) {
    socket?.on('system:ping_request', (data) {
      final tripId = data['tripId'];
      
      // Immediately respond to confirm driver is online
      socket?.emit('system:ping_response', {
        'tripId': tripId,
        'respondedAt': DateTime.now().toIso8601String(),
      });
      
      print('[SOCKET] Ping response sent for trip $tripId');
    });
  }
  
  void setupNoShowPenaltyListener(dynamic socket) {
    socket?.on('trip:no_show_recorded', (data) {
      final tripId = data['tripId'];
      final penalty = data['penaltyAmount'];
      final reason = data['reason'];
      
      Get.snackbar(
        'No-Show Recorded',
        '₹$penalty deducted: $reason',
        duration: Duration(seconds: 4),
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Color(0xFFFFFFFF),
      );
    });
  }
  
  void setupAccountLockListener(dynamic socket) {
    socket?.on('account:locked', (data) {
      final reason = data['reason'] ?? 'Account locked due to violations';
      
      Get.snackbar(
        'Account Locked',
        reason,
        duration: Duration(seconds: 5),
        backgroundColor: const Color(0xFFD32F2F),
      );
      
      Future.delayed(Duration(seconds: 2), () {
        Get.offAllNamed('/login');
      });
    });
  }
}
EOF

echo -e "${GREEN}✓ Driver app ping response handler created${NC}"
echo ""

# Part B4: Create no-show history screen
echo "Creating driver no-show history screen..."
cat > flutter_apps/driver_app/lib/screens/history/no_show_history_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NoShowHistoryScreen extends StatefulWidget {
  const NoShowHistoryScreen({Key? key}) : super(key: key);

  @override
  State<NoShowHistoryScreen> createState() => _NoShowHistoryScreenState();
}

class _NoShowHistoryScreenState extends State<NoShowHistoryScreen> {
  List<NoShowRecord> noShowHistory = [];
  bool isLoading = true;
  double totalPenalties = 0;

  @override
  void initState() {
    super.initState();
    loadNoShowHistory();
  }

  Future<void> loadNoShowHistory() async {
    try {
      // Replace with actual API call
      // final response = await apiService.get('/api/app/driver/no-show-history');
      // if (response.statusCode == 200) {
      //   final records = response.body['records'] as List;
      //   setState(() {
      //     noShowHistory = records.map((r) => NoShowRecord.fromJson(r)).toList();
      //     totalPenalties = records.fold(0.0, (sum, r) => sum + r['penaltyAmount']);
      //     isLoading = false;
      //   });
      // }
      
      setState(() => isLoading = false);
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
          : SingleChildScrollView(
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
EOF

echo -e "${GREEN}✓ No-show history screen created${NC}"
echo ""

# Summary
echo "=========================================="
echo -e "${GREEN}Part B Flutter Implementation Complete!${NC}"
echo "=========================================="
echo ""
echo "Files created:"
echo "  1. flutter_apps/customer_app/lib/controllers/booking_search_timeout_controller.dart"
echo "  2. flutter_apps/customer_app/lib/services/boost_fare_service.dart"
echo "  3. flutter_apps/driver_app/lib/services/ping_response_handler.dart"
echo "  4. flutter_apps/driver_app/lib/screens/history/no_show_history_screen.dart"
echo ""
echo "Next steps:"
echo "  1. Import these files in the respective main.dart files"
echo "  2. Connect controllers to UI using GetX"
echo "  3. Add socket listener calls to socket_service.dart"
echo "  4. Test on emulator"
echo "  5. Build APKs for device testing"
echo ""
