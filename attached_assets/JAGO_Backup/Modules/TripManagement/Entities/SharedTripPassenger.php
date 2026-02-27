<?php

namespace Modules\TripManagement\Entities;

use Illuminate\Database\Eloquent\Model;
use Modules\UserManagement\Entities\User;

class SharedTripPassenger extends Model
{
    protected $fillable = [
        'trip_request_id',
        'shared_group_id',
        'user_id',
        'seats_booked',
        'otp',
        'otp_verified',
        'is_picked_up',
        'is_dropped_off',
        'pickup_lat',
        'pickup_lng',
        'pickup_address',
        'drop_lat',
        'drop_lng',
        'drop_address',
        'fare_amount',
        'distance_km',
        'status',
        'picked_up_at',
        'dropped_off_at',
    ];

    protected $casts = [
        'seats_booked' => 'integer',
        'otp_verified' => 'boolean',
        'is_picked_up' => 'boolean',
        'is_dropped_off' => 'boolean',
        'pickup_lat' => 'float',
        'pickup_lng' => 'float',
        'drop_lat' => 'float',
        'drop_lng' => 'float',
        'fare_amount' => 'float',
        'distance_km' => 'float',
        'picked_up_at' => 'datetime',
        'dropped_off_at' => 'datetime',
    ];

    public function tripRequest()
    {
        return $this->belongsTo(TripRequest::class, 'trip_request_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
