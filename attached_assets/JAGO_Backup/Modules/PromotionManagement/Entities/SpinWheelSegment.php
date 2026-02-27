<?php

namespace Modules\PromotionManagement\Entities;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class SpinWheelSegment extends Model
{
    use HasUuid;

    protected $fillable = [
        'spin_wheel_config_id',
        'label',
        'amount',
        'color',
        'weight',
        'is_active',
        'sort_order',
    ];

    protected $casts = [
        'amount' => 'float',
        'weight' => 'integer',
        'is_active' => 'boolean',
        'sort_order' => 'integer',
    ];

    public function config()
    {
        return $this->belongsTo(SpinWheelConfig::class, 'spin_wheel_config_id');
    }
}
