<?php

namespace App\Enums;

enum TripStatus: string
{
    case PENDING = 'pending';
    case ACCEPTED = 'accepted';
    case ONGOING = 'ongoing';
    case COMPLETED = 'completed';
    case CANCELLED = 'cancelled';
    case RETURNING = 'returning';
    case RETURNED = 'returned';
    case OUT_FOR_PICKUP = 'out_for_pickup';
    case SCHEDULED = 'scheduled';

    public function canTransitionTo(self $target): bool
    {
        return in_array($target, $this->allowedTransitions());
    }

    public function allowedTransitions(): array
    {
        return match ($this) {
            self::PENDING => [self::ACCEPTED, self::CANCELLED, self::SCHEDULED],
            self::SCHEDULED => [self::ACCEPTED, self::CANCELLED],
            self::ACCEPTED => [self::ONGOING, self::OUT_FOR_PICKUP, self::CANCELLED],
            self::OUT_FOR_PICKUP => [self::ONGOING, self::CANCELLED],
            self::ONGOING => [self::COMPLETED, self::CANCELLED, self::RETURNING],
            self::RETURNING => [self::RETURNED, self::CANCELLED],
            self::RETURNED => [],
            self::COMPLETED => [],
            self::CANCELLED => [],
        };
    }

    public function isActive(): bool
    {
        return in_array($this, [self::PENDING, self::ACCEPTED, self::ONGOING, self::OUT_FOR_PICKUP, self::SCHEDULED]);
    }

    public function isTerminal(): bool
    {
        return in_array($this, [self::COMPLETED, self::CANCELLED, self::RETURNED]);
    }

    public function label(): string
    {
        return match ($this) {
            self::PENDING => 'Pending',
            self::ACCEPTED => 'Accepted',
            self::ONGOING => 'Ongoing',
            self::COMPLETED => 'Completed',
            self::CANCELLED => 'Cancelled',
            self::RETURNING => 'Returning',
            self::RETURNED => 'Returned',
            self::OUT_FOR_PICKUP => 'Out for Pickup',
            self::SCHEDULED => 'Scheduled',
        };
    }
}
