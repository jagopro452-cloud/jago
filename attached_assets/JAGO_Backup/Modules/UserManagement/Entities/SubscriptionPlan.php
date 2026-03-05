<?php

namespace Modules\UserManagement\Entities;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class SubscriptionPlan extends Model
{
    use HasFactory, HasUuid;

    protected $fillable = [
        'name',
        'description',
        'duration_type',
        'duration_days',
        'price',
        'max_rides',
        'is_active',
    ];

    protected $casts = [
        'duration_days' => 'integer',
        'price' => 'float',
        'max_rides' => 'integer',
        'is_active' => 'boolean',
    ];

    public function subscriptions()
    {
        return $this->hasMany(DriverSubscription::class, 'plan_id');
    }
}
