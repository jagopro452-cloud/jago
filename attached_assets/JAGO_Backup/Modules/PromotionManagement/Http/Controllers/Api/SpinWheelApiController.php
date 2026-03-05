<?php

namespace Modules\PromotionManagement\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Modules\PromotionManagement\Entities\SpinWheelConfig;
use Modules\PromotionManagement\Entities\SpinWheelResult;
use Modules\PromotionManagement\Entities\SpinWheelSegment;
use Modules\TransactionManagement\Entities\Transaction;
use Modules\TripManagement\Entities\TripRequest;
use Modules\UserManagement\Entities\UserAccount;

class SpinWheelApiController extends Controller
{
    public function getConfig(): JsonResponse
    {
        $config = SpinWheelConfig::first();

        if (!$config || !$config->is_active) {
            return response()->json(responseFormatter(constant: DEFAULT_200, content: [
                'is_active' => false,
            ]));
        }

        $activeSegments = SpinWheelSegment::where('spin_wheel_config_id', $config->id)
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->get();

        return response()->json(responseFormatter(constant: DEFAULT_200, content: [
            'is_active' => true,
            'title' => $config->title,
            'subtitle' => $config->subtitle,
            'segments' => $activeSegments->pluck('label')->toArray(),
            'segment_colors' => $activeSegments->pluck('color')->toArray(),
        ]));
    }

    public function spin(Request $request): JsonResponse
    {
        $request->validate([
            'trip_request_id' => 'nullable|string',
        ]);

        $config = SpinWheelConfig::first();

        if (!$config || !$config->is_active) {
            return response()->json(responseFormatter(constant: DEFAULT_404), 404);
        }

        $userId = auth('api')->id();

        if ($config->ride_completion_required) {
            if (!$request->trip_request_id) {
                return response()->json(responseFormatter(constant: DEFAULT_403, errors: [['error_code' => 403, 'message' => translate('trip_id_required_to_spin')]]), 403);
            }

            $trip = TripRequest::where('id', $request->trip_request_id)
                ->where('customer_id', $userId)
                ->where('current_status', 'completed')
                ->first();

            if (!$trip) {
                return response()->json(responseFormatter(constant: DEFAULT_403, errors: [['error_code' => 403, 'message' => translate('ride_must_be_completed_to_spin')]]), 403);
            }

            $alreadySpunForTrip = SpinWheelResult::where('user_id', $userId)
                ->where('trip_request_id', $request->trip_request_id)
                ->exists();

            if ($alreadySpunForTrip) {
                return response()->json(responseFormatter(constant: DEFAULT_403, errors: [['error_code' => 403, 'message' => translate('already_spun_for_this_ride')]]), 403);
            }
        }

        $todaySpins = SpinWheelResult::where('user_id', $userId)
            ->whereDate('created_at', Carbon::today())
            ->count();

        if ($todaySpins >= $config->spins_per_day) {
            return response()->json(responseFormatter(constant: DEFAULT_403, errors: [['error_code' => 403, 'message' => translate('daily_spin_limit_reached')]]), 403);
        }

        $activeSegments = SpinWheelSegment::where('spin_wheel_config_id', $config->id)
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->get();

        if ($activeSegments->count() < 2) {
            return response()->json(responseFormatter(constant: DEFAULT_400), 400);
        }

        $totalWeight = $activeSegments->sum('weight');
        if ($totalWeight <= 0) {
            return response()->json(responseFormatter(constant: DEFAULT_400), 400);
        }

        $winSegment = $this->weightedRandom($activeSegments, $totalWeight);
        $winIndex = $activeSegments->search(fn($s) => $s->id === $winSegment->id);
        $walletAmount = (float) $winSegment->amount;

        DB::beginTransaction();
        try {
            if ($config->max_total_per_user > 0) {
                $totalEarned = SpinWheelResult::where('user_id', $userId)->lockForUpdate()->sum('wallet_amount');
                if ($totalEarned >= $config->max_total_per_user) {
                    DB::rollBack();
                    return response()->json(responseFormatter(constant: DEFAULT_403, errors: [['error_code' => 403, 'message' => translate('maximum_spin_reward_limit_reached')]]), 403);
                }
            }

            $customerAccount = UserAccount::where('user_id', $userId)->lockForUpdate()->first();
            if (!$customerAccount) {
                $customerAccount = UserAccount::create([
                    'user_id' => $userId,
                    'wallet_balance' => 0,
                ]);
            }

            $customerAccount->wallet_balance += $walletAmount;
            $customerAccount->save();

            $transaction = new Transaction();
            $transaction->attribute = 'spin_wheel_reward';
            $transaction->attribute_id = $request->trip_request_id;
            $transaction->credit = $walletAmount;
            $transaction->added_bonus = 0;
            $transaction->balance = $customerAccount->wallet_balance;
            $transaction->user_id = $userId;
            $transaction->account = 'wallet_balance';
            $transaction->reference = null;
            $transaction->trx_type = 'Spin wheel reward ₹' . number_format($walletAmount, 2) . ' added to wallet';
            $transaction->save();

            SpinWheelResult::create([
                'user_id' => $userId,
                'trip_request_id' => $request->trip_request_id,
                'discount_value' => (int) $walletAmount,
                'wallet_amount' => $walletAmount,
                'transaction_id' => $transaction->id,
            ]);

            DB::commit();

            return response()->json(responseFormatter(constant: DEFAULT_200, content: [
                'win_index' => $winIndex,
                'wallet_amount' => $walletAmount,
                'wallet_balance' => $customerAccount->wallet_balance,
                'segments' => $activeSegments->pluck('label')->toArray(),
                'message' => '₹' . number_format($walletAmount, 2) . ' added to your wallet!',
            ]));
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(responseFormatter(constant: DEFAULT_400), 400);
        }
    }

    public function history(): JsonResponse
    {
        $userId = auth('api')->id();

        $results = SpinWheelResult::where('user_id', $userId)
            ->orderBy('created_at', 'desc')
            ->limit(50)
            ->get()
            ->map(function ($result) {
                return [
                    'wallet_amount' => $result->wallet_amount,
                    'created_at' => $result->created_at->toDateTimeString(),
                    'trip_id' => $result->trip_request_id,
                ];
            });

        return response()->json(responseFormatter(constant: DEFAULT_200, content: $results));
    }

    private function weightedRandom($segments, int $totalWeight)
    {
        $random = mt_rand(1, $totalWeight);
        $current = 0;

        foreach ($segments as $segment) {
            $current += $segment->weight;
            if ($random <= $current) {
                return $segment;
            }
        }

        return $segments->last();
    }
}
