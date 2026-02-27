<?php

namespace Modules\TripManagement\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use Modules\TripManagement\Entities\FestivalOffer;
use Modules\ZoneManagement\Entities\Zone;
use Modules\VehicleManagement\Entities\VehicleCategory;
use Illuminate\Http\Request;

class FestivalOfferController extends Controller
{
    public function index(Request $request)
    {
        $search = $request->get('search');
        $sharingType = $request->get('sharing_type');
        $status = $request->get('status');

        $query = FestivalOffer::with(['zone', 'vehicleCategory']);

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'ilike', "%{$search}%")
                    ->orWhere('description', 'ilike', "%{$search}%");
            });
        }

        if ($sharingType && $sharingType !== 'all') {
            $query->where('sharing_type', $sharingType);
        }

        if ($status && $status !== 'all') {
            if ($status === 'active') {
                $query->where('is_active', true)->where('ends_at', '>=', now());
            } elseif ($status === 'inactive') {
                $query->where('is_active', false);
            } elseif ($status === 'expired') {
                $query->where('ends_at', '<', now());
            }
        }

        $offers = $query->orderBy('created_at', 'desc')->paginate(15);

        return view('tripmanagement::admin.festival-offers.index', compact('offers', 'search', 'sharingType', 'status'));
    }

    public function create()
    {
        $zones = Zone::select('id', 'name')->where('is_active', 1)->get();
        $vehicleCategories = VehicleCategory::select('id', 'name')->where('is_active', 1)->get();

        return view('tripmanagement::admin.festival-offers.create', compact('zones', 'vehicleCategories'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'sharing_type' => 'nullable|in:city,outstation',
            'zone_id' => 'nullable|uuid',
            'vehicle_category_id' => 'nullable|uuid',
            'offer_type' => 'required|in:discount_percent,flat_discount,per_seat_discount',
            'offer_value' => 'required|numeric|min:0',
            'max_discount_amount' => 'nullable|numeric|min:0',
            'min_fare_amount' => 'nullable|numeric|min:0',
            'max_uses_total' => 'nullable|integer|min:0',
            'max_uses_per_user' => 'nullable|integer|min:0',
            'starts_at' => 'required|date',
            'ends_at' => 'required|date|after:starts_at',
            'is_active' => 'nullable',
            'banner_image' => 'nullable|string|max:500',
        ]);

        $data = $request->only([
            'name', 'description', 'sharing_type', 'zone_id', 'vehicle_category_id',
            'offer_type', 'offer_value', 'max_discount_amount', 'min_fare_amount',
            'max_uses_total', 'max_uses_per_user', 'starts_at', 'ends_at', 'banner_image',
        ]);

        $data['is_active'] = $request->has('is_active') ? 1 : 0;
        $data['current_uses'] = 0;
        $data['max_uses_total'] = $data['max_uses_total'] ?? 0;
        $data['max_uses_per_user'] = $data['max_uses_per_user'] ?? 0;

        FestivalOffer::create($data);

        return redirect()->route('admin.trip.festival-offers.index')
            ->with('success', translate('festival_offer_created_successfully'));
    }

    public function edit(string $id)
    {
        $offer = FestivalOffer::findOrFail($id);
        $zones = Zone::select('id', 'name')->where('is_active', 1)->get();
        $vehicleCategories = VehicleCategory::select('id', 'name')->where('is_active', 1)->get();

        return view('tripmanagement::admin.festival-offers.edit', compact('offer', 'zones', 'vehicleCategories'));
    }

    public function update(Request $request, string $id)
    {
        $offer = FestivalOffer::findOrFail($id);

        $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'sharing_type' => 'nullable|in:city,outstation',
            'zone_id' => 'nullable|uuid',
            'vehicle_category_id' => 'nullable|uuid',
            'offer_type' => 'required|in:discount_percent,flat_discount,per_seat_discount',
            'offer_value' => 'required|numeric|min:0',
            'max_discount_amount' => 'nullable|numeric|min:0',
            'min_fare_amount' => 'nullable|numeric|min:0',
            'max_uses_total' => 'nullable|integer|min:0',
            'max_uses_per_user' => 'nullable|integer|min:0',
            'starts_at' => 'required|date',
            'ends_at' => 'required|date|after:starts_at',
            'is_active' => 'nullable',
            'banner_image' => 'nullable|string|max:500',
        ]);

        $data = $request->only([
            'name', 'description', 'sharing_type', 'zone_id', 'vehicle_category_id',
            'offer_type', 'offer_value', 'max_discount_amount', 'min_fare_amount',
            'max_uses_total', 'max_uses_per_user', 'starts_at', 'ends_at', 'banner_image',
        ]);

        $data['is_active'] = $request->has('is_active') ? 1 : 0;
        $data['max_uses_total'] = $data['max_uses_total'] ?? 0;
        $data['max_uses_per_user'] = $data['max_uses_per_user'] ?? 0;

        $offer->update($data);

        return redirect()->route('admin.trip.festival-offers.index')
            ->with('success', translate('festival_offer_updated_successfully'));
    }

    public function toggleStatus(string $id)
    {
        $offer = FestivalOffer::findOrFail($id);
        $offer->update(['is_active' => !$offer->is_active]);

        return back()->with('success', translate('status_updated_successfully'));
    }

    public function destroy(string $id)
    {
        $offer = FestivalOffer::findOrFail($id);
        $offer->delete();

        return back()->with('success', translate('festival_offer_deleted_successfully'));
    }
}
