<?php

namespace Modules\TripManagement\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use Modules\TripManagement\Entities\SharingFareProfile;
use Modules\ZoneManagement\Entities\Zone;
use Modules\VehicleManagement\Entities\VehicleCategory;
use Illuminate\Http\Request;

class SharingFareProfileController extends Controller
{
    public function index(Request $request)
    {
        $sharingType = $request->get('sharing_type');
        $zoneId = $request->get('zone_id');

        $query = SharingFareProfile::with(['zone', 'vehicleCategory']);

        if ($sharingType && $sharingType !== 'all') {
            $query->where('sharing_type', $sharingType);
        }

        if ($zoneId && $zoneId !== 'all') {
            $query->where('zone_id', $zoneId);
        }

        $profiles = $query->orderBy('created_at', 'desc')->paginate(15);
        $zones = Zone::select('id', 'name')->where('is_active', 1)->get();

        return view('tripmanagement::admin.sharing-fare-profiles.index', compact('profiles', 'sharingType', 'zoneId', 'zones'));
    }

    public function create()
    {
        $zones = Zone::select('id', 'name')->where('is_active', 1)->get();
        $vehicleCategories = VehicleCategory::select('id', 'name')->where('is_active', 1)->get();

        return view('tripmanagement::admin.sharing-fare-profiles.create', compact('zones', 'vehicleCategories'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'zone_id' => 'required|uuid',
            'vehicle_category_id' => 'required|uuid',
            'sharing_type' => 'required|in:city,outstation',
            'base_fare_per_seat' => 'required|numeric|min:0',
            'per_km_fare_per_seat' => 'required|numeric|min:0',
            'discount_percent' => 'nullable|numeric|min:0|max:100',
            'commission_percent' => 'nullable|numeric|min:0|max:100',
            'gst_percent' => 'nullable|numeric|min:0|max:100',
            'min_fare_per_seat' => 'nullable|numeric|min:0',
            'max_detour_km' => 'nullable|numeric|min:0',
            'min_distance_km' => 'nullable|numeric|min:0',
            'max_distance_km' => 'nullable|numeric|min:0',
            'is_active' => 'nullable',
        ]);

        $exists = SharingFareProfile::where('zone_id', $request->zone_id)
            ->where('vehicle_category_id', $request->vehicle_category_id)
            ->where('sharing_type', $request->sharing_type)
            ->exists();

        if ($exists) {
            return back()->withInput()->withErrors([
                'zone_id' => translate('a_fare_profile_already_exists_for_this_zone_vehicle_and_sharing_type_combination'),
            ]);
        }

        $data = $request->only([
            'zone_id', 'vehicle_category_id', 'sharing_type',
            'base_fare_per_seat', 'per_km_fare_per_seat', 'discount_percent',
            'commission_percent', 'gst_percent', 'min_fare_per_seat',
            'max_detour_km', 'min_distance_km', 'max_distance_km',
        ]);

        $data['is_active'] = $request->has('is_active') ? 1 : 0;
        $data['discount_percent'] = $data['discount_percent'] ?? 0;
        $data['commission_percent'] = $data['commission_percent'] ?? 0;
        $data['gst_percent'] = $data['gst_percent'] ?? 0;
        $data['min_fare_per_seat'] = $data['min_fare_per_seat'] ?? 0;
        $data['max_detour_km'] = $data['max_detour_km'] ?? 0;
        $data['min_distance_km'] = $data['min_distance_km'] ?? 0;
        $data['max_distance_km'] = $data['max_distance_km'] ?? 0;

        SharingFareProfile::create($data);

        return redirect()->route('admin.trip.sharing-fare-profiles.index')
            ->with('success', translate('sharing_fare_profile_created_successfully'));
    }

    public function edit(string $id)
    {
        $profile = SharingFareProfile::findOrFail($id);
        $zones = Zone::select('id', 'name')->where('is_active', 1)->get();
        $vehicleCategories = VehicleCategory::select('id', 'name')->where('is_active', 1)->get();

        return view('tripmanagement::admin.sharing-fare-profiles.edit', compact('profile', 'zones', 'vehicleCategories'));
    }

    public function update(Request $request, string $id)
    {
        $profile = SharingFareProfile::findOrFail($id);

        $request->validate([
            'zone_id' => 'required|uuid',
            'vehicle_category_id' => 'required|uuid',
            'sharing_type' => 'required|in:city,outstation',
            'base_fare_per_seat' => 'required|numeric|min:0',
            'per_km_fare_per_seat' => 'required|numeric|min:0',
            'discount_percent' => 'nullable|numeric|min:0|max:100',
            'commission_percent' => 'nullable|numeric|min:0|max:100',
            'gst_percent' => 'nullable|numeric|min:0|max:100',
            'min_fare_per_seat' => 'nullable|numeric|min:0',
            'max_detour_km' => 'nullable|numeric|min:0',
            'min_distance_km' => 'nullable|numeric|min:0',
            'max_distance_km' => 'nullable|numeric|min:0',
            'is_active' => 'nullable',
        ]);

        $exists = SharingFareProfile::where('zone_id', $request->zone_id)
            ->where('vehicle_category_id', $request->vehicle_category_id)
            ->where('sharing_type', $request->sharing_type)
            ->where('id', '!=', $id)
            ->exists();

        if ($exists) {
            return back()->withInput()->withErrors([
                'zone_id' => translate('a_fare_profile_already_exists_for_this_zone_vehicle_and_sharing_type_combination'),
            ]);
        }

        $data = $request->only([
            'zone_id', 'vehicle_category_id', 'sharing_type',
            'base_fare_per_seat', 'per_km_fare_per_seat', 'discount_percent',
            'commission_percent', 'gst_percent', 'min_fare_per_seat',
            'max_detour_km', 'min_distance_km', 'max_distance_km',
        ]);

        $data['is_active'] = $request->has('is_active') ? 1 : 0;
        $data['discount_percent'] = $data['discount_percent'] ?? 0;
        $data['commission_percent'] = $data['commission_percent'] ?? 0;
        $data['gst_percent'] = $data['gst_percent'] ?? 0;
        $data['min_fare_per_seat'] = $data['min_fare_per_seat'] ?? 0;
        $data['max_detour_km'] = $data['max_detour_km'] ?? 0;
        $data['min_distance_km'] = $data['min_distance_km'] ?? 0;
        $data['max_distance_km'] = $data['max_distance_km'] ?? 0;

        $profile->update($data);

        return redirect()->route('admin.trip.sharing-fare-profiles.index')
            ->with('success', translate('sharing_fare_profile_updated_successfully'));
    }

    public function toggleStatus(string $id)
    {
        $profile = SharingFareProfile::findOrFail($id);
        $profile->update(['is_active' => !$profile->is_active]);

        return back()->with('success', translate('status_updated_successfully'));
    }

    public function destroy(string $id)
    {
        $profile = SharingFareProfile::findOrFail($id);
        $profile->delete();

        return back()->with('success', translate('sharing_fare_profile_deleted_successfully'));
    }
}
