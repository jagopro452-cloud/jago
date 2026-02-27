<?php

namespace Modules\BusinessManagement\Entities;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class B2bParcelPlan extends Model
{
    use HasUuid, SoftDeletes;

    protected $fillable = [
        'plan_name', 'plan_code', 'description', 'monthly_fee', 'included_deliveries',
        'per_delivery_rate', 'discount_percent', 'priority_pickup', 'dedicated_support',
        'api_access', 'max_weight_kg', 'is_active', 'sort_order',
    ];

    protected $casts = [
        'monthly_fee' => 'float',
        'per_delivery_rate' => 'float',
        'discount_percent' => 'float',
        'priority_pickup' => 'boolean',
        'dedicated_support' => 'boolean',
        'api_access' => 'boolean',
        'is_active' => 'boolean',
    ];
}
