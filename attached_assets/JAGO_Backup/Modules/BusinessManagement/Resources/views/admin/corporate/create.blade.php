@extends('adminmodule::layouts.master')

@section('title', translate('Add Corporate Account'))

@section('content')
<div class="main-content">
    <div class="container-fluid">
        <div class="d-flex align-items-center justify-content-between gap-3 mb-3">
            <h2 class="fs-22 text-capitalize">{{ translate('Add Corporate Account') }}</h2>
            <a href="{{ route('admin.business.setup.corporate.index') }}" class="btn btn-outline-primary">
                <i class="bi bi-arrow-left"></i> {{ translate('Back') }}
            </a>
        </div>

        <form action="{{ route('admin.business.setup.corporate.store') }}" method="POST">
            @csrf
            <div class="card mb-3">
                <div class="card-header">
                    <h5>{{ translate('Company Information') }}</h5>
                </div>
                <div class="card-body">
                    <div class="row g-3">
                        <div class="col-md-6">
                            <label class="form-label">{{ translate('Company Name') }} <span class="text-danger">*</span></label>
                            <input type="text" name="company_name" class="form-control" required value="{{ old('company_name') }}">
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">{{ translate('Company Code') }} <span class="text-danger">*</span></label>
                            <input type="text" name="company_code" class="form-control text-uppercase" required value="{{ old('company_code') }}" placeholder="e.g. TATA001">
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">{{ translate('GST Number') }}</label>
                            <input type="text" name="gst_number" class="form-control" value="{{ old('gst_number') }}">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">{{ translate('Contact Person') }} <span class="text-danger">*</span></label>
                            <input type="text" name="contact_person" class="form-control" required value="{{ old('contact_person') }}">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">{{ translate('Contact Email') }} <span class="text-danger">*</span></label>
                            <input type="email" name="contact_email" class="form-control" required value="{{ old('contact_email') }}">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">{{ translate('Contact Phone') }} <span class="text-danger">*</span></label>
                            <input type="text" name="contact_phone" class="form-control" required value="{{ old('contact_phone') }}">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">{{ translate('Address') }}</label>
                            <input type="text" name="address" class="form-control" value="{{ old('address') }}">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">{{ translate('City') }}</label>
                            <input type="text" name="city" class="form-control" value="{{ old('city') }}">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">{{ translate('State') }}</label>
                            <input type="text" name="state" class="form-control" value="{{ old('state') }}">
                        </div>
                    </div>
                </div>
            </div>

            <div class="card mb-3">
                <div class="card-header">
                    <h5>{{ translate('Plan & Billing') }}</h5>
                </div>
                <div class="card-body">
                    <div class="row g-3">
                        <div class="col-md-3">
                            <label class="form-label">{{ translate('Plan Type') }} <span class="text-danger">*</span></label>
                            <select name="plan_type" class="form-select" required>
                                <option value="basic">{{ translate('Basic') }}</option>
                                <option value="standard">{{ translate('Standard') }}</option>
                                <option value="premium">{{ translate('Premium') }}</option>
                                <option value="enterprise">{{ translate('Enterprise') }}</option>
                            </select>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">{{ translate('Billing Cycle') }} <span class="text-danger">*</span></label>
                            <select name="billing_cycle" class="form-select" required>
                                <option value="monthly">{{ translate('Monthly') }}</option>
                                <option value="quarterly">{{ translate('Quarterly') }}</option>
                                <option value="annual">{{ translate('Annual') }}</option>
                            </select>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">{{ translate('Discount (%)') }}</label>
                            <input type="number" name="discount_percent" class="form-control" step="0.01" min="0" max="50" value="{{ old('discount_percent', 0) }}">
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">{{ translate('Credit Limit') }}</label>
                            <input type="number" name="credit_limit" class="form-control" step="0.01" min="0" value="{{ old('credit_limit', 0) }}">
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">{{ translate('Max Employees') }} <span class="text-danger">*</span></label>
                            <input type="number" name="max_employees" class="form-control" min="1" required value="{{ old('max_employees', 50) }}">
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">{{ translate('Contract Start') }}</label>
                            <input type="date" name="contract_start" class="form-control" value="{{ old('contract_start') }}">
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">{{ translate('Contract End') }}</label>
                            <input type="date" name="contract_end" class="form-control" value="{{ old('contract_end') }}">
                        </div>
                        <div class="col-md-3 d-flex align-items-end gap-4">
                            <div class="form-check">
                                <input type="checkbox" name="ride_allowed" class="form-check-input" checked id="rideAllowed">
                                <label class="form-check-label" for="rideAllowed">{{ translate('Rides') }}</label>
                            </div>
                            <div class="form-check">
                                <input type="checkbox" name="parcel_allowed" class="form-check-input" id="parcelAllowed">
                                <label class="form-check-label" for="parcelAllowed">{{ translate('Parcels') }}</label>
                            </div>
                        </div>
                        <div class="col-12">
                            <label class="form-label">{{ translate('Notes') }}</label>
                            <textarea name="notes" class="form-control" rows="3">{{ old('notes') }}</textarea>
                        </div>
                    </div>
                </div>
            </div>

            <div class="text-end">
                <button type="submit" class="btn btn-primary btn-lg px-5">{{ translate('Create Account') }}</button>
            </div>
        </form>
    </div>
</div>
@endsection
