<?php

namespace Modules\FareManagement\Service;

use App\Service\BaseService;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;
use Modules\FareManagement\Repository\ParcelFareRepositoryInterface;

class ParcelFareService extends BaseService implements Interfaces\ParcelFareServiceInterface
{
    protected $parcelFareRepository;

    public function __construct(ParcelFareRepositoryInterface $parcelFareRepository)
    {
        parent::__construct($parcelFareRepository);
        $this->parcelFareRepository = $parcelFareRepository;
    }

    public function create(array $data): ?Model
    {
        DB::beginTransaction();
        $criteria = ['zone_id' => $data['zone_id']];
        if (!empty($data['vehicle_category_id'])) {
            $criteria['vehicle_category_id'] = $data['vehicle_category_id'];
        }
        $fare = $this->parcelFareRepository->findOneBy(criteria: $criteria);
        $parcelFareData = [
            "zone_id" => $data['zone_id'],
            "vehicle_category_id" => $data['vehicle_category_id'] ?? null,
            "vehicle_category_name" => $data['vehicle_category_name'] ?? null,
            "base_fare" => $data['base_fare'],
            "return_fee" => $data['return_fee'],
            "cancellation_fee" => $data['cancellation_fee'] ?? 0,
            "base_fare_per_km" => $data['base_fare_per_km'] ?? 0,
            "per_minute_rate" => $data['per_minute_rate'] ?? 0,
            "minimum_fare" => $data['minimum_fare'] ?? 0,
            "cancellation_fee_percent" => $data['cancellation_fee_percent'] ?? 0,
            "min_cancellation_fee" => $data['min_cancellation_fee'] ?? 0,
        ];
        if (is_null($fare)) {
            $parcelFare = $this->parcelFareRepository->create(data: $parcelFareData);
        } else {
            $parcelFare = $this->parcelFareRepository->update(id: $fare->id, data: $parcelFareData);
            $fare->fares()->delete();
        }


        foreach ($data['parcel_category'] as $category) {
            if (array_key_exists('weight_' . $category, $data)) {
                foreach ($data['parcel_weight'] as $weight) {
                    if (array_key_exists($weight['id'], $data['weight_' . $category])) {
                        $parcelFare?->fares()->create([
                            'parcel_weight_id' => $weight->id,
                            'parcel_category_id' => $category,
                            'base_fare' => $data['base_fare_' . $category] ?? 0,
                            'return_fee' => $data['return_fee'] ?? 0,
                            'cancellation_fee' => $data['cancellation_fee'] ?? 0,
                            'fare_per_km' => $data['weight_' . $category][$weight->id] ?? 0,
                            'zone_id' => $data['zone_id']
                        ]);
                    }
                }
            }
        }
        DB::commit();
        return $parcelFare;
    }
}
