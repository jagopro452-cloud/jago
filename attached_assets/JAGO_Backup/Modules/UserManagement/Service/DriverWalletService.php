<?php

namespace Modules\UserManagement\Service;

use Illuminate\Support\Facades\DB;
use Modules\TransactionManagement\Entities\Transaction;
use Modules\UserManagement\Entities\UserAccount;
use Modules\UserManagement\Entities\DriverDetail;

class DriverWalletService
{
    public static function deductPlatformFee($driverId, $platformFee, $gst, $tripId): void
    {
        $totalDeduction = $platformFee + $gst;
        if ($totalDeduction <= 0) return;

        DB::beginTransaction();
        try {
            $account = UserAccount::where('user_id', $driverId)->lockForUpdate()->first();
            if (!$account) {
                DB::rollBack();
                return;
            }

            $account->wallet_balance -= $totalDeduction;
            $account->save();

            $transaction = new Transaction();
            $transaction->attribute = 'platform_fee_deduction';
            $transaction->attribute_id = $tripId;
            $transaction->debit = $totalDeduction;
            $transaction->credit = 0;
            $transaction->balance = $account->wallet_balance;
            $transaction->user_id = $driverId;
            $transaction->account = 'wallet_balance';
            $transaction->trx_type = 'Platform fee (₹' . round($platformFee, 2) . ') + GST (₹' . round($gst, 2) . ') deducted for ride';
            $transaction->save();

            DB::commit();
        } catch (\Exception $e) {
            DB::rollBack();
            \Log::error("Platform fee deduction failed for driver {$driverId}: " . $e->getMessage());
            return;
        }

        self::checkAndApplyAutoLock($driverId);
    }

    public static function rechargeWallet($driverId, $amount, $paymentMethod = 'online'): array
    {
        if ($amount <= 0) {
            return ['success' => false, 'message' => 'Invalid amount'];
        }

        DB::beginTransaction();
        try {
            $account = UserAccount::where('user_id', $driverId)->lockForUpdate()->first();
            if (!$account) {
                DB::rollBack();
                return ['success' => false, 'message' => 'Account not found'];
            }

            $previousBalance = $account->wallet_balance;
            $account->wallet_balance += $amount;
            $account->save();

            $transaction = new Transaction();
            $transaction->attribute = 'wallet_recharge';
            $transaction->credit = $amount;
            $transaction->debit = 0;
            $transaction->balance = $account->wallet_balance;
            $transaction->user_id = $driverId;
            $transaction->account = 'wallet_balance';
            $transaction->trx_type = 'Wallet recharged via ' . $paymentMethod . ' - ₹' . number_format($amount, 2);
            $transaction->save();

            DB::commit();

            $unlocked = self::checkAndAutoUnlock($driverId);

            $user = \Modules\UserManagement\Entities\User::find($driverId);
            if ($user && $user->fcm_token) {
                sendDeviceNotification(
                    fcm_token: $user->fcm_token,
                    title: translate(key: 'wallet_recharged_successfully', locale: $user->current_language_key),
                    description: translate(key: '₹' . number_format($amount, 2) . ' added to your wallet. New balance: ₹' . number_format($account->wallet_balance, 2), locale: $user->current_language_key),
                    status: 'success',
                    notification_type: 'wallet',
                    action: 'wallet_recharge_success',
                    user_id: $driverId,
                );
            }

            return [
                'success' => true,
                'previous_balance' => $previousBalance,
                'new_balance' => $account->wallet_balance,
                'amount_added' => $amount,
                'was_unlocked' => $unlocked,
            ];
        } catch (\Exception $e) {
            DB::rollBack();
            \Log::error("Wallet recharge failed for driver {$driverId}: " . $e->getMessage());
            return ['success' => false, 'message' => 'Recharge failed'];
        }
    }

    public static function checkAndApplyAutoLock($driverId): bool
    {
        $negativeLimit = (float)(get_cache('negative_balance_limit') ?? 200);
        $account = UserAccount::where('user_id', $driverId)->first();

        if (!$account) return false;

        if ($account->wallet_balance <= -$negativeLimit) {
            $driverDetail = DriverDetail::where('user_id', $driverId)->first();
            if ($driverDetail && !$driverDetail->is_suspended) {
                $driverDetail->is_suspended = true;
                $driverDetail->suspend_reason = 'negative_balance_auto_lock';
                $driverDetail->save();
                \Log::info("Driver {$driverId} auto-locked: wallet balance {$account->wallet_balance} exceeded negative limit -{$negativeLimit}");

                $user = \Modules\UserManagement\Entities\User::find($driverId);
                if ($user && $user->fcm_token) {
                    sendDeviceNotification(
                        fcm_token: $user->fcm_token,
                        title: translate(key: 'account_locked', locale: $user->current_language_key),
                        description: translate(key: 'Your account is locked due to negative wallet balance (₹' . number_format(abs($account->wallet_balance), 2) . '). Please recharge your wallet to continue accepting rides.', locale: $user->current_language_key),
                        status: 'warning',
                        notification_type: 'wallet',
                        action: 'negative_balance_lock',
                        user_id: $driverId,
                    );
                }

                return true;
            }
        }
        return false;
    }

    public static function checkAndAutoUnlock($driverId): bool
    {
        $negativeLimit = (float)(get_cache('negative_balance_limit') ?? 200);
        $account = UserAccount::where('user_id', $driverId)->first();
        $driverDetail = DriverDetail::where('user_id', $driverId)->first();

        if (!$account || !$driverDetail) return false;

        if ($driverDetail->is_suspended && $driverDetail->suspend_reason === 'negative_balance_auto_lock') {
            if ($account->wallet_balance > -$negativeLimit) {
                $driverDetail->is_suspended = false;
                $driverDetail->suspend_reason = null;
                $driverDetail->save();
                \Log::info("Driver {$driverId} auto-unlocked: wallet balance {$account->wallet_balance} above negative limit -{$negativeLimit}");

                $user = \Modules\UserManagement\Entities\User::find($driverId);
                if ($user && $user->fcm_token) {
                    sendDeviceNotification(
                        fcm_token: $user->fcm_token,
                        title: translate(key: 'account_unlocked', locale: $user->current_language_key),
                        description: translate(key: 'Your account has been unlocked. You can now accept rides again!', locale: $user->current_language_key),
                        status: 'success',
                        notification_type: 'wallet',
                        action: 'negative_balance_unlock',
                        user_id: $driverId,
                    );
                }

                return true;
            }
        }
        return false;
    }

    public static function isLockedForNegativeBalance($driverId): array|bool
    {
        $driverDetail = DriverDetail::where('user_id', $driverId)->first();
        if ($driverDetail && $driverDetail->is_suspended && $driverDetail->suspend_reason === 'negative_balance_auto_lock') {
            $account = UserAccount::where('user_id', $driverId)->first();
            $negativeLimit = (float)(get_cache('negative_balance_limit') ?? 200);
            $walletBalance = $account ? $account->wallet_balance : 0;
            $amountToClear = round(max(0, abs($walletBalance) - $negativeLimit + 1), 2);
            return [
                'response_code' => 'negative_balance_locked_403',
                'message' => 'Your account is locked due to negative wallet balance. Please add money to continue accepting rides.',
                'wallet_balance' => $walletBalance,
                'amount_to_clear' => $amountToClear,
                'negative_limit' => $negativeLimit,
            ];
        }
        return true;
    }

    public static function getWalletStatus($driverId): array
    {
        $account = UserAccount::where('user_id', $driverId)->first();
        $driverDetail = DriverDetail::where('user_id', $driverId)->first();
        $negativeLimit = (float)(get_cache('negative_balance_limit') ?? 200);

        $isLocked = $driverDetail && $driverDetail->is_suspended && $driverDetail->suspend_reason === 'negative_balance_auto_lock';
        $walletBalance = $account ? $account->wallet_balance : 0;

        return [
            'wallet_balance' => round($walletBalance, 2),
            'negative_limit' => $negativeLimit,
            'is_locked' => $isLocked,
            'amount_to_clear' => $isLocked ? round(max(0, abs($walletBalance) - $negativeLimit + 1), 2) : 0,
            'warning_threshold' => round($negativeLimit * 0.8, 2),
            'is_warning' => !$isLocked && $walletBalance < 0 && abs($walletBalance) >= ($negativeLimit * 0.8),
        ];
    }

    public static function adminManualUnlock($driverId, $adminNote = null): bool
    {
        $driverDetail = DriverDetail::where('user_id', $driverId)->first();
        if (!$driverDetail || !$driverDetail->is_suspended || $driverDetail->suspend_reason !== 'negative_balance_auto_lock') {
            return false;
        }

        $driverDetail->is_suspended = false;
        $driverDetail->suspend_reason = null;
        $driverDetail->save();

        \Log::info("Driver {$driverId} manually unlocked by admin" . ($adminNote ? ": {$adminNote}" : ''));

        $user = \Modules\UserManagement\Entities\User::find($driverId);
        if ($user && $user->fcm_token) {
            sendDeviceNotification(
                fcm_token: $user->fcm_token,
                title: translate(key: 'account_unlocked', locale: $user->current_language_key),
                description: translate(key: 'Your account has been unlocked by admin. You can now accept rides again!', locale: $user->current_language_key),
                status: 'success',
                notification_type: 'wallet',
                action: 'admin_manual_unlock',
                user_id: $driverId,
            );
        }

        return true;
    }
}
