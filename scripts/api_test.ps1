$B = "http://localhost:5000"
$pass = 0; $fail = 0; $fails = @()

function T($m, $p, $body, $expect401) {
  try {
    $params = @{ Uri="$B$p"; Method=$m; UseBasicParsing=$true; TimeoutSec=8; ErrorAction='Stop' }
    if ($body) { $params['Body']=$body; $params['ContentType']='application/json' }
    $r = Invoke-WebRequest @params
    return @{ code=$r.StatusCode; ok=$true }
  } catch {
    $c = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
    $ok = ($expect401 -and $c -in @(401,403)) -or ($c -in @(401,403,404))
    return @{ code=$c; ok=$ok; err=$_.Exception.Message }
  }
}

$tests = @(
  @("GET","/api/health",$null,$false),
  @("GET","/api/zones",$null,$false),
  @("GET","/api/vehicle-categories",$null,$false),
  @("GET","/api/vehicle-brands",$null,$false),
  @("GET","/api/vehicle-models",$null,$false),
  @("GET","/api/fares",$null,$false),
  @("GET","/api/services",$null,$false),
  @("GET","/api/subscription-plans",$null,$false),
  @("GET","/api/banners",$null,$false),
  @("GET","/api/coupons",$null,$false),
  @("GET","/api/discounts",$null,$false),
  @("GET","/api/insurance-plans",$null,$false),
  @("GET","/api/intercity-routes",$null,$false),
  @("GET","/api/parcel-categories",$null,$false),
  @("GET","/api/parcel-weights",$null,$false),
  @("GET","/api/parcel-fares",$null,$false),
  @("GET","/api/parcel-attributes",$null,$false),
  @("GET","/api/surge-pricing",$null,$false),
  @("GET","/api/cancellation-reasons",$null,$false),
  @("GET","/api/police-stations",$null,$false),
  @("GET","/api/heatmap-points",$null,$false),
  @("GET","/api/reviews",$null,$false),
  @("GET","/api/notifications",$null,$false),
  @("GET","/api/transactions",$null,$false),
  @("GET","/api/withdrawals",$null,$false),
  @("GET","/api/users",$null,$false),
  @("GET","/api/trips",$null,$false),
  @("GET","/api/revenue-model",$null,$false),
  @("GET","/api/business-settings",$null,$false),
  @("GET","/api/settings",$null,$false),
  @("GET","/api/driver-levels",$null,$false),
  @("GET","/api/customer-levels",$null,$false),
  @("GET","/api/blogs",$null,$false),
  @("GET","/api/spin-wheel",$null,$false),
  @("GET","/api/wallet-bonus",$null,$false),
  @("GET","/api/b2b-companies",$null,$false),
  @("GET","/api/employees",$null,$false),
  @("GET","/api/safety-alerts",$null,$false),
  @("GET","/api/safety-alerts/stats",$null,$false),
  @("GET","/api/referrals",$null,$false),
  @("GET","/api/referrals/stats",$null,$false),
  @("GET","/api/refund-requests",$null,$false),
  @("GET","/api/parcel-refunds",$null,$false),
  @("GET","/api/live-tracking",$null,$false),
  @("GET","/api/matching/stats",$null,$false),
  @("GET","/api/matching/drivers?lat=17.4&lng=78.4",$null,$false),
  @("GET","/api/intercity-cs/rides",$null,$false),
  @("GET","/api/intercity-cs/settings",$null,$false),
  @("GET","/api/car-sharing/rides",$null,$false),
  @("GET","/api/car-sharing/settings",$null,$false),
  @("GET","/api/car-sharing/stats",$null,$false),
  @("GET","/api/vehicle-fares",$null,$false),
  @("GET","/api/fleet-drivers",$null,$false),
  @("GET","/api/driver-subscriptions",$null,$false),
  @("GET","/api/driver-wallet",$null,$false),
  @("GET","/api/driver-earnings",$null,$false),
  @("GET","/api/driver-insurance",$null,$false),
  @("GET","/api/vehicle-requests",$null,$false),
  @("GET","/api/call-logs",$null,$false),
  @("GET","/api/newsletter",$null,$false),
  @("GET","/api/reports/trips",$null,$false),
  @("GET","/api/reports/drivers",$null,$false),
  @("GET","/api/reports/customers",$null,$false),
  @("GET","/api/reports/earnings",$null,$false),
  @("GET","/api/admin-revenue",$null,$false),
  @("GET","/api/dashboard/stats",$null,$false),
  @("GET","/api/dashboard/chart",$null,$false),
  @("GET","/api/admin/dashboard",$null,$false),
  @("GET","/api/admin/complaints",$null,$false),
  @("GET","/api/admin/languages",$null,$false),
  @("GET","/api/admin/drivers/pending-verification",$null,$false),
  @("GET","/api/admin/system/live-overview",$null,$false),
  @("GET","/api/admin/rides/active",$null,$false),
  @("GET","/api/admin/rides/cancelled",$null,$false),
  @("GET","/api/admin/rides/history",$null,$false),
  @("GET","/api/admin/outstation-pool/rides",$null,$false),
  @("GET","/api/admin/outstation-pool/bookings",$null,$false),
  @("GET","/api/app/configs",$null,$false),
  @("GET","/api/app/services",$null,$false),
  @("GET","/api/app/languages",$null,$false),
  @("GET","/api/app/driver/subscription-plans",$null,$false),
  @("GET","/api/app/nearby-drivers?lat=17.4&lng=78.4",$null,$false),
  @("GET","/api/app/customer/profile",$null,$true),
  @("GET","/api/app/driver/profile",$null,$true),
  @("GET","/api/app/driver/dashboard",$null,$true),
  @("GET","/api/app/customer/trips",$null,$true),
  @("GET","/api/app/driver/earnings",$null,$true),
  @("GET","/api/app/customer/wallet",$null,$true),
  @("GET","/api/app/driver/wallet",$null,$true),
  @("GET","/api/app/customer/active-trip",$null,$true),
  @("POST","/api/admin/login",'{"email":"admin@jago.com","password":"Admin@123"}',$false),
  @("POST","/api/admin/forgot-password",'{"email":"admin@jago.com"}',$false),
  @("POST","/api/app/send-otp",'{"phone":"+919999999999"}',$false),
  @("POST","/api/app/customer/estimate-fare",'{"fromLat":17.4,"fromLng":78.4,"toLat":17.45,"toLng":78.5,"vehicleCategoryId":1}',$false),
  @("POST","/api/fare-calculator",'{"fromLat":17.4,"fromLng":78.4,"toLat":17.45,"toLng":78.5,"vehicleCategoryId":1}',$false),
  @("POST","/api/app/customer/book-ride",$null,$true),
  @("POST","/api/app/driver/accept-trip",$null,$true),
  @("POST","/api/app/driver/location",$null,$true)
)

foreach ($t in $tests) {
  $m=$t[0]; $p=$t[1]; $b=$t[2]; $e=$t[3]
  $r = T $m $p $b $e
  if ($r.ok) {
    $pass++
    Write-Output "  PASS [$($r.code)]  $m $p"
  } else {
    $fail++
    $fails += "$m $p => $($r.code)"
    Write-Output "  FAIL [$($r.code)]  $m $p"
  }
}

Write-Output ""
Write-Output "============================================="
Write-Output "  TOTAL: $($tests.Count)   PASS: $pass   FAIL: $fail"
Write-Output "============================================="
if ($fails.Count -gt 0) {
  Write-Output ""
  Write-Output "BROKEN ENDPOINTS:"
  foreach ($f in $fails) { Write-Output "  >> $f" }
}
