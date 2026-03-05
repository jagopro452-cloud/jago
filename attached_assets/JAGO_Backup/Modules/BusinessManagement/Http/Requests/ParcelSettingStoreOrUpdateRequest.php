<?php

namespace Modules\BusinessManagement\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;

class ParcelSettingStoreOrUpdateRequest extends FormRequest
{
    /**
     * Get the validation rules that apply to the request.
     */
    public function rules(): array
    {
        return [
            'parcel_return_time_fee_status' => 'nullable',
            'return_time_for_driver' => [Rule::requiredIf(function () {
                return ($this->input('type') === PARCEL_SETTINGS && ($this->customer_referral_earning_status ?? false));
            }), 'integer'],
            'return_time_type_for_driver' => [Rule::requiredIf(function () {
                return ($this->input('type') === PARCEL_SETTINGS && ($this->customer_referral_earning_status ?? false));
            }), 'string'],
            'return_fee_for_driver_time_exceed' => [Rule::requiredIf(function () {
                return ($this->input('type') === PARCEL_SETTINGS && ($this->customer_referral_earning_status ?? false));
            }), 'numeric'],
            'do_not_charge_customer_return_fee' => 'sometimes|in:on',
            'parcel_receiver_otp_verification' => 'sometimes|in:on',
            'senior_citizen_discount_enabled' => 'nullable',
            'senior_citizen_discount_percent' => 'nullable|numeric|gte:0|lte:50',
            'senior_citizen_min_age' => 'nullable|numeric|gte:50|lte:100',
            'student_discount_enabled' => 'nullable',
            'student_discount_percent' => 'nullable|numeric|gte:0|lte:50',
            'outstation_service_enabled' => 'nullable',
            'outstation_min_distance_km' => 'nullable|numeric|gte:10',
            'outstation_fare_multiplier' => 'nullable|numeric|gte:1|lte:5',
        ];
    }

    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return Auth::check();
    }
}
