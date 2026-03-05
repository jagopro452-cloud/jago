<?php

namespace Modules\TripManagement\Entities;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class SharingFareProfile extends Model
{
    use HasUuids;

    protected $table = 'sharing_fare_profiles';

    protected $fillable = [
        'zone_id',
        'vehicle_category_id',
        'sharing_type',
        'base_fare_per_seat',
        'per_km_fare_per_seat',
        'discount_percent',
        'commission_percent',
        'gst_percent',
        'min_fare_per_seat',
        'max_detour_km',
        'min_distance_km',
        'max_distance_km',
        'is_active',
    ];

    protected $casts = [
        'base_fare_per_seat' => 'float',
        'per_km_fare_per_seat' => 'float',
        'discount_percent' => 'float',
        'commission_percent' => 'float',
        'gst_percent' => 'float',
        'min_fare_per_seat' => 'float',
        'max_detour_km' => 'float',
        'min_distance_km' => 'float',
        'max_distance_km' => 'float',
        'is_active' => 'boolean',
    ];

    public function zone()
    {
        return $this->belongsTo(\Modules\ZoneManagement\Entities\Zone::class, 'zone_id');
    }

    public function vehicleCategory()
    {
        return $this->belongsTo(\Modules\VehicleManagement\Entities\VehicleCategory::class, 'vehicle_category_id');
    }
}
