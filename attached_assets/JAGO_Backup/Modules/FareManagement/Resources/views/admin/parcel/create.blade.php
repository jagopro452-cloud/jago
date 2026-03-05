@extends('adminmodule::layouts.master')

@section('title', translate('Parcel_Delivery_Fare_Setup'))

@section('content')
    @php
        $unit = businessConfig('parcel_weight_unit', PARCEL_SETTINGS)?->value ?? 'kg';
        $symbol = (session()->get('currency_symbol') ?? businessConfig('currency_symbol', 'business_information')?->value) ?? "₹";
    @endphp

    <div class="main-content">
        <div class="container-fluid">
            <h2 class="fs-22 mb-4 text-capitalize">{{ translate('parcel_delivery_fare_setup') }} - <span
                    class="text-primary">{{ $zone->name }} {{ translate('zone') }}</span></h2>

            <div class="card mb-3">
                <div class="card-header">
                    <h5 class="mb-2 text-capitalize">{{ translate('select_vehicle_type') }}</h5>
                    <div class="fs-12 mb-3">{{ translate('Set up separate fares for each vehicle type like Porter. Customers will choose their preferred vehicle when booking a parcel.') }}</div>
                    <div class="d-flex flex-wrap gap-2">
                        @foreach($vehicleCategories as $vc)
                            @php
                                $hasFare = $allFaresForZone->where('vehicle_category_id', $vc->id)->first();
                            @endphp
                            <a href="{{ route('admin.fare.parcel.create', ['zone_id' => $zone->id]) }}?vehicle_category_id={{ $vc->id }}"
                               class="btn {{ $selectedVehicle == $vc->id ? 'btn-primary' : ($hasFare ? 'btn-outline-success' : 'btn-outline-primary') }} btn-sm">
                                @if($hasFare)
                                    <i class="bi bi-check-circle me-1"></i>
                                @endif
                                {{ $vc->name }}
                            </a>
                        @endforeach
                    </div>
                </div>
            </div>

            @if($allFaresForZone->count() > 0)
            <div class="card mb-3">
                <div class="card-header">
                    <h5 class="mb-2 text-capitalize">{{ translate('configured_vehicle_fares') }}</h5>
                </div>
                <div class="card-body">
                    <div class="table-responsive">
                        <table class="table table-bordered table-sm">
                            <thead>
                                <tr>
                                    <th>{{ translate('vehicle_type') }}</th>
                                    <th>{{ translate('base_fare') }} ({{ $symbol }})</th>
                                    <th>{{ translate('per_km') }} ({{ $symbol }})</th>
                                    <th>{{ translate('per_min') }} ({{ $symbol }})</th>
                                    <th>{{ translate('minimum_fare') }} ({{ $symbol }})</th>
                                    <th>{{ translate('status') }}</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($allFaresForZone as $existingFare)
                                <tr>
                                    <td>
                                        <span class="badge bg-primary">{{ $existingFare->vehicle_category_name ?? $existingFare->vehicleCategory?->name ?? translate('default') }}</span>
                                    </td>
                                    <td>{{ $symbol }}{{ number_format($existingFare->base_fare, 2) }}</td>
                                    <td>{{ $symbol }}{{ number_format($existingFare->base_fare_per_km, 2) }}</td>
                                    <td>{{ $symbol }}{{ number_format($existingFare->per_minute_rate ?? 0, 2) }}</td>
                                    <td>{{ $symbol }}{{ number_format($existingFare->minimum_fare ?? 0, 2) }}</td>
                                    <td><span class="badge bg-success">{{ translate('configured') }}</span></td>
                                </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            @endif

            @if($selectedVehicle)
            @php
                $selectedVehicleName = $vehicleCategories->where('id', $selectedVehicle)->first()?->name ?? '';
            @endphp
            <form action="{{ route('admin.fare.parcel.store') }}" method="post">
                @csrf
                <input type="hidden" name="zone_id" value="{{ $zone->id }}">
                <input type="hidden" name="vehicle_category_id" value="{{ $selectedVehicle }}">

                <div class="card mb-3">
                    <div class="card-header">
                        <h5 class="mb-2 text-capitalize">
                            <i class="bi bi-truck me-1"></i>
                            {{ translate('fare_setup_for') }} <span class="text-primary">{{ $selectedVehicleName }}</span>
                        </h5>
                    </div>
                    <div class="card-body">
                        <h5 class="mb-3 text-capitalize">{{ translate('parcel_categories_for_this_vehicle') }}</h5>
                        <div class="d-flex flex-wrap align-items-center gap-4 gap-xl-5 mb-4">
                            @forelse($parcelCategory as $pc)
                                @if ($pc->is_active)
                                    <label class="custom-checkbox">
                                        <input type="checkbox" name="parcel_category[]" value="{{ $pc->id }}"
                                            @forelse($fares?->fares?? [] as $fare)
                                                   @if ($fare->parcel_category_id == $pc->id)
                                                       checked
                                            @endif
                                        @empty
                                            @endforelse>
                                        {{ $pc->name }}
                                    </label>
                                @endif
                            @empty
                            @endforelse
                        </div>

                        <h5 class="mb-3 text-capitalize">{{ translate('default_fare_setup') }}</h5>
                        <div class="row gy-4">
                            <div class="col-sm-6 col-lg-4 category-fare-class">
                                <label for="base_fare" class="form-label">{{ translate('Base_Fare') }} ({{ $symbol }})</label>
                                <div class="input-group_tooltip">
                                    <input type="number" class="form-control" name="base_fare" id="base_fare"
                                           value="{{ $fares?->base_fare + 0 }}" placeholder="{{ translate('Base_Fare') }}"
                                           step=".01" min="0.01" max="99999999" required>
                                    <i class="bi bi-info-circle-fill text-primary tooltip-icon" data-bs-toggle="tooltip"
                                       data-bs-title="{{ translate('base_fare_charged_when_customer_books_this_vehicle') }}"></i>
                                </div>
                            </div>
                            <div class="col-sm-6 col-lg-4 category-fare-class">
                                <label for="base_fare_per_km" class="form-label">{{ translate('fare_per_km') }} ({{ $symbol }})</label>
                                <div class="input-group_tooltip">
                                    <input type="number" class="form-control" name="base_fare_per_km" id="base_fare_per_km"
                                           value="{{ $fares?->base_fare_per_km + 0 }}" placeholder="{{ translate('fare_per_km') }}"
                                           step=".01" min="0" max="99999999">
                                    <i class="bi bi-info-circle-fill text-primary tooltip-icon" data-bs-toggle="tooltip"
                                       data-bs-title="{{ translate('charge_per_kilometer_for_this_vehicle_type') }}"></i>
                                </div>
                            </div>
                            <div class="col-sm-6 col-lg-4 category-fare-class">
                                <label for="per_minute_rate" class="form-label">{{ translate('per_minute_rate') }} ({{ $symbol }})</label>
                                <div class="input-group_tooltip">
                                    <input type="number" class="form-control" name="per_minute_rate" id="per_minute_rate"
                                           value="{{ $fares?->per_minute_rate + 0 }}" placeholder="{{ translate('per_minute_rate') }}"
                                           step=".01" min="0" max="99999999">
                                    <i class="bi bi-info-circle-fill text-primary tooltip-icon" data-bs-toggle="tooltip"
                                       data-bs-title="{{ translate('charge_per_minute_for_this_vehicle_type') }}"></i>
                                </div>
                            </div>
                            <div class="col-sm-6 col-lg-4 category-fare-class">
                                <label for="minimum_fare" class="form-label">{{ translate('minimum_fare') }} ({{ $symbol }})</label>
                                <div class="input-group_tooltip">
                                    <input type="number" class="form-control" name="minimum_fare" id="minimum_fare"
                                           value="{{ $fares?->minimum_fare + 0 }}" placeholder="{{ translate('minimum_fare') }}"
                                           step=".01" min="0" max="99999999">
                                    <i class="bi bi-info-circle-fill text-primary tooltip-icon" data-bs-toggle="tooltip"
                                       data-bs-title="{{ translate('minimum_amount_charged_regardless_of_distance') }}"></i>
                                </div>
                            </div>
                            <div class="col-sm-6 col-lg-4 parcel-fare-setup-class">
                                <label for="return_fee" class="form-label">{{ translate('return_fee') }} (%)</label>
                                <div class="input-group_tooltip">
                                    <input type="number" class="form-control" name="return_fee" id="return_fee"
                                           value="{{ $fares?->return_fee + 0 }}" placeholder="{{ translate('return_fee') }}"
                                           step=".01" min="0" max="100" required>
                                    <i class="bi bi-info-circle-fill text-primary tooltip-icon" data-bs-toggle="tooltip"
                                       data-bs-title="{{ translate('return_fee_percentage_charged_if_parcel_is_returned') }}"></i>
                                </div>
                            </div>
                            <div class="col-sm-6 col-lg-4 parcel-fare-setup-class">
                                <label for="cancellation_fee_percent" class="form-label">{{ translate('cancellation_fee') }} (%)</label>
                                <div class="input-group_tooltip">
                                    <input type="number" class="form-control" name="cancellation_fee_percent" id="cancellation_fee_percent"
                                           value="{{ $fares?->cancellation_fee_percent + 0 }}" placeholder="{{ translate('cancellation_fee_percent') }}"
                                           step=".01" min="0" max="100">
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="card">
                    <div class="card-header">
                        <h5 class="text-capitalize mb-2">
                            {{ translate('category_wise_delivery_fee_for') }} {{ $selectedVehicleName }}
                        </h5>
                        <div class="fs-12">
                            {{ translate("Set price per km for each parcel category and weight range") }}
                        </div>
                    </div>
                    <div class="card-body p-4">
                        <div class="table-responsive border border-primary-light rounded">
                            <table class="table align-middle table-borderless table-variation">
                                <thead class="border-bottom border-primary-light">
                                    <tr>
                                        <th>{{ translate('fare') }}</th>
                                        <th>
                                            {{ translate('base_fare') }}
                                            <span class="fs-10">/{{ translate($unit) }}</span>
                                            ({{ $symbol }})
                                        </th>
                                        @forelse($parcelWeight as $pw)
                                            @if ($pw['is_active'] == 1)
                                                <th>{{ $pw->min_weight + 0 . '-' . ($pw->max_weight + 0) . ' /' . translate($unit) }}
                                                </th>
                                            @endif
                                        @empty
                                        @endforelse
                                    </tr>
                                </thead>
                                <tbody>
                                    @forelse($parcelCategory as $pc)
                                        @if ($pc->is_active)
                                            @php($fare = $fares?->fares->where('parcel_category_id', $pc->id)->first())
                                            <tr>
                                                <td
                                                    class="{{ $pc->id }} {{ $fare?->parcel_category_id == $pc->id ? '' : 'd-none' }}">
                                                    <div
                                                        class="d-flex align-items-center gap-2 text-primary fw-semibold">
                                                        <div>{{ translate($pc->name) }} <span class="fs-10">/
                                                                km</span> ({{ $symbol }}) </div>
                                                        <i class="bi bi-info-circle-fill fs-14" data-bs-toggle="tooltip"
                                                            data-bs-title="{{ translate('set_the_fare_for_each_kilometer_added_with_the_base_fare') }}"></i>
                                                    </div>
                                                </td>
                                                <td
                                                    class="category-fare-class {{ $pc->id }} {{ $fare?->parcel_category_id == $pc->id ? '' : 'd-none' }}">
                                                    <input type="number" name="base_fare_{{ $pc->id }}"
                                                        value="{{ $fare?->base_fare ?? $fares?->base_fare }}"
                                                        class="form-control base_fare" step=".01" min="0.01"
                                                        max="99999999" required>
                                                </td>
                                                @forelse($parcelWeight as $pw)
                                                    @php($weightFare = $fares?->fares->where('parcel_weight_id', $pw->id)->where('parcel_category_id', $pc->id)->first()
)
                                                    @if ($pw->is_active == 1)
                                                        <td
                                                            class="category-fare-class {{ $pc->id }} {{ $fare?->parcel_category_id == $pc->id ? '' : 'd-none' }}">
                                                            <input type="number"
                                                                name="weight_{{ $pc->id }}[{{ $pw->id }}]"
                                                                class="form-control {{ $pc->id }}"
                                                                value="{{ $weightFare?->fare_per_km + 0 }}"
                                                                step=".01" min="0.01" max="99999999"
                                                                {{ $pc->id }}
                                                                {{ $fare?->parcel_category_id == $pc->id ? '' : 'disabled' }}
                                                                required>
                                                        </td>
                                                    @endif
                                                @empty
                                                @endforelse
                                            </tr>
                                        @endif

                                    @empty
                                    @endforelse
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <div class="footer-sticky">
                    <div class="container-fluid">
                        <div class="d-flex justify-content-end gap-2 py-4">
                            <button type="button" class="btn btn-light btn-lg fw-semibold"
                                data-bs-dismiss="modal">{{ translate('reset') }}</button>
                            <button type="submit"
                                class="btn btn-primary btn-lg fw-semibold">{{ translate('save_fare_for') }} {{ $selectedVehicleName }}</button>
                        </div>
                    </div>
                </div>
            </form>
            @else
            <div class="card">
                <div class="card-body text-center py-5">
                    <i class="bi bi-truck fs-1 text-muted mb-3 d-block"></i>
                    <h5 class="text-muted">{{ translate('select_a_vehicle_type_above_to_set_up_fares') }}</h5>
                    <p class="text-muted fs-12">{{ translate('each_vehicle_type_has_its_own_fare_structure_like_porter') }}</p>
                </div>
            </div>
            @endif
        </div>
    </div>

@endsection

@push('script')
    <script src="{{ dynamicAsset('public/assets/admin-module/js/fare-management/parcel/create.js') }}"></script>
    <script>
        "use strict";
        $("form").submit(function() {
            if ($('input[type="checkbox"]:checked').length <= 0) {
                toastr.error('{{ translate('must_select_at_least_one_parcel_category') }}')
                return false;
            }
        });

        const inputParcelElements = document.querySelectorAll('.parcel-fare-setup-class input[type="number"]');

        inputParcelElements.forEach(input => {
            input.addEventListener('input', function() {
                if (parseFloat(this.value) < 0) {
                    toastr.error('{{ translate('the_value_must_greater_than_or_equal_0') }}')
                }
            });
        });

        const inputCategoryElements = document.querySelectorAll('.category-fare-class input[type="number"]');

        inputCategoryElements.forEach(input => {
            input.addEventListener('input', function() {
                if (parseFloat(this.value) <= 0) {
                    toastr.error('{{ translate('the_value_must_greater_than_0') }}')
                }
            });
        });
    </script>
   <script>
        "use strict";
        $(document).ready(function() {
            $(window).on('scroll', function() {
                const $footer = $('.footer-sticky');
                const scrollPosition = $(window).scrollTop() + $(window).height();
                const documentHeight = $(document).height();

                if (scrollPosition >= documentHeight - 5) {
                    $footer.addClass('no-shadow');
                } else {
                    $footer.removeClass('no-shadow');
                }
            });
        });
    </script>

@endpush
