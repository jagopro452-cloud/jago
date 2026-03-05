<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'mailgun' => [
        'domain' => env('MAILGUN_DOMAIN'),
        'secret' => env('MAILGUN_SECRET'),
        'endpoint' => env('MAILGUN_ENDPOINT', 'api.mailgun.net'),
    ],

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'paystack' => [
        'public_key' => env('PAYSTACK_PUBLIC_KEY'),
        'secret_key' => env('PAYSTACK_SECRET_KEY'),
        'payment_url' => env('PAYSTACK_PAYMENT_URL', 'https://api.paystack.co'),
        'merchant_email' => env('MERCHANT_EMAIL'),
    ],

    'paytm' => [
        'merchant_key' => env('PAYTM_MERCHANT_KEY'),
        'merchant_id' => env('PAYTM_MERCHANT_MID'),
        'merchant_website' => env('PAYTM_MERCHANT_WEBSITE'),
        'refund_url' => env('PAYTM_REFUND_URL'),
        'status_query_url' => env('PAYTM_STATUS_QUERY_URL'),
        'status_query_new_url' => env('PAYTM_STATUS_QUERY_NEW_URL'),
        'txn_url' => env('PAYTM_TXN_URL'),
    ],

];
