<?php

namespace Modules\PromotionManagement\Entities;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class SpinWheelConfig extends Model
{
    use HasUuid;

    protected $fillable = [
        'is_active',
        'title',
        'subtitle',
        'min_discount',
        'max_discount',
        'spins_per_day',
        'max_total_per_user',
        'ride_completion_required',
        'segments',
        'segment_colors',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'segments' => 'array',
        'segment_colors' => 'array',
        'min_discount' => 'integer',
        'max_discount' => 'integer',
        'spins_per_day' => 'integer',
        'max_total_per_user' => 'float',
        'ride_completion_required' => 'boolean',
    ];

    public function segmentItems()
    {
        return $this->hasMany(SpinWheelSegment::class, 'spin_wheel_config_id')->orderBy('sort_order');
    }
}
