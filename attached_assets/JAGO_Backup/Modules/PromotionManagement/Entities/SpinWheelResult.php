<?php

namespace Modules\PromotionManagement\Entities;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Modules\UserManagement\Entities\User;
use Modules\TripManagement\Entities\TripRequest;
use Modules\TransactionManagement\Entities\Transaction;

class SpinWheelResult extends Model
{
    use HasUuid;

    protected $fillable = [
        'user_id',
        'trip_request_id',
        'discount_value',
        'wallet_amount',
        'transaction_id',
    ];

    protected $casts = [
        'discount_value' => 'integer',
        'wallet_amount' => 'float',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function trip()
    {
        return $this->belongsTo(TripRequest::class, 'trip_request_id');
    }

    public function transaction()
    {
        return $this->belongsTo(Transaction::class, 'transaction_id');
    }
}
