@extends('adminmodule::layouts.master')

@section('title', translate('Parcel_Delivery_Fare_Setup'))

@section('content')
    <!-- Main Content -->
    <div class="main-content">
        <div class="container-fluid">
            <div class="mb-4">
                <h2 class="fs-22 mb-2 text-capitalize">{{ translate('parcel_delivery_fare_setup') }}</h2>
                <div class="fs-16 text-body">
                    {{ translate('Manage your parcel fares zone wise') }}
                </div>
            </div>
            <div class="card">
                <div class="card-body">
                    <div class="d-flex flex-wrap gap-10 justify-content-between align-items-center mb-4">
                        <h5 class="text-primary text-capitalize">
                            {{ translate('operation_zone_wise_parcel_fare_setup') }}
                        </h5>
                        <form action="javascript:;" class="search-form search-form_style-two" method="GET">
                            <div class="input-group search-form__input_group">
                                <span class="search-form__icon">
                                    <i class="bi bi-search"></i>
                                </span>
                                <input type="search" class="theme-input-style search-form__input"
                                       value="{{ request()->get('search') }}" name="search" id="search"
                                       placeholder="{{ translate('search') }}">
                            </div>
                            <button type="submit" class="btn btn-primary search-submit"
                                    data-url="{{ url()->full() }}">{{ translate('search') }}</button>
                        </form>
                    </div>
                    @forelse($zones as $zone)
                        <div class="card bg-primary-light border-0 mb-3">
                            <div class="card-body">
                                <div class="row gy-4">
                                    <div class="col-lg-4">
                                        <div class="media flex-wrap gap-3">
                                            <span class="fw-medium bg-primary text-white circle-24">{{ $loop->iteration }}</span>
                                            <div class="media-body">
                                                <h6 class="mb-3">{{ $zone->name }}</h6>
                                                <h6 class="text-muted">
                                                    {{ translate('total_driver') }}:
                                                    <span class="text-primary">{{ $zone->drivers_count }}</span>
                                                </h6>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-lg-4">
                                        <div class="">
                                            <h6 class="mb-3 text-capitalize">{{ translate('vehicle_types_configured') }}</h6>
                                            <div class="d-flex flex-wrap align-items-center gap-2">
                                                @php
                                                    $zoneFares = $fares->where('zone_id', $zone->id);
                                                    $configuredCount = $zoneFares->whereNotNull('vehicle_category_id')->count();
                                                @endphp
                                                @if($configuredCount > 0)
                                                    @foreach($zoneFares->whereNotNull('vehicle_category_id') as $zf)
                                                        <span class="badge bg-success">{{ $zf->vehicle_category_name ?? $zf->vehicleCategory?->name ?? 'Unknown' }}</span>
                                                    @endforeach
                                                @else
                                                    @if($zoneFares->count() > 0)
                                                        <span class="badge bg-warning text-dark">{{ translate('legacy_fare_only') }}</span>
                                                    @else
                                                        <span class="badge bg-secondary">{{ translate('no_fares_set') }}</span>
                                                    @endif
                                                @endif
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-lg-4">
                                        <div class="d-flex justify-content-lg-end">
                                            <a href="{{ route('admin.fare.parcel.create', [$zone->id]) }}"
                                               class="btn btn-primary text-capitalize cmn_focus"><i class="bi bi-gear-fill"></i>
                                                {{ translate('view_fare_setup') }}
                                            </a>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    @empty
                        <div class="card bg-primary-light border-0 mb-3">
                            <div class="card-body">
                                <div class="row gy-4">
                                    <div class="col-lg-12">
                                        <div class="text-capitalize d-flex justify-content-center gap-3">
                                            <div>
                                                <h6 class="mb-4 text-capitalize">
                                                    {{ translate('please_add_or_activate_a_zone') }}</h6>
                                                <a href="{{ route('admin.zone.index') }}"
                                                   class="btn btn-primary text-capitalize justify-content-center">
                                                    <i class="bi bi-arrow-left"></i> {{ translate('go_to_zone_setup') }}
                                                </a>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                    @endforelse
                </div>
            </div>
        </div>
    </div>
    <!-- End Main Content -->

@endsection
