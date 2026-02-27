<?php

namespace Modules\TripManagement\Entities;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class FestivalOffer extends Model
{
    use HasUuids;

    protected $table = 'festival_offers';

    protected $fillable = [
        'name',
        'description',
        'sharing_type',
        'zone_id',
        'vehicle_category_id',
        'offer_type',
        'offer_value',
        'max_discount_amount',
        'min_fare_amount',
        'max_uses_total',
        'max_uses_per_user',
        'current_uses',
        'starts_at',
        'ends_at',
        'is_active',
        'banner_image',
    ];

    protected $casts = [
        'offer_value' => 'float',
        'max_discount_amount' => 'float',
        'min_fare_amount' => 'float',
        'max_uses_total' => 'integer',
        'max_uses_per_user' => 'integer',
        'current_uses' => 'integer',
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
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

    public function scopeActive($query)
    {
        return $query->where('is_active', true)
            ->where('starts_at', '<=', now())
            ->where('ends_at', '>=', now());
    }

    public function scopeForSharingType($query, ?string $sharingType)
    {
        return $query->where(function ($q) use ($sharingType) {
            $q->whereNull('sharing_type')
                ->orWhere('sharing_type', $sharingType);
        });
    }

    public function isUsable(): bool
    {
        if (!$this->is_active) return false;
        if (now()->lt($this->starts_at) || now()->gt($this->ends_at)) return false;
        if ($this->max_uses_total > 0 && $this->current_uses >= $this->max_uses_total) return false;
        return true;
    }
}
