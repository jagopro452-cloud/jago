<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class CallSignal extends Model
{
    use HasUuid;

    protected $keyType = 'string';
    public $incrementing = false;
    public $timestamps = false;

    protected $fillable = [
        'call_id',
        'sender_type',
        'sender_id',
        'signal_type',
        'payload',
        'consumed_at',
    ];

    protected $casts = [
        'payload' => 'array',
        'created_at' => 'datetime',
        'consumed_at' => 'datetime',
    ];

    public function call()
    {
        return $this->belongsTo(Call::class);
    }
}
