@extends('adminmodule::layouts.master')

@section('title', translate('B2B Parcel Plans'))

@section('content')
<div class="main-content">
    <div class="container-fluid">
        <div class="d-flex align-items-center justify-content-between gap-3 mb-3">
            <h2 class="fs-22 text-capitalize">{{ translate('B2B Parcel Plans') }}</h2>
            <div class="d-flex gap-2">
                <a href="{{ route('admin.business.setup.corporate.index') }}" class="btn btn-outline-primary">
                    <i class="bi bi-arrow-left"></i> {{ translate('Corporate Accounts') }}
                </a>
                <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addPlanModal">
                    <i class="bi bi-plus-lg"></i> {{ translate('Add Plan') }}
                </button>
            </div>
        </div>

        <div class="row g-3">
            @forelse($plans as $plan)
            <div class="col-lg-4">
                <div class="card h-100 {{ !$plan->is_active ? 'opacity-50' : '' }}">
                    <div class="card-header d-flex align-items-center justify-content-between">
                        <div>
                            <h5 class="mb-0">{{ $plan->plan_name }}</h5>
                            <small class="text-muted">{{ $plan->plan_code }}</small>
                        </div>
                        <form action="{{ route('admin.business.setup.corporate.b2b-plans.status', $plan->id) }}" method="POST">
                            @csrf
                            <label class="switcher">
                                <input class="switcher_input" type="checkbox" {{ $plan->is_active ? 'checked' : '' }} onchange="this.closest('form').submit()">
                                <span class="switcher_control"></span>
                            </label>
                        </form>
                    </div>
                    <div class="card-body">
                        <div class="mb-3">
                            <div class="fs-28 fw-bold text-primary">{{ config('currency_symbol', '₹') }}{{ number_format($plan->monthly_fee) }}<small class="fs-14 text-muted fw-normal">/mo</small></div>
                        </div>
                        @if($plan->description)
                        <p class="text-muted small mb-3">{{ $plan->description }}</p>
                        @endif
                        <ul class="list-unstyled mb-0">
                            <li class="mb-2"><i class="bi bi-check-circle text-success"></i> {{ $plan->included_deliveries }} {{ translate('deliveries included') }}</li>
                            <li class="mb-2"><i class="bi bi-tag text-primary"></i> {{ config('currency_symbol', '₹') }}{{ $plan->per_delivery_rate }} {{ translate('per extra delivery') }}</li>
                            @if($plan->discount_percent > 0)
                            <li class="mb-2"><i class="bi bi-percent text-warning"></i> {{ $plan->discount_percent }}% {{ translate('discount') }}</li>
                            @endif
                            <li class="mb-2"><i class="bi bi-box text-info"></i> {{ translate('Max') }} {{ $plan->max_weight_kg }}kg</li>
                            @if($plan->priority_pickup)
                            <li class="mb-2"><i class="bi bi-lightning text-warning"></i> {{ translate('Priority Pickup') }}</li>
                            @endif
                            @if($plan->dedicated_support)
                            <li class="mb-2"><i class="bi bi-headset text-success"></i> {{ translate('Dedicated Support') }}</li>
                            @endif
                            @if($plan->api_access)
                            <li class="mb-2"><i class="bi bi-code-slash text-primary"></i> {{ translate('API Access') }}</li>
                            @endif
                        </ul>
                    </div>
                    <div class="card-footer text-end">
                        <button type="button" class="btn btn-sm btn-outline-primary" data-bs-toggle="modal" data-bs-target="#editPlan{{ $plan->id }}">
                            <i class="bi bi-pencil"></i> {{ translate('Edit') }}
                        </button>
                    </div>
                </div>
            </div>

            <div class="modal fade" id="editPlan{{ $plan->id }}" tabindex="-1">
                <div class="modal-dialog modal-lg">
                    <div class="modal-content">
                        <form action="{{ route('admin.business.setup.corporate.b2b-plans.update', $plan->id) }}" method="POST">
                            @csrf
                            @method('PUT')
                            <div class="modal-header">
                                <h5 class="modal-title">{{ translate('Edit Plan') }}: {{ $plan->plan_name }}</h5>
                                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                            </div>
                            <div class="modal-body">
                                <div class="row g-3">
                                    <div class="col-md-6">
                                        <label class="form-label">{{ translate('Plan Name') }} <span class="text-danger">*</span></label>
                                        <input type="text" name="plan_name" class="form-control" required value="{{ $plan->plan_name }}">
                                    </div>
                                    <div class="col-md-6">
                                        <label class="form-label">{{ translate('Plan Code') }} <span class="text-danger">*</span></label>
                                        <input type="text" name="plan_code" class="form-control" required value="{{ $plan->plan_code }}">
                                    </div>
                                    <div class="col-md-4">
                                        <label class="form-label">{{ translate('Monthly Fee') }} <span class="text-danger">*</span></label>
                                        <input type="number" name="monthly_fee" class="form-control" step="0.01" required value="{{ $plan->monthly_fee }}">
                                    </div>
                                    <div class="col-md-4">
                                        <label class="form-label">{{ translate('Included Deliveries') }} <span class="text-danger">*</span></label>
                                        <input type="number" name="included_deliveries" class="form-control" required value="{{ $plan->included_deliveries }}">
                                    </div>
                                    <div class="col-md-4">
                                        <label class="form-label">{{ translate('Per Delivery Rate') }} <span class="text-danger">*</span></label>
                                        <input type="number" name="per_delivery_rate" class="form-control" step="0.01" required value="{{ $plan->per_delivery_rate }}">
                                    </div>
                                    <div class="col-md-4">
                                        <label class="form-label">{{ translate('Discount (%)') }}</label>
                                        <input type="number" name="discount_percent" class="form-control" step="0.01" min="0" max="50" value="{{ $plan->discount_percent }}">
                                    </div>
                                    <div class="col-md-4">
                                        <label class="form-label">{{ translate('Max Weight (KG)') }} <span class="text-danger">*</span></label>
                                        <input type="number" name="max_weight_kg" class="form-control" required value="{{ $plan->max_weight_kg }}">
                                    </div>
                                    <div class="col-md-4">
                                        <label class="form-label">{{ translate('Sort Order') }}</label>
                                        <input type="number" name="sort_order" class="form-control" value="{{ $plan->sort_order }}">
                                    </div>
                                    <div class="col-12">
                                        <label class="form-label">{{ translate('Description') }}</label>
                                        <textarea name="description" class="form-control" rows="2">{{ $plan->description }}</textarea>
                                    </div>
                                    <div class="col-12 d-flex gap-4">
                                        <div class="form-check">
                                            <input type="checkbox" name="priority_pickup" class="form-check-input" {{ $plan->priority_pickup ? 'checked' : '' }}>
                                            <label class="form-check-label">{{ translate('Priority Pickup') }}</label>
                                        </div>
                                        <div class="form-check">
                                            <input type="checkbox" name="dedicated_support" class="form-check-input" {{ $plan->dedicated_support ? 'checked' : '' }}>
                                            <label class="form-check-label">{{ translate('Dedicated Support') }}</label>
                                        </div>
                                        <div class="form-check">
                                            <input type="checkbox" name="api_access" class="form-check-input" {{ $plan->api_access ? 'checked' : '' }}>
                                            <label class="form-check-label">{{ translate('API Access') }}</label>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="modal-footer">
                                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">{{ translate('Cancel') }}</button>
                                <button type="submit" class="btn btn-primary">{{ translate('Update Plan') }}</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
            @empty
            <div class="col-12">
                <div class="card">
                    <div class="card-body text-center py-5">
                        <p class="text-muted mb-0">{{ translate('No B2B parcel plans configured yet') }}</p>
                    </div>
                </div>
            </div>
            @endforelse
        </div>
        <div class="mt-3">{{ $plans->links() }}</div>
    </div>
</div>

<div class="modal fade" id="addPlanModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <form action="{{ route('admin.business.setup.corporate.b2b-plans.store') }}" method="POST">
                @csrf
                <div class="modal-header">
                    <h5 class="modal-title">{{ translate('Add B2B Parcel Plan') }}</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="row g-3">
                        <div class="col-md-6">
                            <label class="form-label">{{ translate('Plan Name') }} <span class="text-danger">*</span></label>
                            <input type="text" name="plan_name" class="form-control" required placeholder="e.g. Starter">
                        </div>
                        <div class="col-md-6">
                            <label class="form-label">{{ translate('Plan Code') }} <span class="text-danger">*</span></label>
                            <input type="text" name="plan_code" class="form-control text-uppercase" required placeholder="e.g. B2B_STARTER">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">{{ translate('Monthly Fee') }} <span class="text-danger">*</span></label>
                            <input type="number" name="monthly_fee" class="form-control" step="0.01" required placeholder="0.00">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">{{ translate('Included Deliveries') }} <span class="text-danger">*</span></label>
                            <input type="number" name="included_deliveries" class="form-control" required placeholder="100">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">{{ translate('Per Delivery Rate') }} <span class="text-danger">*</span></label>
                            <input type="number" name="per_delivery_rate" class="form-control" step="0.01" required placeholder="15.00">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">{{ translate('Discount (%)') }}</label>
                            <input type="number" name="discount_percent" class="form-control" step="0.01" min="0" max="50" value="0">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">{{ translate('Max Weight (KG)') }} <span class="text-danger">*</span></label>
                            <input type="number" name="max_weight_kg" class="form-control" required value="50">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">{{ translate('Sort Order') }}</label>
                            <input type="number" name="sort_order" class="form-control" value="0">
                        </div>
                        <div class="col-12">
                            <label class="form-label">{{ translate('Description') }}</label>
                            <textarea name="description" class="form-control" rows="2" placeholder="{{ translate('Plan description...') }}"></textarea>
                        </div>
                        <div class="col-12 d-flex gap-4">
                            <div class="form-check">
                                <input type="checkbox" name="priority_pickup" class="form-check-input" id="newPriorityPickup">
                                <label class="form-check-label" for="newPriorityPickup">{{ translate('Priority Pickup') }}</label>
                            </div>
                            <div class="form-check">
                                <input type="checkbox" name="dedicated_support" class="form-check-input" id="newDedicatedSupport">
                                <label class="form-check-label" for="newDedicatedSupport">{{ translate('Dedicated Support') }}</label>
                            </div>
                            <div class="form-check">
                                <input type="checkbox" name="api_access" class="form-check-input" id="newApiAccess">
                                <label class="form-check-label" for="newApiAccess">{{ translate('API Access') }}</label>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">{{ translate('Cancel') }}</button>
                    <button type="submit" class="btn btn-primary">{{ translate('Create Plan') }}</button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection
