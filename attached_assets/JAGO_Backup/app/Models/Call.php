<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Modules\UserManagement\Entities\User;

class Call extends Model
{
    use HasUuid;

    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'trip_request_id',
        'caller_type',
        'caller_id',
        'callee_type',
        'callee_id',
        'call_type',
        'status',
        'started_at',
        'ended_at',
        'duration_seconds',
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'ended_at' => 'datetime',
    ];

    public function caller()
    {
        return $this->belongsTo(User::class, 'caller_id');
    }

    public function callee()
    {
        return $this->belongsTo(User::class, 'callee_id');
    }

    public function tripRequest()
    {
        return $this->belongsTo(\Modules\TripManagement\Entities\TripRequest::class, 'trip_request_id');
    }

    public function signals()
    {
        return $this->hasMany(CallSignal::class);
    }

    public function recordings()
    {
        return $this->hasMany(CallRecording::class);
    }
}
