<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Modules\UserManagement\Entities\User;
use Modules\TripManagement\Entities\TripRequest;

class DriverOverchargeReport extends Model
{
    use HasUuid;

    protected $table = 'driver_overcharge_reports';
    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'trip_request_id',
        'customer_id',
        'driver_id',
        'reported_amount',
        'description',
        'status',
        'admin_action',
        'admin_notes',
    ];

    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function driver()
    {
        return $this->belongsTo(User::class, 'driver_id');
    }

    public function tripRequest()
    {
        return $this->belongsTo(TripRequest::class, 'trip_request_id');
    }
}
