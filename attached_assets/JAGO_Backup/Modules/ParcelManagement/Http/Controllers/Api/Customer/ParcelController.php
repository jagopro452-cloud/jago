<?php

namespace Modules\ParcelManagement\Http\Controllers\Api\Customer;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Validator;
use Modules\FareManagement\Service\Interfaces\ParcelFareServiceInterface;
use Modules\ParcelManagement\Service\Interfaces\ParcelWeightServiceInterface;
use Modules\VehicleManagement\Service\Interfaces\VehicleCategoryServiceInterface;
use Modules\VehicleManagement\Service\Interfaces\VehicleModelServiceInterface;

class ParcelController extends Controller
{

    protected $vehicleCategoryService;
    protected $vehicleModelService;
    protected $parcelWeightService;
    protected $parcelFareService;

    public function __construct(VehicleCategoryServiceInterface $vehicleCategoryService, VehicleModelServiceInterface $vehicleModelService, ParcelWeightServiceInterface $parcelWeightService, ParcelFareServiceInterface $parcelFareService)
    {
        $this->vehicleCategoryService = $vehicleCategoryService;
        $this->vehicleModelService = $vehicleModelService;
        $this->parcelWeightService = $parcelWeightService;
        $this->parcelFareService = $parcelFareService;
    }

    public function vehicleList(Request $request)
    {
        if (empty($request->header('zoneId'))) {

            return response()->json(responseFormatter(ZONE_404), 200);
        }

        $parcelWeight = $this->parcelWeightService->findOne(id: $request['weight_id']);
        if (!$parcelWeight) {
            return response()->json(responseFormatter(PARCEL_WEIGHT_400), 403);
        }

        $criteria = [
            ['maximum_weight', '>=', $parcelWeight->max_weight],
            ['is_active', 1],
        ];

        $vehicleModels = $this->vehicleModelService->getBy(criteria: $criteria);
        if (count($vehicleModels) < 1) {
            return response()->json(responseFormatter(PARCEL_WEIGHT_400), 403);
        }


        $relations = [
            'vehicles.driver',
            'vehicles.model' => [
                ['maximum_weight', '>', $parcelWeight->max_weight],
            ]
        ];

        $categories = $this->vehicleCategoryService->getBy(criteria: ['is_active' => 1], relations: $relations, limit: $request['limit'], offset: $request['offset']);

        return response()->json(responseFormatter(constant: DEFAULT_200, content: $categories, limit: $request['limit'], offset: $request['offset']));
    }

    public function suggestedVehicleCategory(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'parcel_weight' => 'required',

        ]);
        if ($validator->fails()) {
            return response()->json(responseFormatter(constant: DEFAULT_400, errors: errorProcessor($validator)), 400);
        }
        $criteria = [
            'is_active' => 1
        ];
        $relations = [
            'vehicles.model'
        ];
        $whereHasRelations = [
            'vehicles.model' => [['maximum_weight', '>=', $request->parcel_weight]]
        ];
        $vehicleCategory = $this->vehicleCategoryService->getBy(criteria: $criteria, whereHasRelations: $whereHasRelations, relations: $relations,limit: 9999,offset: 1);

        return response()->json(responseFormatter(constant: DEFAULT_200, content: $vehicleCategory));
    }

    public function parcelVehicleTypes(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'zone_id' => 'required',
        ]);
        if ($validator->fails()) {
            return response()->json(responseFormatter(constant: DEFAULT_400, errors: errorProcessor($validator)), 400);
        }

        $parcelFares = $this->parcelFareService->getBy(
            criteria: ['zone_id' => $request->zone_id],
            relations: ['vehicleCategory'],
            limit: 9999,
            offset: 1
        );

        $vehicleTypes = $parcelFares->filter(fn($fare) => $fare->vehicle_category_id !== null)->map(function ($fare) {
            return [
                'vehicle_category_id' => $fare->vehicle_category_id,
                'vehicle_category_name' => $fare->vehicle_category_name ?? $fare->vehicleCategory?->name,
                'vehicle_category_type' => $fare->vehicleCategory?->type,
                'vehicle_category_image' => $fare->vehicleCategory?->image,
                'base_fare' => $fare->base_fare,
                'base_fare_per_km' => $fare->base_fare_per_km,
                'per_minute_rate' => $fare->per_minute_rate,
                'minimum_fare' => $fare->minimum_fare,
                'return_fee' => $fare->return_fee,
            ];
        })->values();

        return response()->json(responseFormatter(constant: DEFAULT_200, content: $vehicleTypes));
    }
}
