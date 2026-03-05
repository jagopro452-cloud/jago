<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Modules\UserManagement\Entities\User;

class CallRecording extends Model
{
    use HasUuid;

    protected $keyType = 'string';
    public $incrementing = false;
    public $timestamps = false;

    protected $fillable = [
        'call_id',
        'user_type',
        'user_id',
        'file_path',
        'file_size',
        'duration_seconds',
    ];

    protected $casts = [
        'created_at' => 'datetime',
    ];

    public function call()
    {
        return $this->belongsTo(Call::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
