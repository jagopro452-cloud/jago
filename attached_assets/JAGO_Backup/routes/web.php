<?php

use App\Http\Controllers\BlogController;
use App\Http\Controllers\LandingPageController;
use App\Http\Controllers\ParcelTrackingController;
use App\Http\Controllers\PaymentRecordController;
use Illuminate\Support\Facades\Route;

Route::controller(LandingPageController::class)->group(function () {
    Route::get('/', 'index')->name('index');
    Route::get('/contact-us', 'contactUs')->name('contact-us');
    Route::get('/about-us', 'aboutUs')->name('about-us');
    Route::get('/privacy', 'privacy')->name('privacy');
    Route::get('/terms', 'terms')->name('terms');

    Route::group(['prefix' => 'newsletter-subscription', 'as' => 'newsletter-subscription.'], function () {
        Route::post('/', 'storeNewsletterSubscription')->name('store');
    });
});

Route::controller(BlogController::class)->group(function () {
    Route::group(['prefix' => 'blog', 'as' => 'blog.'], function () {
        Route::get('/', 'index')->name('index');
        Route::get('customer-app-download', 'customerAppDownload')->name('customer-app-download');
        Route::get('driver-app-download', 'driverAppDownload')->name('driver-app-download');
        Route::get('search', 'search')->name('search');
        Route::get('popular-blogs', 'popularBlogs')->name('popular-blogs');
        Route::get('{category_slug}', 'category')->name('category');
        Route::get('details/{blog_slug}', 'details')->name('details');
    });
});

Route::get('track-parcel/{id}', [ParcelTrackingController::class, 'trackingParcel'])->name('track-parcel');

Route::get('add-payment-request', [PaymentRecordController::class, 'index']);
Route::get('payment-success', [PaymentRecordController::class, 'success'])->name('payment-success');
Route::get('payment-fail', [PaymentRecordController::class, 'fail'])->name('payment-fail');
Route::get('payment-cancel', [PaymentRecordController::class, 'cancel'])->name('payment-cancel');
Route::get('gateway-inactive', [PaymentRecordController::class, 'gatewayInactive'])->name('gateway-inactive');


