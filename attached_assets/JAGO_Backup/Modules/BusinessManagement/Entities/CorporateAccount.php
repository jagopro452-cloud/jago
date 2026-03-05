<?php

namespace Modules\BusinessManagement\Entities;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Modules\UserManagement\Entities\User;

class CorporateAccount extends Model
{
    use HasUuid, SoftDeletes;

    protected $fillable = [
        'company_name', 'company_code', 'contact_person', 'contact_email', 'contact_phone',
        'gst_number', 'address', 'city', 'state', 'plan_type', 'discount_percent',
        'credit_limit', 'used_credit', 'billing_cycle', 'ride_allowed', 'parcel_allowed',
        'max_employees', 'active_employees', 'is_active', 'contract_start', 'contract_end', 'notes',
    ];

    protected $casts = [
        'discount_percent' => 'float',
        'credit_limit' => 'float',
        'used_credit' => 'float',
        'ride_allowed' => 'boolean',
        'parcel_allowed' => 'boolean',
        'is_active' => 'boolean',
        'contract_start' => 'date',
        'contract_end' => 'date',
    ];

    public function employees()
    {
        return $this->hasMany(User::class, 'corporate_account_id');
    }

    public function getRemainingCreditAttribute()
    {
        return $this->credit_limit - $this->used_credit;
    }
}
