<?php

namespace App\Enums;

enum TripType: string
{
    case RIDE_REQUEST = 'ride_request';
    case PARCEL = 'parcel';

    public function label(): string
    {
        return match ($this) {
            self::RIDE_REQUEST => 'Ride Request',
            self::PARCEL => 'Parcel',
        };
    }
}
