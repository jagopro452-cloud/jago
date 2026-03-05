<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\CallController;
use App\Http\Controllers\Api\DriverOverchargeController;
use App\Http\Controllers\Api\HealthController;
use App\Http\Controllers\Api\DriverPerformanceController;
use App\Http\Controllers\Api\FraudDetectionController;
use App\Http\Controllers\Api\GstInvoiceController;
use App\Http\Controllers\Api\RideAnalyticsController;
use App\Http\Controllers\Api\EtaController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

Route::prefix('calls')->middleware(['auth:api'])->group(function () {
    Route::post('start', [CallController::class, 'startCall']);
    Route::post('{callId}/signal', [CallController::class, 'sendSignal']);
    Route::get('{callId}/poll', [CallController::class, 'pollSignals']);
    Route::get('incoming', [CallController::class, 'checkIncoming']);
    Route::post('{callId}/recording', [CallController::class, 'uploadRecording']);
    Route::get('{callId}/status', [CallController::class, 'getCallStatus']);
});

Route::prefix('overcharge')->middleware(['auth:api'])->group(function () {
    Route::post('report', [DriverOverchargeController::class, 'reportOvercharge']);
    Route::get('status', [DriverOverchargeController::class, 'getReportStatus']);
});

Route::prefix('customer/ride')->middleware(['auth:api'])->group(function () {
    Route::post('report-overcharge', [DriverOverchargeController::class, 'reportOvercharge']);
});

Route::get('helper/config', function () {
    $helperEnabled = (bool)(businessConfig('helper_service_enabled', TRIP_SETTINGS)?->value ?? true);
    $helperRatePerHour = (float)(businessConfig('helper_rate_per_hour', TRIP_SETTINGS)?->value ?? 100);
    $gstPercent = (float)(get_cache('vat_percent') ?? 0);
    return response()->json(responseFormatter(DEFAULT_200, [
        'helper_enabled' => $helperEnabled,
        'helper_rate_per_hour' => $helperRatePerHour,
        'gst_percent' => $gstPercent,
        'helper_rate_with_gst' => round($helperRatePerHour + ($helperRatePerHour * $gstPercent / 100), 2),
    ]));
});

Route::get('earning-model/config', function () {
    $subscriptionEnabled = (bool)(get_cache('subscription_model_enabled') ?? false);
    $freeRideLimit = (int)(get_cache('free_ride_limit') ?? 200);
    $parcelCommissionEnabled = (bool)(get_cache('parcel_commission_enabled') ?? false);
    $parcelCommissionPercent = (float)(get_cache('parcel_commission_percent') ?? 0);
    $tripCommission = (float)(get_cache('trip_commission') ?? 0);

    return response()->json(responseFormatter(DEFAULT_200, [
        'ride' => [
            'model' => $subscriptionEnabled ? 'subscription' : 'commission',
            'subscription_enabled' => $subscriptionEnabled,
            'free_ride_limit' => $freeRideLimit,
            'commission_percent' => $tripCommission,
        ],
        'parcel' => [
            'model' => 'commission',
            'commission_enabled' => $parcelCommissionEnabled,
            'commission_percent' => $parcelCommissionEnabled ? $parcelCommissionPercent : $tripCommission,
        ],
    ]));
});

Route::get('health', HealthController::class);

Route::prefix('eta')->group(function () {
    Route::post('estimate', [EtaController::class, 'estimate']);
    Route::get('nearby-drivers', [EtaController::class, 'nearbyDrivers']);
});

Route::prefix('driver-performance')->middleware(['auth:api'])->group(function () {
    Route::get('{driverId}/score', [DriverPerformanceController::class, 'score']);
    Route::get('score/{driverId}', [DriverPerformanceController::class, 'score']);
    Route::get('leaderboard', [DriverPerformanceController::class, 'leaderboard']);
});

Route::prefix('fraud')->middleware(['auth:api'])->group(function () {
    Route::get('scan', [FraudDetectionController::class, 'scan']);
    Route::get('driver-risk/{driverId}', [FraudDetectionController::class, 'driverRisk']);
});

Route::prefix('invoice')->middleware(['auth:api'])->group(function () {
    Route::get('trip/{tripId}', [GstInvoiceController::class, 'generate']);
    Route::get('history', [GstInvoiceController::class, 'history']);
});

Route::prefix('analytics')->middleware(['auth:api'])->group(function () {
    Route::get('overview', [RideAnalyticsController::class, 'overview']);
    Route::get('peak-hours', [RideAnalyticsController::class, 'peakHours']);
    Route::get('popular-routes', [RideAnalyticsController::class, 'popularRoutes']);
    Route::get('revenue-trend', [RideAnalyticsController::class, 'revenueTrend']);
    Route::get('cancellations', [RideAnalyticsController::class, 'cancellationAnalysis']);
});
