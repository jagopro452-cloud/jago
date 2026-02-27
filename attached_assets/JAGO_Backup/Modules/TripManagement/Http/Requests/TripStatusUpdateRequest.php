<?php

namespace Modules\TripManagement\Http\Requests;

use App\Enums\TripStatus;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Enum;

class TripStatusUpdateRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'status' => ['required', 'string', new Enum(TripStatus::class)],
            'cancellation_reason' => ['required_if:status,cancelled', 'string', 'max:500'],
        ];
    }

    public function messages(): array
    {
        return [
            'status.required' => 'Trip status is required.',
            'cancellation_reason.required_if' => 'A reason is required when cancelling a trip.',
        ];
    }
}
