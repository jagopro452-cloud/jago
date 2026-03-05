<?php

namespace Modules\TripManagement\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use Modules\TripManagement\Entities\TripRequest;
use Modules\TripManagement\Entities\SharedTripPassenger;
use Illuminate\Http\Request;

class CarSharingAdminController extends Controller
{
    public function index(Request $request)
    {
        $search = $request->get('search');
        $status = $request->get('status');
        $sharingType = $request->get('sharing_type');

        $query = TripRequest::where('ride_mode', 'shared')
            ->whereNotNull('shared_group_id')
            ->with(['customer:id,first_name,last_name,phone', 'driver:id,first_name,last_name,phone', 'vehicleCategory:id,name'])
            ->withCount(['sharedPassengers as total_passengers'])
            ->withCount(['sharedPassengers as active_passengers' => function ($q) {
                $q->whereIn('status', ['pending', 'picked_up']);
            }]);

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('shared_group_id', 'ilike', "%{$search}%")
                    ->orWhere('ref_id', 'ilike', "%{$search}%");
            });
        }

        if ($status && $status !== 'all') {
            $query->where('current_status', $status);
        }

        if ($sharingType && $sharingType !== 'all') {
            $query->where('sharing_type', $sharingType);
        }

        $trips = $query->orderBy('created_at', 'desc')->paginate(15);

        return view('tripmanagement::admin.car-sharing.index', compact('trips', 'search', 'status', 'sharingType'));
    }

    public function show(string $id)
    {
        $trip = TripRequest::where('id', $id)
            ->where('ride_mode', 'shared')
            ->with(['customer:id,first_name,last_name,phone,email', 'driver:id,first_name,last_name,phone,email', 'vehicleCategory:id,name', 'coordinate', 'fee'])
            ->firstOrFail();

        $passengers = SharedTripPassenger::where('shared_group_id', $trip->shared_group_id)
            ->with('user:id,first_name,last_name,phone')
            ->orderByRaw("CASE WHEN status = 'picked_up' THEN 1 WHEN status = 'pending' THEN 2 WHEN status = 'dropped_off' THEN 3 ELSE 4 END")
            ->orderBy('created_at')
            ->get();

        $stats = [
            'total_passengers' => $passengers->count(),
            'active' => $passengers->whereIn('status', ['pending', 'picked_up'])->count(),
            'picked_up' => $passengers->where('status', 'picked_up')->count(),
            'dropped_off' => $passengers->where('status', 'dropped_off')->count(),
            'pending' => $passengers->where('status', 'pending')->count(),
            'total_fare' => round($passengers->sum('fare_amount'), 2),
            'total_seats' => $passengers->sum('seats_booked'),
        ];

        return view('tripmanagement::admin.car-sharing.show', compact('trip', 'passengers', 'stats'));
    }
}
