@extends('adminmodule::layouts.master')

@section('title', translate('Add Festival Offer'))

@section('content')
    <div class="main-content">
        <div class="container-fluid">
            <div class="d-flex flex-wrap justify-content-between align-items-center mb-4">
                <h4 class="text-capitalize">{{ translate('add_festival_offer') }}</h4>
                <a href="{{ route('admin.trip.festival-offers.index') }}" class="btn btn-secondary">
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

                    <form action="{{ route('admin.trip.festival-offers.store') }}" method="POST">
                        @csrf
                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label class="form-label">{{ translate('name') }} <span class="text-danger">*</span></label>
                                <input type="text" name="name" class="form-control" value="{{ old('name') }}" required>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">{{ translate('sharing_type') }}</label>
                                <select name="sharing_type" class="form-select">
                                    <option value="">{{ translate('all_both') }}</option>
                                    <option value="city" {{ old('sharing_type') == 'city' ? 'selected' : '' }}>{{ translate('city_only') }}</option>
                                    <option value="outstation" {{ old('sharing_type') == 'outstation' ? 'selected' : '' }}>{{ translate('outstation_only') }}</option>
                                </select>
                            </div>
                            <div class="col-md-12 mb-3">
                                <label class="form-label">{{ translate('description') }}</label>
                                <textarea name="description" class="form-control" rows="3">{{ old('description') }}</textarea>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">{{ translate('zone') }}</label>
                                <select name="zone_id" class="form-select">
                                    <option value="">{{ translate('all_zones') }}</option>
                                    @foreach($zones as $zone)
                                        <option value="{{ $zone->id }}" {{ old('zone_id') == $zone->id ? 'selected' : '' }}>{{ $zone->name }}</option>
                                    @endforeach
                                </select>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">{{ translate('vehicle_category') }}</label>
                                <select name="vehicle_category_id" class="form-select">
                                    <option value="">{{ translate('all_categories') }}</option>
                                    @foreach($vehicleCategories as $category)
                                        <option value="{{ $category->id }}" {{ old('vehicle_category_id') == $category->id ? 'selected' : '' }}>{{ $category->name }}</option>
                                    @endforeach
                                </select>
                            </div>
                            <div class="col-md-4 mb-3">
                                <label class="form-label">{{ translate('offer_type') }} <span class="text-danger">*</span></label>
                                <select name="offer_type" class="form-select" required>
                                    <option value="discount_percent" {{ old('offer_type') == 'discount_percent' ? 'selected' : '' }}>{{ translate('percentage_discount') }}</option>
                                    <option value="flat_discount" {{ old('offer_type') == 'flat_discount' ? 'selected' : '' }}>{{ translate('flat_discount') }}</option>
                                    <option value="per_seat_discount" {{ old('offer_type') == 'per_seat_discount' ? 'selected' : '' }}>{{ translate('per_seat_discount') }}</option>
                                </select>
                            </div>
                            <div class="col-md-4 mb-3">
                                <label class="form-label">{{ translate('offer_value') }} <span class="text-danger">*</span></label>
                                <input type="number" name="offer_value" class="form-control" step="0.01" min="0" value="{{ old('offer_value') }}" required>
                            </div>
                            <div class="col-md-4 mb-3">
                                <label class="form-label">{{ translate('max_discount_amount') }}</label>
                                <input type="number" name="max_discount_amount" class="form-control" step="0.01" min="0" value="{{ old('max_discount_amount') }}">
                            </div>
                            <div class="col-md-4 mb-3">
                                <label class="form-label">{{ translate('min_fare_amount') }}</label>
                                <input type="number" name="min_fare_amount" class="form-control" step="0.01" min="0" value="{{ old('min_fare_amount') }}">
                            </div>
                            <div class="col-md-4 mb-3">
                                <label class="form-label">{{ translate('max_uses_total') }}</label>
                                <input type="number" name="max_uses_total" class="form-control" min="0" value="{{ old('max_uses_total', 0) }}">
                                <small class="text-muted">{{ translate('0_means_unlimited') }}</small>
                            </div>
                            <div class="col-md-4 mb-3">
                                <label class="form-label">{{ translate('max_uses_per_user') }}</label>
                                <input type="number" name="max_uses_per_user" class="form-control" min="0" value="{{ old('max_uses_per_user', 0) }}">
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">{{ translate('start_date') }} <span class="text-danger">*</span></label>
                                <input type="datetime-local" name="starts_at" class="form-control" value="{{ old('starts_at') }}" required>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">{{ translate('end_date') }} <span class="text-danger">*</span></label>
                                <input type="datetime-local" name="ends_at" class="form-control" value="{{ old('ends_at') }}" required>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">{{ translate('banner_image') }}</label>
                                <input type="text" name="banner_image" class="form-control" value="{{ old('banner_image') }}" placeholder="{{ translate('image_url_optional') }}">
                            </div>
                            <div class="col-md-6 mb-3 d-flex align-items-end">
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
