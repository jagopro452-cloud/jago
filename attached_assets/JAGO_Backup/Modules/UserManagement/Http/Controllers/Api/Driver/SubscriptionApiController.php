<?php

namespace Modules\UserManagement\Http\Controllers\Api\Driver;

use App\Http\Controllers\Controller;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Modules\TransactionManagement\Entities\Transaction;
use Modules\UserManagement\Entities\DriverSubscription;
use Modules\UserManagement\Entities\SubscriptionPlan;
use Modules\UserManagement\Entities\UserAccount;

class SubscriptionApiController extends Controller
{
    public function getPlans(): JsonResponse
    {
        $plans = SubscriptionPlan::where('is_active', true)->get();
        $gstPercent = (double)(get_cache('vat_percent') ?? 18);

        $plansData = $plans->map(function ($plan) use ($gstPercent) {
            $gstAmount = round(($plan->price * $gstPercent) / 100, 2);
            return array_merge($plan->toArray(), [
                'gst_percent' => $gstPercent,
                'gst_amount' => $gstAmount,
                'total_price' => round($plan->price + $gstAmount, 2),
            ]);
        });

        return response()->json(responseFormatter(constant: DEFAULT_200, content: $plansData));
    }

    public function subscribe(Request $request): JsonResponse
    {
        $request->validate([
            'plan_id' => 'required|uuid',
        ]);

        $plan = SubscriptionPlan::where('id', $request->plan_id)->where('is_active', true)->first();
        if (!$plan) {
            return response()->json(responseFormatter(constant: DEFAULT_404), 404);
        }

        $driverId = auth('api')->id();

        $existingActive = DriverSubscription::where('driver_id', $driverId)
            ->where('status', 'active')
            ->where('expires_at', '>', now())
            ->first();

        if ($existingActive) {
            return response()->json(responseFormatter(constant: DEFAULT_400, content: null, errors: [
                ['error_code' => 'already_subscribed', 'message' => translate('you_already_have_an_active_subscription')]
            ]), 400);
        }

        $gstPercent = (double)(get_cache('vat_percent') ?? 18);
        $gstAmount = round(($plan->price * $gstPercent) / 100, 2);
        $totalAmount = round($plan->price + $gstAmount, 2);

        DB::beginTransaction();
        try {
            $userAccount = UserAccount::where('user_id', $driverId)->lockForUpdate()->first();
            if (!$userAccount || $userAccount->wallet_balance < $totalAmount) {
                DB::rollBack();
                return response()->json(responseFormatter(constant: DEFAULT_403, content: null, errors: [
                    ['error_code' => 'insufficient_balance', 'message' => translate('insufficient_wallet_balance') . '. ' . translate('Required') . ': ₹' . $totalAmount . ' (' . translate('Plan') . ': ₹' . $plan->price . ' + GST: ₹' . $gstAmount . ')']
                ]), 403);
            }

            $userAccount->wallet_balance -= $totalAmount;
            $userAccount->save();

            $transaction = new Transaction();
            $transaction->attribute = 'subscription_purchase';
            $transaction->attribute_id = $plan->id;
            $transaction->debit = $totalAmount;
            $transaction->credit = 0;
            $transaction->balance = $userAccount->wallet_balance;
            $transaction->user_id = $driverId;
            $transaction->account = 'wallet_balance';
            $transaction->trx_ref_id = $plan->id;
            $transaction->trx_type = 'Subscription: ' . $plan->name . ' (₹' . $plan->price . ' + GST ₹' . $gstAmount . ')';
            $transaction->save();

            $subscription = DriverSubscription::create([
                'driver_id' => $driverId,
                'plan_id' => $plan->id,
                'plan_name' => $plan->name,
                'duration_type' => $plan->duration_type,
                'price_paid' => $totalAmount,
                'gst_amount' => $gstAmount,
                'max_rides' => $plan->max_rides,
                'rides_used' => 0,
                'is_locked' => false,
                'status' => 'active',
                'started_at' => now(),
                'expires_at' => now()->addDays($plan->duration_days),
                'payment_transaction_id' => $transaction->id,
            ]);

            DB::commit();

            return response()->json(responseFormatter(constant: DEFAULT_200, content: array_merge($subscription->toArray(), [
                'plan_price' => $plan->price,
                'gst_percent' => $gstPercent,
                'gst_amount' => $gstAmount,
                'total_paid' => $totalAmount,
            ])));
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(responseFormatter(constant: DEFAULT_400), 400);
        }
    }

    public function getStatus(): JsonResponse
    {
        $driverId = auth('api')->id();
        $earningModel = get_cache('earning_model') ?? 'commission';
        $platformFee = (double)(get_cache('platform_fee_amount') ?? 0);
        $gstPercent = (double)(get_cache('vat_percent') ?? 18);
        $platformFeeGst = round(($platformFee * $gstPercent) / 100, 2);

        $subscription = DriverSubscription::where('driver_id', $driverId)
            ->where('status', 'active')
            ->latest()
            ->first();

        if (!$subscription) {
            return response()->json(responseFormatter(constant: DEFAULT_200, content: [
                'has_subscription' => false,
                'is_locked' => false,
                'earning_model' => $earningModel,
                'per_ride_platform_fee' => $platformFee,
                'per_ride_platform_fee_gst' => $platformFeeGst,
                'per_ride_total_deduction' => round($platformFee + $platformFeeGst, 2),
            ]));
        }

        if ($subscription->expires_at && $subscription->expires_at->isPast()) {
            $subscription->update(['status' => 'expired']);
            return response()->json(responseFormatter(constant: DEFAULT_200, content: [
                'has_subscription' => false,
                'is_locked' => $subscription->is_locked,
                'earning_model' => $earningModel,
                'per_ride_platform_fee' => $platformFee,
                'per_ride_platform_fee_gst' => $platformFeeGst,
                'per_ride_total_deduction' => round($platformFee + $platformFeeGst, 2),
            ]));
        }

        return response()->json(responseFormatter(constant: DEFAULT_200, content: [
            'has_subscription' => true,
            'subscription' => $subscription,
            'rides_used' => $subscription->rides_used,
            'rides_remaining' => max(0, $subscription->max_rides - $subscription->rides_used),
            'is_locked' => $subscription->is_locked,
            'earning_model' => $earningModel,
            'per_ride_platform_fee' => $platformFee,
            'per_ride_platform_fee_gst' => $platformFeeGst,
            'per_ride_total_deduction' => round($platformFee + $platformFeeGst, 2),
        ]));
    }

    public function getHistory(): JsonResponse
    {
        $driverId = auth('api')->id();

        $subscriptions = DriverSubscription::where('driver_id', $driverId)
            ->with('plan')
            ->latest()
            ->get();

        return response()->json(responseFormatter(constant: DEFAULT_200, content: $subscriptions));
    }
}
