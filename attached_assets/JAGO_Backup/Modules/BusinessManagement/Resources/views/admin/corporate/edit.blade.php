@extends('adminmodule::layouts.master')

@section('title', translate('Edit Corporate Account'))

@section('content')
<div class="main-content">
    <div class="container-fluid">
        <div class="d-flex align-items-center justify-content-between gap-3 mb-3">
            <h2 class="fs-22 text-capitalize">{{ translate('Edit') }}: {{ $corporate->company_name }}</h2>
            <a href="{{ route('admin.business.setup.corporate.index') }}" class="btn btn-outline-primary">
                <i class="bi bi-arrow-left"></i> {{ translate('Back') }}
            </a>
        </div>

        <form action="{{ route('admin.business.setup.corporate.update', $corporate->id) }}" method="POST">
            @csrf
            @method('PUT')
            <div class="card mb-3">
                <div class="card-header">
                    <h5>{{ translate('Company Information') }}</h5>
                </div>
                <div class="card-body">
                    <div class="row g-3">
                        <div class="col-md-6">
                            <label class="form-label">{{ translate('Company Name') }} <span class="text-danger">*</span></label>
                            <input type="text" name="company_name" class="form-control" required value="{{ $corporate->company_name }}">
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">{{ translate('Company Code') }} <span class="text-danger">*</span></label>
                            <input type="text" name="company_code" class="form-control text-uppercase" required value="{{ $corporate->company_code }}">
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">{{ translate('GST Number') }}</label>
                            <input type="text" name="gst_number" class="form-control" value="{{ $corporate->gst_number }}">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">{{ translate('Contact Person') }} <span class="text-danger">*</span></label>
                            <input type="text" name="contact_person" class="form-control" required value="{{ $corporate->contact_person }}">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">{{ translate('Contact Email') }} <span class="text-danger">*</span></label>
                            <input type="email" name="contact_email" class="form-control" required value="{{ $corporate->contact_email }}">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">{{ translate('Contact Phone') }} <span class="text-danger">*</span></label>
                            <input type="text" name="contact_phone" class="form-control" required value="{{ $corporate->contact_phone }}">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">{{ translate('Address') }}</label>
                            <input type="text" name="address" class="form-control" value="{{ $corporate->address }}">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">{{ translate('City') }}</label>
                            <input type="text" name="city" class="form-control" value="{{ $corporate->city }}">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">{{ translate('State') }}</label>
                            <input type="text" name="state" class="form-control" value="{{ $corporate->state }}">
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
                                @foreach(['basic', 'standard', 'premium', 'enterprise'] as $plan)
                                <option value="{{ $plan }}" {{ $corporate->plan_type == $plan ? 'selected' : '' }}>{{ ucfirst($plan) }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">{{ translate('Billing Cycle') }} <span class="text-danger">*</span></label>
                            <select name="billing_cycle" class="form-select" required>
                                @foreach(['monthly', 'quarterly', 'annual'] as $cycle)
                                <option value="{{ $cycle }}" {{ $corporate->billing_cycle == $cycle ? 'selected' : '' }}>{{ ucfirst($cycle) }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">{{ translate('Discount (%)') }}</label>
                            <input type="number" name="discount_percent" class="form-control" step="0.01" min="0" max="50" value="{{ $corporate->discount_percent }}">
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">{{ translate('Credit Limit') }}</label>
                            <input type="number" name="credit_limit" class="form-control" step="0.01" min="0" value="{{ $corporate->credit_limit }}">
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">{{ translate('Max Employees') }} <span class="text-danger">*</span></label>
                            <input type="number" name="max_employees" class="form-control" min="1" required value="{{ $corporate->max_employees }}">
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">{{ translate('Contract Start') }}</label>
                            <input type="date" name="contract_start" class="form-control" value="{{ $corporate->contract_start?->format('Y-m-d') }}">
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">{{ translate('Contract End') }}</label>
                            <input type="date" name="contract_end" class="form-control" value="{{ $corporate->contract_end?->format('Y-m-d') }}">
                        </div>
                        <div class="col-md-3 d-flex align-items-end gap-4">
                            <div class="form-check">
                                <input type="checkbox" name="ride_allowed" class="form-check-input" {{ $corporate->ride_allowed ? 'checked' : '' }} id="rideAllowed">
                                <label class="form-check-label" for="rideAllowed">{{ translate('Rides') }}</label>
                            </div>
                            <div class="form-check">
                                <input type="checkbox" name="parcel_allowed" class="form-check-input" {{ $corporate->parcel_allowed ? 'checked' : '' }} id="parcelAllowed">
                                <label class="form-check-label" for="parcelAllowed">{{ translate('Parcels') }}</label>
                            </div>
                        </div>
                        <div class="col-12">
                            <label class="form-label">{{ translate('Notes') }}</label>
                            <textarea name="notes" class="form-control" rows="3">{{ $corporate->notes }}</textarea>
                        </div>
                    </div>
                </div>
            </div>

            <div class="text-end mb-4">
                <button type="submit" class="btn btn-primary btn-lg px-5">{{ translate('Update Account') }}</button>
            </div>
        </form>

        <div class="card">
            <div class="card-header d-flex align-items-center justify-content-between">
                <h5>{{ translate('Employees') }} <span class="badge bg-primary">{{ $corporate->active_employees }}</span></h5>
                <button type="button" class="btn btn-sm btn-primary" data-bs-toggle="modal" data-bs-target="#addEmployeeModal">
                    <i class="bi bi-plus-lg"></i> {{ translate('Add Employee') }}
                </button>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-borderless align-middle">
                        <thead class="table-light">
                            <tr>
                                <th>{{ translate('SL') }}</th>
                                <th>{{ translate('Name') }}</th>
                                <th>{{ translate('Phone') }}</th>
                                <th>{{ translate('Employee ID') }}</th>
                                <th class="text-center">{{ translate('Action') }}</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($employees as $key => $emp)
                            <tr>
                                <td>{{ $employees->firstItem() + $key }}</td>
                                <td>{{ $emp->first_name }} {{ $emp->last_name }}</td>
                                <td>{{ $emp->phone }}</td>
                                <td><code>{{ $emp->employee_id }}</code></td>
                                <td class="text-center">
                                    <form action="{{ route('admin.business.setup.corporate.remove-employee', [$corporate->id, $emp->id]) }}" method="POST" onsubmit="return confirm('{{ translate('Remove this employee?') }}')">
                                        @csrf
                                        @method('DELETE')
                                        <button type="submit" class="btn btn-sm btn-outline-danger"><i class="bi bi-x-lg"></i></button>
                                    </form>
                                </td>
                            </tr>
                            @empty
                            <tr>
                                <td colspan="5" class="text-center py-4 text-muted">{{ translate('No employees linked yet') }}</td>
                            </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
            @if($employees->hasPages())
            <div class="card-footer border-0">{{ $employees->links() }}</div>
            @endif
        </div>
    </div>
</div>

<div class="modal fade" id="addEmployeeModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form action="{{ route('admin.business.setup.corporate.add-employee', $corporate->id) }}" method="POST">
                @csrf
                <div class="modal-header">
                    <h5 class="modal-title">{{ translate('Add Employee') }}</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label class="form-label">{{ translate('User Phone Number') }} <span class="text-danger">*</span></label>
                        <input type="text" name="phone" class="form-control" required placeholder="{{ translate('Enter registered phone number') }}">
                    </div>
                    <div class="mb-3">
                        <label class="form-label">{{ translate('Employee ID') }} <span class="text-danger">*</span></label>
                        <input type="text" name="employee_id" class="form-control" required placeholder="e.g. EMP001">
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">{{ translate('Cancel') }}</button>
                    <button type="submit" class="btn btn-primary">{{ translate('Add') }}</button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection
