@extends('adminmodule::layouts.master')

@section('title', translate('subscription_plans'))

@section('content')
    <div class="main-content">
        <div class="container-fluid">
            <h2 class="fs-22 mb-4 text-capitalize">{{ translate('subscription_plans') }}</h2>

            @php
                $currentEarningModel = get_cache('earning_model') ?? 'commission';
                $platformFee = (double)(get_cache('platform_fee_amount') ?? 0);
                $gstPercent = (double)(get_cache('vat_percent') ?? 18);
            @endphp
            <div class="alert {{ $currentEarningModel === 'subscription' ? 'alert-success' : 'alert-warning' }} mb-3">
                <div class="d-flex align-items-center justify-content-between">
                    <div>
                        <strong>{{ translate('Current Earning Model') }}:</strong>
                        <span class="badge {{ $currentEarningModel === 'subscription' ? 'bg-success' : 'bg-primary' }} ms-2">
                            {{ $currentEarningModel === 'subscription' ? translate('Subscription Model') : translate('Commission Model') }}
                        </span>
                        @if($currentEarningModel === 'subscription')
                            <span class="ms-3">{{ translate('Per-ride Platform Fee') }}: <strong>{{ set_currency_symbol($platformFee) }} + GST {{ $gstPercent }}% = {{ set_currency_symbol(round($platformFee + ($platformFee * $gstPercent / 100), 2)) }}</strong></span>
                        @endif
                    </div>
                    <a href="{{ route('admin.business.setup.settings') }}" class="btn btn-sm btn-outline-dark">
                        <i class="bi bi-gear-fill"></i> {{ translate('Change in Settings') }}
                    </a>
                </div>
            </div>

            <div class="row g-4 mb-4">
                <div class="col-lg-4 col-sm-6">
                    <div class="card">
                        <div class="card-body">
                            <div class="d-flex align-items-center gap-3">
                                <div class="avatar avatar-lg bg-primary bg-opacity-10 rounded-circle d-flex align-items-center justify-content-center">
                                    <i class="bi bi-people-fill text-primary fs-4"></i>
                                </div>
                                <div>
                                    <h3 class="fs-24 fw-bold mb-0">{{ $totalActiveDrivers }}</h3>
                                    <p class="fs-14 text-muted mb-0">{{ translate('active_subscribed_drivers') }}</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-lg-4 col-sm-6">
                    <div class="card">
                        <div class="card-body">
                            <div class="d-flex align-items-center gap-3">
                                <div class="avatar avatar-lg bg-info bg-opacity-10 rounded-circle d-flex align-items-center justify-content-center">
                                    <i class="bi bi-card-checklist text-info fs-4"></i>
                                </div>
                                <div>
                                    <h3 class="fs-24 fw-bold mb-0">{{ $totalSubscriptions }}</h3>
                                    <p class="fs-14 text-muted mb-0">{{ translate('total_subscriptions') }}</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-lg-4 col-sm-6">
                    <div class="card">
                        <div class="card-body">
                            <div class="d-flex align-items-center gap-3">
                                <div class="avatar avatar-lg bg-success bg-opacity-10 rounded-circle d-flex align-items-center justify-content-center">
                                    <i class="bi bi-collection text-success fs-4"></i>
                                </div>
                                <div>
                                    <h3 class="fs-24 fw-bold mb-0">{{ $plans->total() }}</h3>
                                    <p class="fs-14 text-muted mb-0">{{ translate('total_plans') }}</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="card mb-3">
                <form action="{{ route('admin.subscription.store') }}" method="post">
                    @csrf
                    <div class="card-body">
                        <h3 class="mb-20 text-dark">{{ translate('add_subscription_plan') }}</h3>
                        <div class="row g-lg-4 g-3">
                            <div class="col-md-4">
                                <label for="name" class="mb-2 text-capitalize">{{ translate('plan_name') }} <span class="text-danger">*</span></label>
                                <input type="text" class="form-control" id="name" name="name" placeholder="{{ translate('enter_plan_name') }}" required>
                            </div>
                            <div class="col-md-4">
                                <label for="duration_type" class="mb-2 text-capitalize">{{ translate('duration_type') }} <span class="text-danger">*</span></label>
                                <select class="form-control js-select" id="duration_type" name="duration_type" required>
                                    <option value="daily">{{ translate('daily') }}</option>
                                    <option value="weekly">{{ translate('weekly') }}</option>
                                    <option value="monthly" selected>{{ translate('monthly') }}</option>
                                </select>
                            </div>
                            <div class="col-md-4">
                                <label for="duration_days" class="mb-2 text-capitalize">{{ translate('duration_days') }} <span class="text-danger">*</span></label>
                                <input type="number" class="form-control" id="duration_days" name="duration_days" placeholder="{{ translate('enter_duration_in_days') }}" min="1" required>
                            </div>
                            <div class="col-md-4">
                                <label for="price" class="mb-2 text-capitalize">{{ translate('price') }} <span class="text-danger">*</span></label>
                                <input type="number" step="0.01" class="form-control" id="price" name="price" placeholder="{{ translate('enter_price') }}" min="0" required>
                            </div>
                            <div class="col-md-4">
                                <label for="max_rides" class="mb-2 text-capitalize">{{ translate('max_rides') }} <span class="text-danger">*</span></label>
                                <input type="number" class="form-control" id="max_rides" name="max_rides" placeholder="{{ translate('enter_max_rides') }}" min="1" required>
                            </div>
                            <div class="col-md-4">
                                <label for="description" class="mb-2 text-capitalize">{{ translate('description') }}</label>
                                <input type="text" class="form-control" id="description" name="description" placeholder="{{ translate('enter_description') }}">
                            </div>
                            <div class="col-12 d-flex justify-content-end align-items-end mt-3 gap-2">
                                <button type="reset" class="btn btn-secondary">{{ translate('reset') }}</button>
                                <button type="submit" class="btn btn-primary">{{ translate('submit') }}</button>
                            </div>
                        </div>
                    </div>
                </form>
            </div>

            <h2 class="fs-22 mb-3 text-capitalize">{{ translate('plan_list') }}</h2>
            <div class="card">
                <div class="card-body">
                    <div class="table-responsive mt-3">
                        <table class="table table-borderless mb-0 align-middle table-hover text-nowrap">
                            <thead class="table-light align-middle text-capitalize">
                            <tr>
                                <th class="fw-semibold fs-14">{{ translate('SL') }}</th>
                                <th class="fw-semibold fs-14">{{ translate('plan_name') }}</th>
                                <th class="fw-semibold fs-14">{{ translate('duration') }}</th>
                                <th class="fw-semibold fs-14">{{ translate('price') }}</th>
                                <th class="fw-semibold fs-14">{{ translate('max_rides') }}</th>
                                <th class="fw-semibold fs-14">{{ translate('status') }}</th>
                                <th class="fw-semibold text-center fs-14">{{ translate('action') }}</th>
                            </tr>
                            </thead>
                            <tbody>
                            @forelse($plans as $key => $plan)
                                <tr>
                                    <td class="fs-14 fw-semibold text-dark">{{ $plans->firstItem() + $key }}</td>
                                    <td>
                                        <div class="max-w-240 min-w-170 fs-14 text-wrap">{{ $plan->name }}</div>
                                        @if($plan->description)
                                            <small class="text-muted">{{ Str::limit($plan->description, 50) }}</small>
                                        @endif
                                    </td>
                                    <td class="fs-14">{{ $plan->duration_days }} {{ translate('days') }} ({{ translate($plan->duration_type) }})</td>
                                    <td class="fs-14">
                                        {{ set_currency_symbol($plan->price) }}
                                        @php $gstPct = (double)(get_cache('vat_percent') ?? 18); @endphp
                                        <br><small class="text-muted">+ GST {{ $gstPct }}%: {{ set_currency_symbol(round($plan->price * $gstPct / 100, 2)) }}</small>
                                        <br><small class="fw-bold text-success">{{ translate('Total') }}: {{ set_currency_symbol(round($plan->price + ($plan->price * $gstPct / 100), 2)) }}</small>
                                    </td>
                                    <td class="fs-14">{{ $plan->max_rides }}</td>
                                    <td>
                                        <span class="badge {{ $plan->is_active ? 'bg-success' : 'bg-danger' }}">
                                            {{ $plan->is_active ? translate('active') : translate('inactive') }}
                                        </span>
                                    </td>
                                    <td class="action text-center">
                                        <div class="d-flex justify-content-center gap-2 align-items-center">
                                            <button type="button" class="btn btn-outline-primary btn-action edit-plan"
                                                    data-id="{{ $plan->id }}"
                                                    data-name="{{ $plan->name }}"
                                                    data-description="{{ $plan->description }}"
                                                    data-duration-type="{{ $plan->duration_type }}"
                                                    data-duration-days="{{ $plan->duration_days }}"
                                                    data-price="{{ $plan->price }}"
                                                    data-max-rides="{{ $plan->max_rides }}"
                                                    data-bs-toggle="modal" data-bs-target="#editPlanModal">
                                                <i class="bi bi-pencil-fill"></i>
                                            </button>
                                            <form action="{{ route('admin.subscription.toggle-status', $plan->id) }}" method="POST" class="d-inline">
                                                @csrf
                                                <button type="submit" class="btn {{ $plan->is_active ? 'btn-outline-danger' : 'btn-outline-success' }} btn-action"
                                                        data-bs-toggle="tooltip" title="{{ $plan->is_active ? translate('deactivate') : translate('activate') }}">
                                                    <i class="bi {{ $plan->is_active ? 'bi-toggle-on' : 'bi-toggle-off' }}"></i>
                                                </button>
                                            </form>
                                        </div>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="7">
                                        <div class="d-flex flex-column justify-content-center align-items-center gap-2 py-3">
                                            <img src="{{ dynamicAsset('public/assets/admin-module/img/empty-icons/no-data-found.svg') }}" alt="" width="100">
                                            <p class="text-center">{{ translate('no_data_available') }}</p>
                                        </div>
                                    </td>
                                </tr>
                            @endforelse
                            </tbody>
                        </table>
                    </div>
                    <div class="d-flex justify-content-end">
                        {!! $plans->withQueryString()->links() !!}
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="modal fade" id="editPlanModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">{{ translate('edit_subscription_plan') }}</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <form id="editPlanForm" method="POST">
                    @csrf
                    @method('PUT')
                    <div class="modal-body">
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="mb-2 text-capitalize">{{ translate('plan_name') }} <span class="text-danger">*</span></label>
                                <input type="text" class="form-control" name="name" id="edit_name" required>
                            </div>
                            <div class="col-md-6">
                                <label class="mb-2 text-capitalize">{{ translate('duration_type') }} <span class="text-danger">*</span></label>
                                <select class="form-control" name="duration_type" id="edit_duration_type" required>
                                    <option value="daily">{{ translate('daily') }}</option>
                                    <option value="weekly">{{ translate('weekly') }}</option>
                                    <option value="monthly">{{ translate('monthly') }}</option>
                                </select>
                            </div>
                            <div class="col-md-6">
                                <label class="mb-2 text-capitalize">{{ translate('duration_days') }} <span class="text-danger">*</span></label>
                                <input type="number" class="form-control" name="duration_days" id="edit_duration_days" min="1" required>
                            </div>
                            <div class="col-md-6">
                                <label class="mb-2 text-capitalize">{{ translate('price') }} <span class="text-danger">*</span></label>
                                <input type="number" step="0.01" class="form-control" name="price" id="edit_price" min="0" required>
                            </div>
                            <div class="col-md-6">
                                <label class="mb-2 text-capitalize">{{ translate('max_rides') }} <span class="text-danger">*</span></label>
                                <input type="number" class="form-control" name="max_rides" id="edit_max_rides" min="1" required>
                            </div>
                            <div class="col-md-6">
                                <label class="mb-2 text-capitalize">{{ translate('description') }}</label>
                                <input type="text" class="form-control" name="description" id="edit_description">
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">{{ translate('close') }}</button>
                        <button type="submit" class="btn btn-primary">{{ translate('update') }}</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
@endsection

@push('script')
    <script>
        $(document).on('click', '.edit-plan', function () {
            let id = $(this).data('id');
            let baseUrl = "{{ url('admin/subscription') }}/" + id;
            $('#editPlanForm').attr('action', baseUrl);
            $('#edit_name').val($(this).data('name'));
            $('#edit_description').val($(this).data('description'));
            $('#edit_duration_type').val($(this).data('duration-type'));
            $('#edit_duration_days').val($(this).data('duration-days'));
            $('#edit_price').val($(this).data('price'));
            $('#edit_max_rides').val($(this).data('max-rides'));
        });
    </script>
@endpush
