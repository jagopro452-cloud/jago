<?php

namespace Modules\TripManagement\Service;

use App\Enums\TripStatus;
use Illuminate\Support\Facades\Log;
use Modules\TripManagement\Entities\TripRequest;

class RideStateMachine
{
    public function transition(TripRequest $trip, TripStatus $newStatus, ?string $reason = null): TripRequest
    {
        $currentStatus = $this->resolveStatus($trip);
        if (!$currentStatus) {
            Log::warning('Unknown trip status, allowing transition', [
                'trip_id' => $trip->id,
                'current_status' => $trip->current_status,
                'target_status' => $newStatus->value,
            ]);
        } elseif (!$currentStatus->canTransitionTo($newStatus)) {
            throw new \InvalidArgumentException(
                "Invalid status transition from '{$currentStatus->label()}' to '{$newStatus->label()}' for trip #{$trip->id}"
            );
        }

        $previousStatus = $trip->current_status;
        $trip->current_status = $newStatus->value;

        if ($newStatus === TripStatus::CANCELLED && $reason) {
            $trip->cancellation_reason = $reason;
        }

        $trip->save();

        Log::info('Trip status transition', [
            'trip_id' => $trip->id,
            'from' => $previousStatus,
            'to' => $newStatus->value,
            'reason' => $reason,
        ]);

        return $trip;
    }

    public function canTransition(TripRequest $trip, TripStatus $newStatus): bool
    {
        $currentStatus = $this->resolveStatus($trip);
        if (!$currentStatus) {
            return true;
        }
        return $currentStatus->canTransitionTo($newStatus);
    }

    public function getAvailableTransitions(TripRequest $trip): array
    {
        $currentStatus = $this->resolveStatus($trip);
        if (!$currentStatus) {
            return [];
        }
        return array_map(fn(TripStatus $s) => [
            'status' => $s->value,
            'label' => $s->label(),
        ], $currentStatus->allowedTransitions());
    }

    public function isActive(TripRequest $trip): bool
    {
        $status = $this->resolveStatus($trip);
        return $status ? $status->isActive() : false;
    }

    public function isTerminal(TripRequest $trip): bool
    {
        $status = $this->resolveStatus($trip);
        return $status ? $status->isTerminal() : false;
    }

    private function resolveStatus(TripRequest $trip): ?TripStatus
    {
        try {
            return TripStatus::from($trip->current_status);
        } catch (\ValueError $e) {
            return null;
        }
    }
}
