<?php

namespace Modules\TripManagement\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CreateRideRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'zone_id' => ['required', 'exists:zones,id'],
            'vehicle_category_id' => ['required', 'exists:vehicle_categories,id'],
            'pickup_coordinates' => ['required', 'array'],
            'pickup_coordinates.latitude' => ['required', 'numeric', 'between:-90,90'],
            'pickup_coordinates.longitude' => ['required', 'numeric', 'between:-180,180'],
            'destination_coordinates' => ['required', 'array'],
            'destination_coordinates.latitude' => ['required', 'numeric', 'between:-90,90'],
            'destination_coordinates.longitude' => ['required', 'numeric', 'between:-180,180'],
            'pickup_address' => ['required', 'string', 'max:500'],
            'destination_address' => ['required', 'string', 'max:500'],
            'intermediate_addresses' => ['nullable', 'array', 'max:3'],
            'intermediate_addresses.*.latitude' => ['required', 'numeric', 'between:-90,90'],
            'intermediate_addresses.*.longitude' => ['required', 'numeric', 'between:-180,180'],
            'intermediate_addresses.*.address' => ['required', 'string', 'max:500'],
            'estimated_fare' => ['required', 'numeric', 'min:0'],
            'estimated_distance' => ['required', 'numeric', 'min:0'],
            'ride_request_type' => ['required', 'in:regular,shared'],
            'payment_method' => ['required', 'in:cash,digital,wallet'],
            'note' => ['nullable', 'string', 'max:255'],
            'coupon_id' => ['nullable', 'exists:coupons,id'],
            'schedule_time' => ['nullable', 'date', 'after:now'],
        ];
    }
}
