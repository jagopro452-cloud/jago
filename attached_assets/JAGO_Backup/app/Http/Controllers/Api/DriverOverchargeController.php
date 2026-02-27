<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DriverOverchargeReport;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Modules\UserManagement\Entities\User;
use Modules\TripManagement\Entities\TripRequest;

class DriverOverchargeController extends Controller
{
    public function reportOvercharge(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'trip_request_id' => 'required|string',
            'reported_amount' => 'nullable|numeric|min:0',
            'description' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $customerId = auth('api')->id();
        if (!$customerId) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        $trip = TripRequest::find($request->trip_request_id);
        if (!$trip) {
            return response()->json(['error' => 'Trip not found'], 404);
        }

        if ($trip->customer_id !== $customerId) {
            return response()->json(['error' => 'This trip does not belong to you'], 403);
        }

        if (!$trip->driver_id) {
            return response()->json(['error' => 'No driver assigned to this trip'], 400);
        }

        $existingReport = DriverOverchargeReport::where('trip_request_id', $request->trip_request_id)
            ->where('customer_id', $customerId)
            ->first();

        if ($existingReport) {
            return response()->json(['error' => 'You have already reported this trip'], 409);
        }

        DB::beginTransaction();
        try {
            $report = DriverOverchargeReport::create([
                'trip_request_id' => $trip->id,
                'customer_id' => $customerId,
                'driver_id' => $trip->driver_id,
                'reported_amount' => $request->reported_amount ?? 0,
                'description' => $request->description ?? 'Driver demanded extra payment beyond app fare',
                'status' => 'confirmed',
            ]);

            $totalReports = DriverOverchargeReport::where('driver_id', $trip->driver_id)
                ->where('status', 'confirmed')
                ->count();

            $autoBlockThreshold = (int)(get_cache('overcharge_auto_block_threshold') ?? 2);

            $blocked = false;
            if ($totalReports >= $autoBlockThreshold) {
                $driver = User::find($trip->driver_id);
                if ($driver) {
                    $driver->is_active = false;
                    $driver->save();
                    $blocked = true;

                    if ($driver->fcm_token) {
                        sendDeviceNotification(
                            fcm_token: $driver->fcm_token,
                            title: 'Account Suspended',
                            description: 'Your account has been suspended due to multiple reports of demanding extra payment from customers. The fare shown in the app is the final fare. Contact support to appeal.',
                            status: 'blocked',
                            type: 'account_action',
                            notification_type: 'account',
                            user_id: $driver->id,
                        );
                    }
                }
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Report submitted successfully. ' .
                    ($blocked
                        ? 'The driver has been blocked due to multiple complaints.'
                        : 'Our team will review this report. The fare shown in the app is the final fare - you are not required to pay any extra amount.'),
                'report_id' => $report->id,
                'driver_blocked' => $blocked,
                'instructions' => [
                    'Do NOT pay any amount beyond what is shown in the app.',
                    'The fare displayed in JAGO is the final fare including all charges.',
                    'If the driver refuses to complete the ride, you can cancel and report.',
                    'Contact support if you need further assistance.',
                ],
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['error' => 'Failed to submit report. Please try again.'], 500);
        }
    }

    public function getReportStatus(Request $request): JsonResponse
    {
        $customerId = auth('api')->id();
        if (!$customerId) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        $reports = DriverOverchargeReport::where('customer_id', $customerId)
            ->orderBy('created_at', 'desc')
            ->limit(10)
            ->get();

        return response()->json([
            'reports' => $reports->map(fn($r) => [
                'id' => $r->id,
                'trip_id' => $r->trip_request_id,
                'reported_amount' => $r->reported_amount,
                'status' => $r->status,
                'admin_action' => $r->admin_action,
                'created_at' => $r->created_at->toISOString(),
            ]),
        ]);
    }

    public function adminOverchargeReports(Request $request)
    {
        $query = DriverOverchargeReport::with(['customer', 'driver', 'tripRequest'])
            ->orderBy('created_at', 'desc');

        if ($search = $request->get('search')) {
            $query->where(function ($q) use ($search) {
                $q->whereHas('driver', function ($dq) use ($search) {
                    $dq->where('first_name', 'ILIKE', "%{$search}%")
                        ->orWhere('phone', 'ILIKE', "%{$search}%");
                })->orWhereHas('customer', function ($cq) use ($search) {
                    $cq->where('first_name', 'ILIKE', "%{$search}%")
                        ->orWhere('phone', 'ILIKE', "%{$search}%");
                });
            });
        }

        if ($status = $request->get('status')) {
            $query->where('status', $status);
        }

        $reports = $query->paginate(15);

        return view('adminmodule::overcharge-reports', compact('reports'));
    }

    public function adminBlockDriver(Request $request, string $reportId): JsonResponse
    {
        $report = DriverOverchargeReport::find($reportId);
        if (!$report) {
            return response()->json(['error' => 'Report not found'], 404);
        }

        $driver = User::find($report->driver_id);
        if (!$driver) {
            return response()->json(['error' => 'Driver not found'], 404);
        }

        $driver->is_active = false;
        $driver->save();

        $report->status = 'confirmed';
        $report->admin_action = 'blocked';
        $report->admin_notes = $request->notes ?? 'Blocked by admin for overcharge complaint';
        $report->save();

        if ($driver->fcm_token) {
            sendDeviceNotification(
                fcm_token: $driver->fcm_token,
                title: 'Account Suspended',
                description: 'Your account has been suspended due to demanding extra payment. The fare shown in the app is the final fare. Contact support to appeal.',
                status: 'blocked',
                type: 'account_action',
                notification_type: 'account',
                user_id: $driver->id,
            );
        }

        return response()->json(['success' => true, 'message' => 'Driver has been blocked']);
    }

    public function adminDismissReport(Request $request, string $reportId): JsonResponse
    {
        $report = DriverOverchargeReport::find($reportId);
        if (!$report) {
            return response()->json(['error' => 'Report not found'], 404);
        }

        $report->status = 'dismissed';
        $report->admin_action = 'dismissed';
        $report->admin_notes = $request->notes ?? 'Dismissed by admin';
        $report->save();

        return response()->json(['success' => true, 'message' => 'Report dismissed']);
    }
}
