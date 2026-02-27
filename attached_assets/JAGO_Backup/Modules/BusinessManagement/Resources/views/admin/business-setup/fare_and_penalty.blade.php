@extends('adminmodule::layouts.master')

@section('title', translate('Business_Info'))

@section('content')
        <!-- Main Content -->
        <div class="main-content">
            <div class="container-fluid">
                <h2 class="fs-20 fw-bold mb-3 text-capitalize">{{translate('business_management')}}</h2>
                <div class="mb-3">
                    <div class="">
                        @include('businessmanagement::admin.business-setup.partials._business-setup-inline')
                    </div>
                </div>
                <div class="card text-capitalize h-100vh-250px">
                    <form action="{{route('admin.business.setup.trip-fare.store')."?type=".TRIP_FARE_SETTINGS}}" id="fare_and_penalty_form" method="POST">
                        @csrf
                        <div class="card-header">
                            <h4 class="d-flex align-items-center gap-2 mb-1">
                                {{ translate('fare_&_penalty_settings') }}
                            </h4>
                            <p class="mb-0">
                                {{ translate('set_trip_fares_and_penalties_for_delays_or_idle_time.') }}
                            </p>
                        </div>
                        <div class="card-body">
                            <div class="row g-4">
                                <div class="col-lg-6">
                                    <div class="mb-3">
                                        <h4 class="d-flex align-items-center gap-2 mb-1">
                                            {{ translate('Idle_fee') }}
                                        </h4>
                                        <p class="mb-0">
                                            {{ translate('The idle fee is applied when the driver pauses an ongoing trip.') }}
                                        </p>
                                    </div>
                                    <div class="p-lg-4 p-3 rounded bg-F6F6F6">
                                        <label for="start_count_idle_fee" class="mb-2">
                                            {{ translate('start_count_idle_fee_after') }} ({{ translate('min') }})
                                            <span class="text-danger">*</span>
                                            <i class="bi bi-info-circle-fill text-primary tooltip-icon" data-bs-toggle="tooltip"
                                               data-bs-title="{{ translate('set_time_(in_minutes)_after_which_the_system_starts_calculating_idle_waiting_charges_during_a_trip.') }}"></i>
                                        </label>
                                        <div class="input-group_tooltip">
                                            <input required type="number" class="form-control" placeholder="Ex: 5" id="start_count_idle_fee" name="idle_fee" value="{{$settings->where('key_name', 'idle_fee')->first()?->value}}" tabindex="1">
                                        </div>
                                    </div>
                                </div>
                                <div class="col-lg-6">
                                    <div class="mb-3">
                                        <h4 class="d-flex align-items-center gap-2 mb-1">
                                            {{ translate('Delay_fee') }}
                                        </h4>
                                        <p class="mb-0">
                                            {{ translate('The fee applied when a trip is delayed beyond the set time.') }}
                                        </p>
                                    </div>
                                    <div class="p-lg-4 p-3 rounded bg-F6F6F6">
                                        <label for="delay_fee" class="mb-2">
                                            {{ translate('start_count_delay_fee_after') }} ({{ translate('min') }})
                                            <span class="text-danger">*</span>
                                            <i class="bi bi-info-circle-fill text-primary tooltip-icon" data-bs-toggle="tooltip"
                                               data-bs-title="{{ translate('set_time_(in_minutes)_after_which_delay_fees_begin_to_apply_if_the_trip_exceeds_the_estimated_duration.') }}"></i>
                                        </label>
                                        <div class="input-group_tooltip">
                                            <input required type="number" class="form-control" placeholder="Ex: 5" id="delay_fee" name="delay_fee" value="{{$settings->firstWhere('key_name', 'delay_fee')?->value}}" tabindex="2">
                                        </div>
                                    </div>
                                </div>
                                <div class="col-lg-6">
                                    <div class="mb-3">
                                        <h4 class="d-flex align-items-center gap-2 mb-1">
                                            {{ translate('Waiting Fee') }}
                                        </h4>
                                        <p class="mb-0">
                                            {{ translate('Free waiting time (in minutes) at pickup before charges apply. After this, per-minute waiting fee from fare setup is charged.') }}
                                        </p>
                                    </div>
                                    <div class="p-lg-4 p-3 rounded bg-F6F6F6">
                                        <label for="waiting_fee_free_minutes" class="mb-2">
                                            {{ translate('Free Waiting Time') }} ({{ translate('min') }})
                                            <span class="text-danger">*</span>
                                            <i class="bi bi-info-circle-fill text-primary tooltip-icon" data-bs-toggle="tooltip"
                                               data-bs-title="{{ translate('Pilot arrives at pickup and waits for customer. Waiting charges start after this free period ends.') }}"></i>
                                        </label>
                                        <div class="input-group_tooltip">
                                            <input required type="number" class="form-control" placeholder="Ex: 3" step="0.5" min="0"
                                                   id="waiting_fee_free_minutes" name="waiting_fee_free_minutes"
                                                   value="{{$settings->firstWhere('key_name', 'waiting_fee_free_minutes')?->value ?? 3}}" tabindex="3">
                                        </div>
                                    </div>
                                </div>
                                <div class="col-lg-6">
                                    <div class="mb-3">
                                        <h4 class="d-flex align-items-center gap-2 mb-1">
                                            {{ translate('Cancellation Free Distance') }}
                                        </h4>
                                        <p class="mb-0">
                                            {{ translate('If the pilot has not yet traveled this distance towards pickup, customer can cancel for free. Beyond this, cancellation fee applies.') }}
                                        </p>
                                    </div>
                                    <div class="p-lg-4 p-3 rounded bg-F6F6F6">
                                        <label for="cancellation_free_distance" class="mb-2">
                                            {{ translate('Free Cancellation Distance') }} ({{ translate('km') }})
                                            <span class="text-danger">*</span>
                                            <i class="bi bi-info-circle-fill text-primary tooltip-icon" data-bs-toggle="tooltip"
                                               data-bs-title="{{ translate('Customer can cancel without charges if pilot has traveled less than this distance. Default: 0.5 km (500 meters).') }}"></i>
                                        </label>
                                        <div class="input-group_tooltip">
                                            <input required type="number" class="form-control" placeholder="Ex: 0.5" step="0.1" min="0"
                                                   id="cancellation_free_distance" name="cancellation_free_distance"
                                                   value="{{$settings->firstWhere('key_name', 'cancellation_free_distance')?->value ?? 0.5}}" tabindex="4">
                                        </div>
                                    </div>
                                </div>
                                <div class="col-12">
                                    <div class="btn--container justify-content-end">
                                        <button type="reset" class="btn btn-secondary min-w-120 cmn_focus" tabindex="5">{{ translate('reset') }}</button>
                                        <button type="submit" class="btn btn-primary min-w-120 cmn_focus" tabindex="6">{{ translate('save') }}</button>
                                    </div>
                                </div>
                            </div>

                        </div>
                    </form>
                </div>
            </div>
        </div>
        <!-- End Main Content -->
@endsection

@push('script')

    <script>
        "use strict";
        let permission = false;
        @can('business_edit')
            permission = true;
        @endcan
        $('#fare_and_penalty_form').on('submit', function (e) {
            if (!permission) {
                toastr.error('{{ translate('you_do_not_have_enough_permission_to_update_this_settings') }}');
                e.preventDefault();
            }
        });
    </script>

@endpush
