<?php

namespace Modules\BusinessManagement\Http\Controllers\Api;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Modules\BusinessManagement\Entities\CorporateAccount;
use Modules\UserManagement\Entities\User;

class CorporateApiController extends Controller
{
    public function activateCorporate(Request $request): JsonResponse
    {
        $request->validate([
            'company_code' => 'required|string',
            'employee_id' => 'required|string',
        ]);

        $corporate = CorporateAccount::where('company_code', $request->company_code)
            ->where('is_active', true)
            ->first();

        if (!$corporate) {
            return response()->json(['message' => 'Invalid company code or account is inactive'], 404);
        }

        if ($corporate->contract_end && $corporate->contract_end->isPast()) {
            return response()->json(['message' => 'Corporate contract has expired'], 403);
        }

        $user = $request->user();

        if ($user->corporate_account_id && $user->corporate_account_id !== $corporate->id) {
            return response()->json(['message' => 'You are already linked to another corporate account'], 409);
        }

        $existingEmployee = User::where('corporate_account_id', $corporate->id)
            ->where('employee_id', $request->employee_id)
            ->where('id', '!=', $user->id)
            ->exists();

        if ($existingEmployee) {
            return response()->json(['message' => 'This employee ID is already in use'], 409);
        }

        if (!$user->corporate_account_id && $corporate->active_employees >= $corporate->max_employees) {
            return response()->json(['message' => 'Corporate account has reached maximum employee limit'], 403);
        }

        if (!$user->corporate_account_id) {
            $corporate->increment('active_employees');
        }

        $user->update([
            'corporate_account_id' => $corporate->id,
            'employee_id' => $request->employee_id,
            'user_category' => 'corporate',
        ]);

        return response()->json([
            'message' => 'Corporate account activated successfully',
            'corporate' => [
                'company_name' => $corporate->company_name,
                'plan_type' => $corporate->plan_type,
                'discount_percent' => $corporate->discount_percent,
                'ride_allowed' => $corporate->ride_allowed,
                'parcel_allowed' => $corporate->parcel_allowed,
            ],
        ]);
    }

    public function deactivateCorporate(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user->corporate_account_id) {
            return response()->json(['message' => 'You are not linked to any corporate account'], 404);
        }

        CorporateAccount::where('id', $user->corporate_account_id)->decrement('active_employees');

        $user->update([
            'corporate_account_id' => null,
            'employee_id' => null,
            'user_category' => 'regular',
        ]);

        return response()->json(['message' => 'Corporate account deactivated']);
    }

    public function corporateStatus(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user->corporate_account_id) {
            return response()->json([
                'is_corporate' => false,
            ]);
        }

        $corporate = CorporateAccount::find($user->corporate_account_id);

        return response()->json([
            'is_corporate' => true,
            'employee_id' => $user->employee_id,
            'corporate' => $corporate ? [
                'company_name' => $corporate->company_name,
                'company_code' => $corporate->company_code,
                'plan_type' => $corporate->plan_type,
                'discount_percent' => $corporate->discount_percent,
                'ride_allowed' => $corporate->ride_allowed,
                'parcel_allowed' => $corporate->parcel_allowed,
                'remaining_credit' => $corporate->remaining_credit,
            ] : null,
        ]);
    }
}
