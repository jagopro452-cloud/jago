<?php

namespace Modules\FareManagement\Service\Interfaces;

use App\Service\BaseServiceInterface;
use Illuminate\Database\Eloquent\Model;

interface SurgePricingServiceInterface extends BaseServiceInterface
{
    public function checkSurgePricing(int|string $zoneId, int|string $tripType, int|string $vehicleCategoryId = null, $scheduledAt = null): array;

    public function updatesSurgePricing(int|string $id, array $data = []): ?Model;

    public function updateZone(string|int $id, array $data): ?Model;
}
