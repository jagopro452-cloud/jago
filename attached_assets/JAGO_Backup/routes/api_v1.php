<?php

use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::prefix('customer')->group(function () {
        Route::prefix('auth')->middleware('throttle:auth')->group(function () {
            $controller = \Modules\AuthManagement\Http\Controllers\Api\AuthController::class;
            Route::post('login', [$controller, 'login']);
            Route::post('otp-login', [$controller, 'otpLogin']);
            Route::post('registration', [$controller, 'registration']);
            Route::post('check', [$controller, 'check']);
            Route::post('firebase-otp-verification', [$controller, 'firebaseOtpVerification'])->middleware('throttle:otp');
            Route::post('forget-password', [$controller, 'forgetPassword']);
            Route::post('otp-verification', [$controller, 'otpVerification'])->middleware('throttle:otp');
            Route::post('reset-password', [$controller, 'resetPassword']);
            Route::post('external-login', [$controller, 'externalLogin']);
            Route::post('external-registration', [$controller, 'externalRegistration']);
        });

        Route::middleware(['auth:api', 'maintenance_mode'])->group(function () {
            Route::prefix('ride')->group(function () {
                $controller = \Modules\TripManagement\Http\Controllers\Api\Customer\TripRequestController::class;
                Route::get('list', [$controller, 'rideList']);
                Route::get('details/{trip_request_id}', [$controller, 'rideDetails']);
                Route::post('create', [$controller, 'createRideRequest'])->middleware('throttle:trip-action');
                Route::post('get-estimated-fare', [$controller, 'getEstimatedFare']);
                Route::put('update-status/{trip_request_id}', [$controller, 'rideStatusUpdate'])->middleware('throttle:trip-action');
                Route::get('final-fare', [$controller, 'finalFareCalculation']);
                Route::post('trip-action', [$controller, 'requestAction'])->middleware('throttle:trip-action');
                Route::get('ride-resume-status', [$controller, 'rideResumeStatus']);
            });

            Route::prefix('profile')->group(function () {
                $controller = \Modules\UserManagement\Http\Controllers\Api\Customer\CustomerController::class;
                Route::get('/', [$controller, 'profileInfo']);
                Route::put('update', [$controller, 'updateProfile']);
                Route::delete('delete', [$controller, 'deleteAccount']);
            });

            Route::prefix('wallet')->middleware('throttle:payment')->group(function () {
                $controller = \Modules\UserManagement\Http\Controllers\Api\Customer\WalletController::class;
                Route::get('/', [$controller, 'index']);
                Route::post('add-fund', [$controller, 'addFund']);
            });
        });
    });

    Route::prefix('driver')->group(function () {
        Route::prefix('auth')->middleware('throttle:auth')->group(function () {
            $controller = \Modules\AuthManagement\Http\Controllers\Api\AuthController::class;
            Route::post('login', [$controller, 'login']);
            Route::post('registration', [$controller, 'registration']);
        });

        Route::middleware(['auth:api', 'maintenance_mode'])->group(function () {
            Route::prefix('ride')->group(function () {
                $controller = \Modules\TripManagement\Http\Controllers\Api\Driver\TripRequestController::class;
                Route::get('list', [$controller, 'rideList']);
                Route::get('details/{trip_request_id}', [$controller, 'rideDetails']);
                Route::post('trip-action', [$controller, 'requestAction'])->middleware('throttle:trip-action');
                Route::put('update-status/{trip_request_id}', [$controller, 'rideStatusUpdate'])->middleware('throttle:trip-action');
                Route::post('track-location', [$controller, 'trackLocation']);
                Route::get('final-fare', [$controller, 'finalFareCalculation']);
            });

            Route::prefix('profile')->group(function () {
                $controller = \Modules\UserManagement\Http\Controllers\Api\Driver\DriverController::class;
                Route::get('/', [$controller, 'profileInfo']);
                Route::put('update', [$controller, 'updateProfile']);
            });

            Route::prefix('subscription')->middleware('throttle:payment')->group(function () {
                $controller = \Modules\UserManagement\Http\Controllers\Api\Driver\SubscriptionApiController::class;
                Route::get('plans', [$controller, 'listPlans']);
                Route::post('subscribe', [$controller, 'subscribe']);
                Route::get('status', [$controller, 'status']);
                Route::get('history', [$controller, 'history']);
            });

            Route::prefix('earnings')->group(function () {
                $controller = \Modules\TransactionManagement\Http\Controllers\Api\Driver\DriverTransactionController::class;
                Route::get('/', [$controller, 'index']);
            });
        });
    });

    Route::get('config', [\Modules\BusinessManagement\Http\Controllers\Api\ConfigurationController::class, 'getConfiguration']);
});
