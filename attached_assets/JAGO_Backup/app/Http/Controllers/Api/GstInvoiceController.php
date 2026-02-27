<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;

class GstInvoiceController extends Controller
{
    private const GST_HSN_PASSENGER = '996411';
    private const GST_HSN_PARCEL = '996812';
    private const COMPANY_NAME = 'Mindwhile IT Solutions Pvt Ltd';
    private const COMPANY_GSTIN = 'PENDING_GSTIN';
    private const COMPANY_ADDRESS = 'Hyderabad, Telangana, India';
    private const SAC_PASSENGER = '996411';
    private const SAC_PARCEL = '996812';

    public function generate(Request $request, string $tripId): JsonResponse
    {
        $trip = DB::table('trip_requests')
            ->where('id', $tripId)
            ->where('current_status', 'completed')
            ->first();

        if (!$trip) {
            return response()->json(responseFormatter(DEFAULT_404, null), 404);
        }

        $user = $request->user();
        if ($user && $user->user_type !== 'admin' && $user->id !== $trip->customer_id && $user->id !== $trip->driver_id) {
            return response()->json(responseFormatter(DEFAULT_403, null), 403);
        }

        $customer = DB::table('users')->where('id', $trip->customer_id)->first();
        $driver = DB::table('users')->where('id', $trip->driver_id)->first();
        $fees = DB::table('trip_request_fees')->where('trip_request_id', $tripId)->first();
        $zone = DB::table('zones')->where('id', $trip->zone_id)->first();

        $isParcel = $trip->type === 'parcel';
        $hsnCode = $isParcel ? self::GST_HSN_PARCEL : self::GST_HSN_PASSENGER;
        $sacCode = $isParcel ? self::SAC_PARCEL : self::SAC_PASSENGER;

        $baseFare = (float) $trip->paid_fare;
        $vatPercent = $fees ? (float) $fees->vat_tax : 0;

        $fareBeforeGst = $baseFare;
        $gstAmount = 0;
        if ($vatPercent > 0 && $baseFare > 0) {
            $fareBeforeGst = round($baseFare / (1 + ($vatPercent / 100)), 2);
            $gstAmount = round($baseFare - $fareBeforeGst, 2);
        }

        $cgst = round($gstAmount / 2, 2);
        $sgst = round($gstAmount / 2, 2);
        $igst = 0;

        $invoiceNumber = 'JAGO-' . strtoupper(substr($trip->type, 0, 1)) . '-' . date('Ymd', strtotime($trip->updated_at)) . '-' . substr($tripId, -8);

        $invoice = [
            'invoice_number' => $invoiceNumber,
            'invoice_date' => date('Y-m-d', strtotime($trip->updated_at)),
            'invoice_time' => date('H:i:s', strtotime($trip->updated_at)),
            'trip_ref' => $trip->ref_id,
            'trip_type' => $trip->type,
            'service_type' => $isParcel ? 'Parcel Delivery Service' : 'Passenger Transportation Service',

            'supplier' => [
                'name' => self::COMPANY_NAME,
                'gstin' => self::COMPANY_GSTIN,
                'address' => self::COMPANY_ADDRESS,
                'brand' => 'JAGO',
            ],

            'customer' => [
                'name' => $customer ? trim($customer->first_name . ' ' . $customer->last_name) : 'Customer',
                'phone' => $customer->phone ?? '',
            ],

            'pilot' => [
                'name' => $driver ? trim($driver->first_name . ' ' . $driver->last_name) : 'Pilot',
            ],

            'trip_details' => [
                'zone' => $zone->name ?? '',
                'distance_km' => round($trip->actual_distance ?? $trip->estimated_distance ?? 0, 2),
                'payment_method' => $trip->payment_method,
                'ride_mode' => $trip->ride_mode ?? 'single',
            ],

            'fare_breakdown' => [
                'base_fare' => $fareBeforeGst,
                'coupon_discount' => (float) ($trip->coupon_amount ?? 0),
                'discount' => (float) ($trip->discount_amount ?? 0),
                'special_discount' => $fees ? (float) ($fees->special_discount_amount ?? 0) : 0,
                'tips' => (float) ($trip->tips ?? 0),
                'waiting_fee' => $fees ? (float) ($fees->waiting_fee ?? 0) : 0,
                'pickup_charge' => $fees ? (float) ($fees->pickup_charge ?? 0) : 0,
                'helper_fee' => (float) ($trip->helper_fee ?? 0),
                'subtotal' => $fareBeforeGst,
            ],

            'tax_details' => [
                'hsn_sac_code' => $hsnCode,
                'taxable_amount' => $fareBeforeGst,
                'cgst_rate' => $vatPercent > 0 ? round($vatPercent / 2, 2) : 0,
                'cgst_amount' => $cgst,
                'sgst_rate' => $vatPercent > 0 ? round($vatPercent / 2, 2) : 0,
                'sgst_amount' => $sgst,
                'igst_rate' => 0,
                'igst_amount' => $igst,
                'total_gst' => $gstAmount,
            ],

            'total' => [
                'amount_before_tax' => $fareBeforeGst,
                'total_tax' => $gstAmount,
                'total_amount' => $baseFare,
                'currency' => 'INR',
                'amount_in_words' => $this->numberToWords(round($baseFare)),
            ],

            'legal' => [
                'disclaimer' => 'This is a computer-generated invoice and does not require a physical signature.',
                'jurisdiction' => 'Subject to Hyderabad, Telangana jurisdiction.',
                'compliance' => 'Generated under GST Act, 2017. Invoice as per Rule 46 of CGST Rules.',
            ],
        ];

        return response()->json(responseFormatter(DEFAULT_200, $invoice));
    }

    public function history(Request $request): JsonResponse
    {
        $userId = $request->user()?->id;
        if (!$userId) {
            return response()->json(responseFormatter(DEFAULT_401, null), 401);
        }

        $page = max(1, (int) $request->get('page', 1));
        $perPage = min(20, max(1, (int) $request->get('per_page', 10)));

        $trips = DB::table('trip_requests')
            ->where('customer_id', $userId)
            ->where('current_status', 'completed')
            ->orderBy('updated_at', 'desc')
            ->select('id', 'ref_id', 'type', 'paid_fare', 'payment_method', 'updated_at')
            ->paginate($perPage, ['*'], 'page', $page);

        $invoices = collect($trips->items())->map(function ($trip) {
            return [
                'trip_id' => $trip->id,
                'ref_id' => $trip->ref_id,
                'type' => $trip->type,
                'amount' => (float) $trip->paid_fare,
                'payment_method' => $trip->payment_method,
                'date' => date('Y-m-d', strtotime($trip->updated_at)),
                'invoice_number' => 'JAGO-' . strtoupper(substr($trip->type, 0, 1)) . '-' . date('Ymd', strtotime($trip->updated_at)) . '-' . substr($trip->id, -8),
            ];
        });

        return response()->json(responseFormatter(DEFAULT_200, [
            'invoices' => $invoices,
            'pagination' => [
                'current_page' => $trips->currentPage(),
                'total_pages' => $trips->lastPage(),
                'total' => $trips->total(),
                'per_page' => $trips->perPage(),
            ],
        ]));
    }

    private function numberToWords(int $number): string
    {
        if ($number == 0) return 'Zero Rupees';

        $ones = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
                 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
                 'Seventeen', 'Eighteen', 'Nineteen'];
        $tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

        $words = '';

        if ($number >= 10000000) {
            $words .= $this->numberToWords(intdiv($number, 10000000)) . ' Crore ';
            $number %= 10000000;
        }
        if ($number >= 100000) {
            $words .= $this->numberToWords(intdiv($number, 100000)) . ' Lakh ';
            $number %= 100000;
        }
        if ($number >= 1000) {
            $words .= $this->numberToWords(intdiv($number, 1000)) . ' Thousand ';
            $number %= 1000;
        }
        if ($number >= 100) {
            $words .= $ones[intdiv($number, 100)] . ' Hundred ';
            $number %= 100;
        }
        if ($number >= 20) {
            $words .= $tens[intdiv($number, 10)] . ' ';
            $number %= 10;
        }
        if ($number > 0) {
            $words .= $ones[$number] . ' ';
        }

        return trim($words) . ' Rupees Only';
    }
}
