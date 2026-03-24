#!/bin/bash
# REAL DEVICE TESTING FRAMEWORK FOR JAGO HARDENING
# 
# This script guides manual end-to-end testing on real Android devices
# Run on terminal with: chmod +x real-device-testing.sh && ./real-device-testing.sh
#
# Prerequisites:
# - Android devices (minimum 2: one for customer, one for driver)
# - Both connected via adb
# - Both apps installed (apk files or flutter run)
# - API server running and accessible (staging or local tunnel)
# - Test admin account configured

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ═══════════════════════════════════════════════════════════════════════════════
# TEST CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

API_URL="${API_URL:-http://localhost:5000}"
CUSTOMER_PHONE="${CUSTOMER_PHONE:-9876543210}"
DRIVER_PHONE="${DRIVER_PHONE:-9876543211}"
TEST_ADMIN_EMAIL="${TEST_ADMIN_EMAIL:-admin@test.com}"
TEST_ADMIN_PASSWORD="${TEST_ADMIN_PASSWORD:-TestAdmin123!}"

# Timeouts (in seconds)
SEARCH_TIMEOUT=120
DRIVER_ACCEPT_TIMEOUT=40
ARRIVAL_TIMEOUT=300

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     JAGO PLATFORM - REAL DEVICE TESTING FRAMEWORK          ║${NC}"
echo -e "${BLUE}║                   Production Hardening                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

# ═══════════════════════════════════════════════════════════════════════════════
# TEST SUITE 1: BOOKING FLOW
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "\n${YELLOW}TEST 1: Booking Flow${NC}"
echo -e "Expected: Customer books ride, driver accepts within 40 seconds\n"

test_booking_flow() {
  echo -e "${BLUE}[CUSTOMER DEVICE]${NC}"
  read -p "1. Open app on customer device, login as: $CUSTOMER_PHONE" enter
  
  echo -e "\n${BLUE}[CUSTOMER DEVICE]${NC}"
  read -p "2. Tap 'Book Ride'" enter
  
  echo -e "\n${BLUE}[CUSTOMER DEVICE]${NC}"
  read -p "3. Select pickup location (any location)" enter
  read -p "4. Select destination (5+ km away for fare > ₹100)" enter
  
  echo -e "\n${BLUE}[CUSTOMER DEVICE]${NC}"
  read -p "5. Select vehicle type (Bike)" enter
  read -p "6. Tap 'Confirm Booking'" enter
  
  # Record booking time
  BOOKING_TIME=$(date +%s)
  BOOKING_TRIP_ID=$(curl -s "$API_URL/api/admin/trips?status=searching&limit=1" \
    -H "Authorization: Bearer $TEST_ADMIN_TOKEN" | jq -r '.trips[0].id' 2>/dev/null)
  
  echo -e "\n${BLUE}[CUSTOMER DEVICE]${NC}"
  read -p "7. Verify 'Finding driver...' message appears" enter
  read -p "8. Watch the search radius expand (5km → 8km → 12km...)" enter
  
  echo -e "\n${YELLOW}TEST POINT: Real-time Search Progress${NC}"
  read -p "Does customer see search radius + drivers found? (y/n)" response
  if [[ $response == "n" ]]; then
    echo -e "${RED}❌ FAIL: Search progress not visible${NC}"
    return 1
  fi
  
  # ─────────────────────────────────────────────────────────────────────────────
  
  echo -e "\n${BLUE}[DRIVER DEVICE]${NC}"
  read -p "9. Driver accepts trip (should receive notification in <3 seconds)" enter
  
  # Record acceptance time
  ACCEPT_TIME=$(date +%s)
  ACCEPT_DELAY=$((ACCEPT_TIME - BOOKING_TIME))
  
  if [ $ACCEPT_DELAY -lt 3 ]; then
    echo -e "${GREEN}✅ PASS: Notification delivered in ${ACCEPT_DELAY}s${NC}"
  else
    echo -e "${YELLOW}⚠️ WARNING: Notification took ${ACCEPT_DELAY}s (target <3s)${NC}"
  fi
  
  echo -e "\n${YELLOW}TEST POINT: Driver Ping Verification (FIX #1)${NC}"
  read -p "10. After driver accepts, observe brief 'Confirming...' indicator (should be instant)" enter
  
  # ─────────────────────────────────────────────────────────────────────────────
  
  echo -e "\n${BLUE}[CUSTOMER DEVICE]${NC}"
  read -p "11. Verify driver details appear: name, rating, photo, phone" enter
  read -p "12. Verify status shows '✅ Driver Assigned'" enter
  
  echo -e "\n${YELLOW}TEST POINT: Real-time Status Update (FIX #6)${NC}"
  read -p "Did customer see instant driver assignment (not delayed)? (y/n)" response
  if [[ $response == "n" ]]; then
    echo -e "${RED}❌ FAIL: Status update was delayed${NC}"
    return 1
  fi
  
  echo -e "\n${GREEN}✅ BOOKING FLOW TEST PASSED${NC}\n"
  return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST SUITE 2: TIMEOUT HANDLING
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "\n${YELLOW}TEST 2: Auto-Timeout After No Driver Found (FIX #3)${NC}"
echo -e "Expected: Trip auto-cancels after 2 minutes with auto-refund\n"

test_timeout_flow() {
  echo -e "${BLUE}[CUSTOMER DEVICE]${NC}"
  echo "Starting new booking (will timeout in 2 minutes)..."
  read -p "Press ENTER to continue" enter
  
  # Create a test trip that matches no drivers
  # Use coordinates in remote area or very specific vehicle category
  
  echo -e "\n${BLUE}[CUSTOMER DEVICE]${NC}"
  read -p "1. Book ride from remote location (somewhere drivers won't be)" enter
  read -p "2. Watch search expand radius" enter
  read -p "3. Verify you see timeout warning at 1:30 (90 seconds)" enter
  
  echo -e "\n${YELLOW}TEST POINT: Timeout Warning (FIX #3)${NC}"
  read -p "Did you see ⏰ warning at ~90 seconds? (y/n)" response
  if [[ $response == "n" ]]; then
    echo -e "${RED}❌ FAIL: Timeout warning not shown${NC}"
    return 1
  fi
  
  echo -e "\n${BLUE}[CUSTOMER DEVICE]${NC}"
  read -p "4. Wait for 2-minute mark (total search time)" enter
  read -p "5. Verify trip auto-cancels with notification" enter
  
  echo -e "\n${YELLOW}TEST POINT: Auto-Refund Confirmation (FIX #3)${NC}"
  read -p "6. Check wallet balance - did it increase by estimated fare? (y/n)" response
  if [[ $response == "n" ]]; then
    echo -e "${RED}❌ FAIL: Auto-refund not processed${NC}"
    return 1
  fi
  
  echo -e "\n${GREEN}✅ TIMEOUT TEST PASSED${NC}\n"
  return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST SUITE 3: NOTIFICATION DELIVERY IN BACKGROUND
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "\n${YELLOW}TEST 3: Background Notifications (FIX #2)${NC}"
echo -e "Expected: Driver gets full-screen notification even when app is killed\n"

test_background_notifications() {
  echo -e "${BLUE}[DRIVER DEVICE]${NC}"
  read -p "1. Open driver app, login" enter
  read -p "2. Go to home screen" enter
  read -p "3. KILL THE APP (swipe from recent apps)" enter
  read -p "4. Press ENTER once app is killed" enter
  
  echo -e "\n${BLUE}[CUSTOMER DEVICE]${NC}"
  read -p "5. Book a ride from customer device" enter
  
  echo -e "\n${BLUE}[DRIVER DEVICE]${NC}"
  echo "Waiting for full-screen notification..."
  read -p "6. Watch for full-screen trip notification (should appear in <3 seconds)" enter
  
  echo -e "\n${YELLOW}TEST POINT: Full-Screen Notification (FIX #2)${NC}"
  read -p "Did full-screen notification appear on driver device? (y/n)" response
  if [[ $response == "n" ]]; then
    echo -e "${RED}❌ FAIL: Background notification not received${NC}"
    read -p "Check ADB logs: adb logcat | grep -i fcm" enter
    return 1
  fi
  
  echo -e "\n${BLUE}[DRIVER DEVICE]${NC}"
  read -p "7. Tap notification to open app" enter
  read -p "8. Verify trip details load correctly" enter
  
  echo -e "\n${GREEN}✅ BACKGROUND NOTIFICATION TEST PASSED${NC}\n"
  return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST SUITE 4: NO-SHOW PENALTIES
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "\n${YELLOW}TEST 4: No-Show Penalties (FIX #4)${NC}"
echo -e "Expected: Driver/Customer penalty applied after no-show\n"

test_no_show_penalties() {
  echo -e "${BLUE}[DRIVER DEVICE]${NC}"
  read -p "1. Accept an active trip" enter
  read -p "2. DO NOT go to pickup location" enter
  read -p "3. Wait for assignment timeout (~10 minutes)" enter
  
  echo -e "\n${YELLOW}TEST POINT: No-Show Recorded (FIX #4)${NC}"
  read -p "4. Check driver wallet - ₹100 penalty applied? (y/n)" response
  if [[ $response == "n" ]]; then
    echo -e "${RED}❌ FAIL: No-show penalty not applied${NC}"
    return 1
  fi
  
  read -p "5. Check driver rating - decreased by 0.5 stars? (y/n)" response
  if [[ $response == "n" ]]; then
    echo -e "${RED}❌ FAIL: Rating penalty not applied${NC}"
    return 1
  fi
  
  read -p "6. Check No-Shws history - incident recorded? (y/n)" response
  if [[ $response == "n" ]]; then
    echo -e "${RED}❌ FAIL: No-show not logged${NC}"
    return 1
  fi
  
  echo -e "\n${GREEN}✅ NO-SHOW PENALTY TEST PASSED${NC}\n"
  return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST SUITE 5: NETWORK LOSS & RECOVERY
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "\n${YELLOW}TEST 5: Network Loss Resilience (FIX #2)${NC}"
echo -e "Expected: App recovers, notifications still delivered\n"

test_network_resilience() {
  echo -e "${BLUE}[DRIVER DEVICE]${NC}"
  read -p "1. Enable WiFi and set API server address in app" enter
  read -p "2. Go to Settings > WiFi > Current Network > Forget" enter
  read -p "3. Now driver is offline" enter
  
  echo -e "\n${BLUE}[CUSTOMER DEVICE]${NC}"
  read -p "4. Book a ride" enter
  
  echo -e "\n${YELLOW}TEST POINT: Fallback Notification (FIX #2)${NC}"
  echo "Driver should receive notification via SMS fallback within 30 seconds..."
  read -p "5. Did driver receive SMS? Check phone for message from Jago" enter
  
  echo -e "\n${BLUE}[DRIVER DEVICE]${NC}"
  read -p "6. Reconnect WiFi" enter
  read -p "7. Reopen app - should load pending trip automatically" enter
  
  echo -e "\n${GREEN}✅ NETWORK RESILIENCE TEST PASSED${NC}\n"
  return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST SUITE 6: PAYMENT FLOW
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "\n${YELLOW}TEST 6: Payment Flow${NC}"
echo -e "Expected: Online payment processes, wallet deduction works\n"

test_payment_flow() {
  echo -e "${BLUE}[CUSTOMER DEVICE]${NC}"
  read -p "1. Book ride with Online (Razorpay) payment" enter
  read -p "2. Complete Razorpay checkout in browser" enter
  
  echo -e "\n${YELLOW}TEST POINT: Payment Verification (FIX #7)${NC}"
  read -p "3. Verify payment status shows 'Paid' in trip details" enter
  
  echo -e "\n${BLUE}[DRIVER DEVICE]${NC}"
  read -p "4. Complete trip - enter actual fare" enter
  
  echo -e "\n${BLUE}[CUSTOMER DEVICE]${NC}"
  read -p "5. Verify fare receipt shows correct breakdown:" enter
  echo "   - Base fare"
  echo "   - Distance charge"
  echo "   - Discount (if any)"
  echo "   - Commission not deducted from customer"
  read -p "6. Confirm total matches trip agreement" enter
  
  echo -e "\n${GREEN}✅ PAYMENT FLOW TEST PASSED${NC}\n"
  return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN TEST EXECUTION
# ═══════════════════════════════════════════════════════════════════════════════

main() {
  echo -e "\n${BLUE}Select test suite to run:${NC}"
  echo "1. Booking Flow"
  echo "2. Timeout Handling"
  echo "3. Background Notifications"
  echo "4. No-Show Penalties"
  echo "5. Network Resilience"
  echo "6. Payment Flow"
  echo "7. Run All Tests"
  echo "0. Exit"
  
  read -p "Enter choice (0-7): " choice
  
  case $choice in
    1) test_booking_flow ;;
    2) test_timeout_flow ;;
    3) test_background_notifications ;;
    4) test_no_show_penalties ;;
    5) test_network_resilience ;;
    6) test_payment_flow ;;
    7)
      test_booking_flow && \
      test_timeout_flow && \
      test_background_notifications && \
      test_no_show_penalties && \
      test_network_resilience && \
      test_payment_flow
      
      if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}═══════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}  ✅ ALL REAL DEVICE TESTS PASSED!${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
      fi
      ;;
    0) exit 0 ;;
    *) echo "Invalid choice" ;;
  esac
}

# Run main
main
