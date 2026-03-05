<?php

namespace App\Enums;

enum PaymentStatus: string
{
    case PAID = 'paid';
    case UNPAID = 'unpaid';
    case PARTIAL_PAID = 'partial_paid';
    case PENDING = 'pending';
    case REFUNDED = 'refunded';
    case SETTLED = 'settled';
    case DUE = 'due';

    public function isPaid(): bool
    {
        return $this === self::PAID;
    }

    public function isSettled(): bool
    {
        return in_array($this, [self::PAID, self::SETTLED]);
    }

    public function canRefund(): bool
    {
        return in_array($this, [self::PAID, self::SETTLED]);
    }

    public function label(): string
    {
        return match ($this) {
            self::PAID => 'Paid',
            self::UNPAID => 'Unpaid',
            self::PARTIAL_PAID => 'Partially Paid',
            self::PENDING => 'Pending',
            self::REFUNDED => 'Refunded',
            self::SETTLED => 'Settled',
            self::DUE => 'Due',
        };
    }
}
