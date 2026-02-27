<?php

namespace Modules\FareManagement\Entities;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;
use Modules\VehicleManagement\Entities\VehicleCategory;
use Modules\ZoneManagement\Entities\Zone;

class ParcelFare extends Model
{
    use HasFactory, HasUuid, SoftDeletes;

    protected $fillable = [
        'zone_id',
        'vehicle_category_id',
        'vehicle_category_name',
        'base_fare',
        'return_fee',
        'cancellation_fee',
        'base_fare_per_km',
        'per_minute_rate',
        'minimum_fare',
        'cancellation_fee_percent',
        'min_cancellation_fee',
        'pickup_charge_per_km',
        'pickup_free_distance',
        'waiting_fee_per_min',
        'deleted_at',
        'created_at',
        'updated_at',
    ];

    protected $casts = [
        'base_fare' => 'float',
        'cancellation_fee' => 'float',
        'base_fare_per_km' => 'float',
        'per_minute_rate' => 'float',
        'minimum_fare' => 'float',
        'cancellation_fee_percent' => 'float',
        'min_cancellation_fee' => 'float',
        'pickup_charge_per_km' => 'float',
        'pickup_free_distance' => 'float',
        'waiting_fee_per_min' => 'float',
    ];

    protected static function newFactory()
    {
        return \Modules\FareManagement\Database\factories\ParcelFareFactory::new();
    }

    public function fares()
    {
        return $this->hasMany(ParcelFareWeight::class, 'parcel_fare_id');
    }
    public function zone()
    {
        return $this->belongsTo(Zone::class, 'zone_id');
    }

    public function vehicleCategory()
    {
        return $this->belongsTo(VehicleCategory::class, 'vehicle_category_id');
    }
}
