<?php

use Illuminate\Support\Facades\Route;
use Modules\TripManagement\Http\Controllers\Web\RefundController;
use Modules\TripManagement\Http\Controllers\Web\SafetyAlertController;
use Modules\TripManagement\Http\Controllers\Web\Admin\FestivalOfferController;
use Modules\TripManagement\Http\Controllers\Web\Admin\SharingFareProfileController;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::group(['prefix' => 'admin', 'as' => 'admin.', 'middleware' => 'admin'], function () {
    Route::group(['prefix' => 'trip', 'as' => 'trip.'], function () {
        Route::controller(\Modules\TripManagement\Http\Controllers\Web\TripController::class)->group(function () {
            Route::get('list/{type}', 'tripList')->name('index');
            Route::get('details/{id}', 'show')->name('show');
            Route::delete('delete/{id}', 'destroy')->name('delete');
            Route::get('export', 'export')->name('export');
            Route::get('log', 'log')->name('log');
            Route::get('invoice/{id}', 'invoice')->name('invoice');
        });

        Route::group(['prefix' => 'refund', 'as' => 'refund.'], function () {
            Route::controller(RefundController::class)->group(function () {
                Route::get('list/{type}', 'parcelRefundList')->name('index');
                Route::get('details/{id}', 'show')->name('show');
                Route::post('approved/{id}', 'storeApproved')->name('approved');
                Route::post('denied/{id}', 'storeDenied')->name('denied');
                Route::post('store/{id}', 'store')->name('store');
                Route::get('export', 'export')->name('export');
            });
        });
    });

    Route::group(['prefix' => 'trip/car-sharing', 'as' => 'trip.car-sharing.'], function () {
        Route::controller(\Modules\TripManagement\Http\Controllers\Web\Admin\CarSharingAdminController::class)->group(function () {
            Route::get('/', 'index')->name('index');
            Route::get('details/{id}', 'show')->name('show');
        });
    });

    Route::group(['prefix' => 'safety-alert', 'as' => 'safety-alert.'], function () {
        Route::controller(SafetyAlertController::class)->group(function () {
            Route::get('list/{type}', 'index')->name('index');
            Route::get('export/{type}', 'export')->name('export');
            Route::put('mark-as-solved/{id}', 'markAsSolved')->name('mark-as-solved');
            Route::put('ajax-mark-as-solved/{id}', 'ajaxMarkAsSolved')->name('ajax-mark-as-solved');
        });
    });

    Route::group(['prefix' => 'trip/festival-offers', 'as' => 'trip.festival-offers.'], function () {
        Route::controller(FestivalOfferController::class)->group(function () {
            Route::get('/', 'index')->name('index');
            Route::get('create', 'create')->name('create');
            Route::post('store', 'store')->name('store');
            Route::get('edit/{id}', 'edit')->name('edit');
            Route::put('update/{id}', 'update')->name('update');
            Route::post('toggle-status/{id}', 'toggleStatus')->name('toggle-status');
            Route::delete('delete/{id}', 'destroy')->name('destroy');
        });
    });

    Route::group(['prefix' => 'trip/sharing-fare-profiles', 'as' => 'trip.sharing-fare-profiles.'], function () {
        Route::controller(SharingFareProfileController::class)->group(function () {
            Route::get('/', 'index')->name('index');
            Route::get('create', 'create')->name('create');
            Route::post('store', 'store')->name('store');
            Route::get('edit/{id}', 'edit')->name('edit');
            Route::put('update/{id}', 'update')->name('update');
            Route::post('toggle-status/{id}', 'toggleStatus')->name('toggle-status');
            Route::delete('delete/{id}', 'destroy')->name('destroy');
        });
    });

});
