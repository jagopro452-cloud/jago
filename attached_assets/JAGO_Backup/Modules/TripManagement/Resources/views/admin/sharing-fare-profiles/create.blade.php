@extends('adminmodule::layouts.master')

@section('title', translate('Add Sharing Fare Profile'))

@section('content')
    <div class="main-content">
        <div class="container-fluid">
            <div class="d-flex flex-wrap justify-content-between align-items-center mb-4">
                <h4 class="text-capitalize">{{ translate('add_sharing_fare_profile') }}</h4>
                <a href="{{ route('admin.trip.sharing-fare-profiles.index') }}" class="btn btn-secondary">
                    <i class="bi bi-arrow-left"></i> {{ translate('back') }}
                </a>
            </div>

            <div class="card">
                <div class="card-body">
                    @if($errors->any())
                        <div class="alert alert-danger">
                            <ul class="mb-0">
                                @foreach($errors->all() as $error)
                                    <li>{{ $error }}</li>
                                @endforeach
                            </ul>
                        </div>
                    @endif

                    <form action="{{ route('admin.trip.sharing-fare-profiles.store') }}" method="POST">
                        @csrf
                        <div class="row">
                            <div class="col-md-4 mb-3">
                                <label class="form-label">{{ translate('zone') }} <span class="text-danger">*</span></label>
                                <select name="zone_id" class="form-select" required>
                                    <option value="">{{ translate('select_zone') }}</option>
                                    @foreach($zones as $zone)
                                        <option value="{{ $zone->id }}" {{ old('zone_id') == $zone->id ? 'selected' : '' }}>{{ $zone->name }}</option>
                                    @endforeach
                                </select>
                            </div>
                            <div class="col-md-4 mb-3">
                                <label class="form-label">{{ translate('vehicle_category') }} <span class="text-danger">*</span></label>
                                <select name="vehicle_category_id" class="form-select" required>
                                    <option value="">{{ translate('select_vehicle_category') }}</option>
                                    @foreach($vehicleCategories as $category)
                                        <option value="{{ $category->id }}" {{ old('vehicle_category_id') == $category->id ? 'selected' : '' }}>{{ $category->name }}</option>
                                    @endforeach
                                </select>
                            </div>
                            <div class="col-md-4 mb-3">
                                <label class="form-label">{{ translate('sharing_type') }} <span class="text-danger">*</span></label>
                                <select name="sharing_type" class="form-select" required>
                                    <option value="">{{ translate('select_type') }}</option>
                                    <option value="city" {{ old('sharing_type') == 'city' ? 'selected' : '' }}>{{ translate('city') }}</option>
                                    <option value="outstation" {{ old('sharing_type') == 'outstation' ? 'selected' : '' }}>{{ translate('outstation') }}</option>
                                </select>
                            </div>
                            <div class="col-md-4 mb-3">
                                <label class="form-label">{{ translate('base_fare_per_seat') }} <span class="text-danger">*</span></label>
                                <input type="number" name="base_fare_per_seat" class="form-control" step="0.01" min="0" value="{{ old('base_fare_per_seat') }}" required>
                            </div>
                            <div class="col-md-4 mb-3">
                                <label class="form-label">{{ translate('per_km_fare_per_seat') }} <span class="text-danger">*</span></label>
                                <input type="number" name="per_km_fare_per_seat" class="form-control" step="0.01" min="0" value="{{ old('per_km_fare_per_seat') }}" required>
                            </div>
                            <div class="col-md-4 mb-3">
                                <label class="form-label">{{ translate('min_fare_per_seat') }}</label>
                                <input type="number" name="min_fare_per_seat" class="form-control" step="0.01" min="0" value="{{ old('min_fare_per_seat', 0) }}">
                            </div>
                            <div class="col-md-4 mb-3">
                                <label class="form-label">{{ translate('discount_percent') }}</label>
                                <input type="number" name="discount_percent" class="form-control" step="0.01" min="0" max="100" value="{{ old('discount_percent', 0) }}">
                            </div>
                            <div class="col-md-4 mb-3">
                                <label class="form-label">{{ translate('commission_percent') }}</label>
                                <input type="number" name="commission_percent" class="form-control" step="0.01" min="0" max="100" value="{{ old('commission_percent', 0) }}">
                            </div>
                            <div class="col-md-4 mb-3">
                                <label class="form-label">{{ translate('gst_percent') }}</label>
                                <input type="number" name="gst_percent" class="form-control" step="0.01" min="0" max="100" value="{{ old('gst_percent', 0) }}">
                            </div>
                            <div class="col-md-4 mb-3">
                                <label class="form-label">{{ translate('max_detour_km') }}</label>
                                <input type="number" name="max_detour_km" class="form-control" step="0.01" min="0" value="{{ old('max_detour_km', 0) }}">
                            </div>
                            <div class="col-md-4 mb-3">
                                <label class="form-label">{{ translate('min_distance_km') }}</label>
                                <input type="number" name="min_distance_km" class="form-control" step="0.01" min="0" value="{{ old('min_distance_km', 0) }}">
                            </div>
                            <div class="col-md-4 mb-3">
                                <label class="form-label">{{ translate('max_distance_km') }}</label>
                                <input type="number" name="max_distance_km" class="form-control" step="0.01" min="0" value="{{ old('max_distance_km', 0) }}">
                            </div>
                            <div class="col-md-12 mb-3">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" name="is_active" id="is_active" {{ old('is_active', true) ? 'checked' : '' }}>
                                    <label class="form-check-label" for="is_active">{{ translate('active') }}</label>
                                </div>
                            </div>
                        </div>
                        <div class="d-flex justify-content-end mt-3">
                            <button type="submit" class="btn btn-primary">{{ translate('submit') }}</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
@endsection
