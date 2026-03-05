<?php

namespace Modules\UserManagement\Entities;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class DriverSubscription extends Model
{
    use HasFactory, HasUuid;

    protected $fillable = [
        'driver_id',
        'plan_id',
        'plan_name',
        'duration_type',
        'price_paid',
        'gst_amount',
        'max_rides',
        'rides_used',
        'is_locked',
        'status',
        'started_at',
        'expires_at',
        'payment_transaction_id',
    ];

    protected $casts = [
        'price_paid' => 'float',
        'gst_amount' => 'float',
        'max_rides' => 'integer',
        'rides_used' => 'integer',
        'is_locked' => 'boolean',
        'started_at' => 'datetime',
        'expires_at' => 'datetime',
    ];

    public function driver()
    {
        return $this->belongsTo(User::class, 'driver_id');
    }

    public function plan()
    {
        return $this->belongsTo(SubscriptionPlan::class, 'plan_id');
    }
}
