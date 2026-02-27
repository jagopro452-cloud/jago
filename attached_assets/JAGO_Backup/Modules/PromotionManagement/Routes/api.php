<?php

use Illuminate\Support\Facades\Route;
use Modules\PromotionManagement\Http\Controllers\Api\Customer\BannerSetupController;
use Modules\PromotionManagement\Http\Controllers\Api\Customer\CouponSetupController;
use Modules\PromotionManagement\Http\Controllers\Api\Customer\DiscountSetupController;
use Modules\PromotionManagement\Http\Controllers\Api\SpinWheelApiController;

Route::group(['prefix' => 'customer'], function (){

    Route::group(['prefix' => 'banner'], function(){
        Route::controller(BannerSetupController::class)->group(function () {
            Route::get('list', 'list');
        Route::post('update-redirection-count', 'RedirectionCount');
        });

    });
    Route::group(['prefix' => 'coupon', 'middleware' => ['auth:api', 'maintenance_mode']], function(){
        Route::controller(CouponSetupController::class)->group(function () {
            Route::get('list', 'list');
             Route::post('apply', 'apply');
        });
    });
    Route::group(['prefix' => 'discount', 'middleware' => ['auth:api', 'maintenance_mode']], function(){
        Route::controller(DiscountSetupController::class)->group(function () {
            Route::get('list', 'list');
        });
    });
    Route::group(['prefix' => 'spin-wheel'], function () {
        Route::controller(SpinWheelApiController::class)->group(function () {
            Route::get('config', 'getConfig');
            Route::group(['middleware' => ['auth:api', 'maintenance_mode']], function () {
                Route::post('spin', 'spin');
                Route::get('history', 'history');
            });
        });
    });
});
