@extends('adminmodule::layouts.master')

@section('title', translate('Business_Information'))

@section('content')
    <!-- Main Content -->
    <div class="main-content">
        <form action="{{route('admin.business.setup.info.update-settings')}}" method="post" id="settings_form"
            enctype="multipart/form-data">
            @csrf
            <div class="container-fluid">
                <h2 class="fs-20 fw-bold mb-3 text-capitalize">{{translate('business_management')}}</h2>
                <div class="mb-3">
                    <div class="">
                        @include('businessmanagement::admin.business-setup.partials._business-setup-inline')
                    </div>
                </div>
                <div class="row g-3">
                    <div class="col-12">
                        <div class="card card-body h-100">
                            <div class="mb-20">
                                <h5 class="d-flex align-items-center gap-2 text-capitalize mb-2">
                                    {{translate('Business_Configuration')}}
                                </h5>
                                <p class="mb-0">{{ translate('general_settings_for_business_operation,_trip_behavior,_and_tax_policies.') }}</p>
                            </div>
                            <div class="p-lg-4 p-3 rounded bg-F6F6F6">
                                <div class="row g-4">
                                    <div class="col-lg-6">
                                        <label class="text-capitalize mb-2">
                                            {{translate('Commission Rate')}} (%) <span class="text-danger">*</span>
                                            <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                                data-bs-toggle="tooltip"
                                                title="{{translate('Per-ride commission percentage charged to pilots under the commission earning model.')}}"></i>
                                        </label>
                                        <input type="number" name="trip_commission"
                                            class="form-control" id="business_name"
                                            placeholder="{{translate('Ex: 5')}}" step="0.1"
                                            value="{{$settings->firstWhere('key_name', 'trip_commission')->value ?? ''}}"
                                        tabindex="1">
                                    </div>
                                    <div class="col-lg-6">
                                        <div>
                                            <label class="text-capitalize mb-2">
                                                {{translate('GST')}} (%) <span class="text-danger">*</span>
                                                <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                                    data-bs-toggle="tooltip"
                                                    title="{{translate('enter_the_applicable_gst_rate_for_trip_billing.')}}"></i>
                                            </label>
                                            <input type="number" name="vat_percent" class="form-control"
                                                    id="business_contact_num" tabindex="2"
                                                    placeholder="{{translate('Ex: 5')}}" step="0.1"
                                                    value="{{$settings->firstWhere('key_name', 'vat_percent')->value ?? ''}}">
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-12">
                        <div class="card card-body h-100">
                            <div class="mb-20">
                                <h5 class="d-flex align-items-center gap-2 text-capitalize mb-2">
                                    {{translate('Real-Time_&_Location_Settings')}}
                                </h5>
                                <p class="mb-0">{{ translate('configure_location_settings_and_live_updates_to_track_trips_and_keep_drivers_informed_in_real_time.') }}</p>
                            </div>
                            <div class="p-lg-4 p-3 rounded bg-F6F6F6">
                                <div class="row g-4">
                                    <div class="col-lg-6">
                                        <label class="text-capitalize mb-2">
                                            {{translate('Search_Radius')}} (Km) <span class="text-danger">*</span>
                                            <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                                data-bs-toggle="tooltip"
                                                title="{{translate('defines_how_far_(in_kilometers)_a_customer_can_search_for_nearby_drivers_when_a_ride_request_is_made._by_default,_it_is_set_to_5_kilometers.')}}"></i>
                                        </label>
                                        <input type="number" name="search_radius" class="form-control"
                                            step="any" tabindex="3"
                                            id="business_email" placeholder="{{translate('Ex: 5')}}"
                                            value="{{$settings->firstWhere('key_name', 'search_radius')->value ?? ''}}">

                                    </div>
                                    <div class="col-lg-6">
                                        <div>
                                            <label class="text-capitalize mb-2">
                                                {{translate('Driver_Completion_Radius')}} (Meter) <span class="text-danger">*</span>
                                                <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                                    data-bs-toggle="tooltip"
                                                    title="{{translate('drivers_can_complete_the_ride_within_the_radius_(in_meter)_you_have_set_here._by_default,_it_is_set_to_10_meters.')}}"></i>
                                            </label>
                                            <input type="number" name="driver_completion_radius"
                                                class="form-control" step="any" tabindex="4"
                                                id="driver_completion_radius"
                                                placeholder="{{translate('Ex: 15')}}"
                                                value="{{$settings->firstWhere('key_name', 'driver_completion_radius')->value ?? ''}}">

                                        </div>
                                    </div>
                                    <div class="col-lg-6">
                                        <div>
                                            <label class="text-capitalize mb-2">
                                                {{translate('WebSocket_URL')}} <span class="text-danger">*</span>
                                                <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                                    data-bs-toggle="tooltip"
                                                    title="{{translate('enter_the_websocket_server_url,_that_is_used_for_real-time_communication_between_drivers,_riders,_and_the_system.')}}"></i>
                                            </label>
                                            <input type="text" name="websocket_url" class="form-control"
                                                id="websocket_url" tabindex="5"
                                                placeholder="{{translate('Ex: your_domain_name')}}"
                                                value="{{$settings->firstWhere('key_name', 'websocket_url')->value ?? env('PUSHER_HOST')}}" disabled>
                                        </div>
                                    </div>
                                    <div class="col-lg-6">
                                        <div>
                                            <label class="text-capitalize mb-2">
                                                {{translate('WebSocket_Port')}} <span class="text-danger">*</span>
                                                <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                                    data-bs-toggle="tooltip"
                                                    title="{{translate('specify_the_port_number_for_the_websocket_connection_to_enable_live_tracking_and_instant_updates._port_default_6001.')}}"></i>
                                            </label>
                                            <input type="number" name="websocket_port" class="form-control"
                                                id="business_email" placeholder="{{translate('Ex: 6001')}}" tabindex="6"
                                                value="{{$settings->firstWhere('key_name', 'websocket_port')->value ?? ''}}">
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-12">
                        <div class="card card-body h-100">
                            <div class="mb-20">
                                <h5 class="d-flex align-items-center gap-2 text-capitalize mb-2">
                                    {{translate('Login_&_Security_Settings')}}
                                </h5>
                                <p class="mb-0">{{ translate('manage_login_attempts,_otp_behavior,_and_block_durations.') }}
                                </p>
                            </div>
                            <div class="p-lg-4 p-3 rounded bg-F6F6F6">
                                <div class="row g-4">
                                    <div class="col-lg-4">
                                        <label class="text-capitalize mb-2">
                                            {{translate('Maximum_Login_Attempts')}} <span class="text-danger">*</span>
                                            <i class="bi bi-info-circle-fill text-primary cursor-pointer" data-bs-toggle="tooltip"
                                                title="{{translate('set_the_maximum_number_of_incorrect_login_attempts_allowed_within_a_period.')}}"></i>
                                        </label>
                                        <input type="number" name="maximum_login_hit" class="form-control" tabindex="7"
                                            id="maximum_login_hit" placeholder="{{translate('Ex: 10')}}"
                                            value="{{$settings->firstWhere('key_name', 'maximum_login_hit')->value ?? ''}}">
                                    </div>
                                    <div class="col-lg-4">
                                        <div>
                                            <label class="text-capitalize mb-2">
                                                {{translate('Temporary_Login_Block_Time')}} ({{ translate('In_Seconds') }}) <span class="text-danger">*</span>
                                                <i class="bi bi-info-circle-fill text-primary cursor-pointer" data-bs-toggle="tooltip"
                                                    title="{{translate('duration_(in_seconds)_for_which_a_user_will_be_blocked_after_exceeding_the_maximum_login_attempts.')}}"></i>
                                            </label>
                                            <input type="number" name="temporary_login_block_time"
                                                class="form-control" id="temporary_login_block_time"
                                                placeholder="{{translate('Ex: 10')}}" tabindex="8"
                                                value="{{$settings->firstWhere('key_name', 'temporary_login_block_time')->value ?? ''}}">
                                        </div>
                                    </div>
                                    <div class="col-lg-4">
                                        <div>
                                            <label class="text-capitalize mb-2">
                                                {{translate('Maximum_OTP_Submit_Attempts')}} <span class="text-danger">*</span>
                                                <i class="bi bi-info-circle-fill text-primary cursor-pointer" data-bs-toggle="tooltip"
                                                    title="{{translate('defines_how_many_times_a_user_can_enter_an_incorrect_otp_before_being_temporarily_blocked.')}}"></i>
                                            </label>
                                            <input type="number" name="maximum_otp_hit" class="form-control"
                                                id="maximum_otp_hit" placeholder="{{translate('Ex: 10')}}" tabindex="9"
                                                value="{{$settings->firstWhere('key_name', 'maximum_otp_hit')->value ?? ''}}">
                                        </div>
                                    </div>
                                    <div class="col-lg-4">
                                        <div>
                                            <label class="text-capitalize mb-2">
                                                {{translate('OTP_Resend_Time')}} ({{ translate('In_Seconds') }}) <span class="text-danger">*</span>
                                                <i class="bi bi-info-circle-fill text-primary cursor-pointer" data-bs-toggle="tooltip"
                                                    title="{{translate('set_the_waiting_time_(in_seconds)_before_the_user_can_request_to_resend_the_otp_again.')}}"></i>
                                            </label>
                                            <input type="number" name="otp_resend_time" class="form-control" tabindex="10"
                                                id="otp_resend_time" placeholder="{{translate('Ex: 60')}}"
                                                value="{{$settings->firstWhere('key_name', 'otp_resend_time')->value ?? ''}}">
                                        </div>
                                    </div>
                                    <div class="col-lg-4">
                                        <div>
                                            <label class="text-capitalize mb-2">
                                                {{translate('Temporary_OTP_Block_Time')}} ({{ translate('In_Seconds') }}) <span class="text-danger">*</span>
                                                <i class="bi bi-info-circle-fill text-primary cursor-pointer" data-bs-toggle="tooltip"
                                                    title="{{translate('set_the_time_(in_seconds)_that_a_user_is_restricted_from_otp_verification_after_exceeding_the_maximum_attempt_limit.')}}"></i>
                                            </label>
                                            <input type="number" name="temporary_block_time" class="form-control" tabindex="11"
                                                id="temporary_block_time" placeholder="{{translate('Ex: 600')}}"
                                                value="{{$settings->firstWhere('key_name', 'temporary_block_time')->value ?? ''}}">
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-6">
                        <div class="card card-body h-100">
                            <div class="mb-20">
                                <h5 class="d-flex align-items-center gap-2 text-capitalize mb-2">
                                    {{translate('Fare_Bidding')}}
                                </h5>
                                <p class="mb-0">{{ translate('enable_fare_bidding_between_drivers_and_customers.') }}</p>
                            </div>
                            <div class="p-lg-4 p-3 rounded bg-F6F6F6">
                                <label class="text-capitalize mb-2">
                                    {{translate('allow_drivers_and_customers_to_bid_on_trip_fares.')}}
                                    <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                        data-bs-toggle="tooltip"
                                        title="{{translate('enable_this_option_to_allow_drivers_to_bid_on_ride_fares_instead_of_accepting_fixed_prices.')}}"></i>
                                </label>
                                <label class="form-control d-flex align-items-center justify-content-between">
                                    <label for="customerReview" class="fs-14 lh-1 d-block cursor-pointer text-dark">{{ translate('Status') }}</label>
                                    <label class="switcher">
                                        <input class="switcher_input" type="checkbox" name="bid_on_fare"
                                                id="loyalty_point_switch" tabindex="12"
                                            {{ (businessConfig('bid_on_fare', 'business_settings')?->value ?? 0) == 1 ? 'checked' : ''}}>
                                        <span class="switcher_control"></span>
                                    </label>
                                </label>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-12">
                        <div class="card card-body h-100">
                            <div class="mb-20">
                                <h5 class="d-flex align-items-center gap-2 text-capitalize mb-2">
                                    {{translate('Ride Pilot Earning Model')}}
                                </h5>
                                <p class="mb-0">{{ translate('Choose how ride pilots earn — via commission deduction or subscription-based flat fee.') }}</p>
                            </div>
                            @php
                                $currentEarningModel = businessConfig('earning_model', 'business_settings')?->value ?? 'commission';
                            @endphp
                            <div class="p-lg-4 p-3 rounded bg-F6F6F6 mb-3">
                                <label class="text-capitalize mb-2 fw-semibold">{{translate('Earning Model')}}</label>
                                <div class="d-flex gap-4">
                                    <div class="form-check">
                                        <input class="form-check-input earning-model-radio" type="radio" name="earning_model" id="earning_model_commission" value="commission" {{ $currentEarningModel === 'commission' ? 'checked' : '' }}>
                                        <label class="form-check-label" for="earning_model_commission">
                                            {{translate('Commission Model')}}
                                        </label>
                                    </div>
                                    <div class="form-check">
                                        <input class="form-check-input earning-model-radio" type="radio" name="earning_model" id="earning_model_subscription" value="subscription" {{ $currentEarningModel === 'subscription' ? 'checked' : '' }}>
                                        <label class="form-check-label" for="earning_model_subscription">
                                            {{translate('Subscription Model')}}
                                        </label>
                                    </div>
                                </div>
                            </div>
                            <div class="row g-3">
                                <div class="col-lg-6" id="commission_model_settings" style="{{ $currentEarningModel === 'commission' ? '' : 'display:none;' }}">
                                    <div class="p-lg-4 p-3 rounded bg-F6F6F6">
                                        <label class="text-capitalize mb-2">
                                            {{translate('Commission')}} (%)
                                            <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                                data-bs-toggle="tooltip"
                                                title="{{translate('Percentage commission deducted from each ride.')}}"></i>
                                        </label>
                                        <input type="number" name="trip_commission"
                                            class="form-control"
                                            placeholder="{{translate('Ex: 10')}}" step="0.1"
                                            value="{{$settings->firstWhere('key_name', 'trip_commission')->value ?? ''}}">
                                        <small class="text-muted d-block mt-1">{{translate('Commission + GST will be deducted per ride from pilot')}}</small>
                                    </div>
                                </div>
                                <div class="col-lg-6" id="subscription_model_settings" style="{{ $currentEarningModel === 'subscription' ? '' : 'display:none;' }}">
                                    <div class="p-lg-4 p-3 rounded bg-F6F6F6">
                                        <label class="text-capitalize mb-2">
                                            {{translate('Per-ride Platform Fee')}}
                                            <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                                data-bs-toggle="tooltip"
                                                title="{{translate('Fixed platform fee amount charged per ride in subscription model.')}}"></i>
                                        </label>
                                        <input type="number" name="platform_fee_amount"
                                            class="form-control"
                                            placeholder="{{translate('Ex: 20')}}" step="0.01"
                                            value="{{$settings->firstWhere('key_name', 'platform_fee_amount')->value ?? '0'}}">
                                        <small class="text-muted d-block mt-1">{{translate('Pilots must purchase subscription to accept rides. Platform Fee + GST deducted per ride additionally.')}}</small>
                                        <a href="{{ route('admin.subscription.index') }}" class="btn btn-outline-primary btn-sm mt-2">{{translate('Manage Subscription Plans')}}</a>
                                    </div>
                                </div>
                                <div class="col-lg-6">
                                    <div class="p-lg-4 p-3 rounded bg-F6F6F6">
                                        <label class="text-capitalize mb-2">
                                            {{translate('Negative Balance Limit')}}
                                            <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                                data-bs-toggle="tooltip"
                                                title="{{translate('Auto-lock driver account when negative wallet balance exceeds this limit.')}}"></i>
                                        </label>
                                        <input type="number" name="negative_balance_limit"
                                            class="form-control"
                                            placeholder="{{translate('Ex: 200')}}"
                                            value="{{$settings->firstWhere('key_name', 'negative_balance_limit')->value ?? '200'}}">
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-lg-6">
                        <div class="card card-body h-100">
                            <div class="mb-20">
                                <h5 class="d-flex align-items-center gap-2 text-capitalize mb-2">
                                    {{translate('Parcel Commission Settings')}}
                                </h5>
                                <p class="mb-0">{{ translate('Configure commission-based earning model for parcel delivery pilots.') }}</p>
                            </div>
                            <div class="row g-3">
                                <div class="col-lg-6">
                                    <div class="p-lg-4 p-3 rounded bg-F6F6F6">
                                        <label class="text-capitalize mb-2">
                                            {{translate('Parcel Commission')}}
                                            <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                                data-bs-toggle="tooltip"
                                                title="{{translate('Enable or disable separate commission for parcel deliveries.')}}"></i>
                                        </label>
                                        <label class="form-control d-flex align-items-center justify-content-between">
                                            <label class="fs-14 lh-1 d-block cursor-pointer text-dark">{{ translate('Status') }}</label>
                                            <label class="switcher">
                                                <input class="switcher_input" type="checkbox" name="parcel_commission_enabled"
                                                    {{ (businessConfig('parcel_commission_enabled', 'business_settings')?->value ?? 0) == 1 ? 'checked' : ''}}>
                                                <span class="switcher_control"></span>
                                            </label>
                                        </label>
                                    </div>
                                </div>
                                <div class="col-lg-6">
                                    <div class="p-lg-4 p-3 rounded bg-F6F6F6">
                                        <label class="text-capitalize mb-2">
                                            {{translate('Parcel Commission (%)')}}
                                            <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                                data-bs-toggle="tooltip"
                                                title="{{translate('Commission percentage charged on parcel deliveries. If disabled, the general trip commission rate is used.')}}"></i>
                                        </label>
                                        <input type="number" name="parcel_commission_percent"
                                            class="form-control"
                                            step="0.01"
                                            min="0"
                                            max="100"
                                            placeholder="{{translate('Ex: 15')}}"
                                            value="{{$settings->firstWhere('key_name', 'parcel_commission_percent')->value ?? ''}}">
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-6">
                        <div class="card card-body h-100">
                            <div class="mb-20">
                                <h5 class="d-flex align-items-center gap-2 text-capitalize mb-2">
                                    {{translate('Car Sharing')}}
                                </h5>
                                <p class="mb-0">{{ translate('Configure city and outstation car sharing services independently.') }}</p>
                            </div>
                            <div class="p-lg-4 p-3 rounded bg-F6F6F6">
                                <label class="text-capitalize mb-2">
                                    {{translate('Master Car Sharing Toggle')}}
                                    <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                        data-bs-toggle="tooltip"
                                        title="{{translate('When enabled, customers can opt for shared rides at a discounted fare.')}}"></i>
                                </label>
                                <label class="form-control d-flex align-items-center justify-content-between">
                                    <label class="fs-14 lh-1 d-block cursor-pointer text-dark">{{ translate('Status') }}</label>
                                    <label class="switcher">
                                        <input class="switcher_input" type="checkbox" name="car_sharing_enabled"
                                                {{ (businessConfig('car_sharing_enabled', 'business_settings')?->value ?? 1) == 1 ? 'checked' : ''}}>
                                        <span class="switcher_control"></span>
                                    </label>
                                </label>

                                <div class="mt-3 p-3 border rounded">
                                    <h6 class="mb-2"><i class="bi bi-building"></i> {{translate('City Sharing (Intracity)')}}</h6>
                                    <div class="row g-3">
                                        <div class="col-md-6">
                                            <label class="form-control d-flex align-items-center justify-content-between">
                                                <label class="fs-14 lh-1 d-block cursor-pointer text-dark">{{ translate('Enable City Sharing') }}</label>
                                                <label class="switcher">
                                                    <input class="switcher_input" type="checkbox" name="city_sharing_enabled"
                                                            {{ (businessConfig('city_sharing_enabled', 'business_settings')?->value ?? 1) == 1 ? 'checked' : ''}}>
                                                    <span class="switcher_control"></span>
                                                </label>
                                            </label>
                                        </div>
                                        <div class="col-md-6">
                                            <label class="text-capitalize mb-1">{{translate('Commission (%)')}} <span class="text-danger">*</span></label>
                                            <input type="number" name="city_sharing_commission_percent" step="0.01" min="0" max="100"
                                                class="form-control" value="{{ businessConfig('city_sharing_commission_percent', 'business_settings')?->value ?? 20 }}">
                                        </div>
                                        <div class="col-md-6">
                                            <label class="text-capitalize mb-1">{{translate('GST (%)')}} <span class="text-danger">*</span></label>
                                            <input type="number" name="city_sharing_gst_percent" step="0.01" min="0" max="100"
                                                class="form-control" value="{{ businessConfig('city_sharing_gst_percent', 'business_settings')?->value ?? 5 }}">
                                        </div>
                                        <div class="col-md-6">
                                            <label class="text-capitalize mb-1">{{translate('Max Detour (km)')}} <span class="text-danger">*</span></label>
                                            <input type="number" name="city_sharing_max_detour_km" step="0.1" min="0.5" max="50"
                                                class="form-control" value="{{ businessConfig('city_sharing_max_detour_km', 'business_settings')?->value ?? 3 }}">
                                        </div>
                                    </div>
                                </div>

                                <div class="mt-3 p-3 border rounded">
                                    <h6 class="mb-2"><i class="bi bi-signpost-2"></i> {{translate('Outstation Sharing (Intercity)')}}</h6>
                                    <div class="row g-3">
                                        <div class="col-md-6">
                                            <label class="form-control d-flex align-items-center justify-content-between">
                                                <label class="fs-14 lh-1 d-block cursor-pointer text-dark">{{ translate('Enable Outstation Sharing') }}</label>
                                                <label class="switcher">
                                                    <input class="switcher_input" type="checkbox" name="outstation_sharing_enabled"
                                                            {{ (businessConfig('outstation_sharing_enabled', 'business_settings')?->value ?? 1) == 1 ? 'checked' : ''}}>
                                                    <span class="switcher_control"></span>
                                                </label>
                                            </label>
                                        </div>
                                        <div class="col-md-6">
                                            <label class="text-capitalize mb-1">{{translate('Commission (%)')}} <span class="text-danger">*</span></label>
                                            <input type="number" name="outstation_sharing_commission_percent" step="0.01" min="0" max="100"
                                                class="form-control" value="{{ businessConfig('outstation_sharing_commission_percent', 'business_settings')?->value ?? 15 }}">
                                        </div>
                                        <div class="col-md-6">
                                            <label class="text-capitalize mb-1">{{translate('GST (%)')}} <span class="text-danger">*</span></label>
                                            <input type="number" name="outstation_sharing_gst_percent" step="0.01" min="0" max="100"
                                                class="form-control" value="{{ businessConfig('outstation_sharing_gst_percent', 'business_settings')?->value ?? 5 }}">
                                        </div>
                                        <div class="col-md-6">
                                            <label class="text-capitalize mb-1">{{translate('Max Detour (km)')}} <span class="text-danger">*</span></label>
                                            <input type="number" name="outstation_sharing_max_detour_km" step="0.1" min="0.5" max="100"
                                                class="form-control" value="{{ businessConfig('outstation_sharing_max_detour_km', 'business_settings')?->value ?? 10 }}">
                                        </div>
                                        <div class="col-md-6">
                                            <label class="text-capitalize mb-1">{{translate('Min Distance for Outstation (km)')}} <span class="text-danger">*</span>
                                                <i class="bi bi-info-circle-fill text-primary cursor-pointer" data-bs-toggle="tooltip"
                                                    title="{{translate('Rides above this distance will be classified as outstation sharing.')}}"></i>
                                            </label>
                                            <input type="number" name="outstation_min_distance_km" step="1" min="5" max="500"
                                                class="form-control" value="{{ businessConfig('outstation_min_distance_km', 'business_settings')?->value ?? 30 }}">
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-lg-6">
                        <div class="card card-body h-100">
                            <div class="mb-20">
                                <h5 class="d-flex align-items-center gap-2 text-capitalize mb-2">
                                    {{translate('Pagination_Setting')}}
                                </h5>
                                <p class="mb-0">{{ translate('define_how_many_items_appear_per_page_in_listings.') }}</p>
                            </div>
                            <div class="p-lg-4 p-3 rounded bg-F6F6F6">
                                <label class="text-capitalize mb-2">
                                    {{translate('Pagination_Limit')}} <span class="text-danger">*</span>
                                    <i class="bi bi-info-circle-fill text-primary cursor-pointer" data-bs-toggle="tooltip"
                                        title="{{translate('set_the_number_of_items_(e.g.,_rides,_users,_drivers)_displayed_per_page_in_the_admin_panel_listings._by_default_it_is_10.')}}"></i>
                                </label>
                                <input type="number" name="pagination_limit" tabindex="13"
                                    class="form-control" id="business_email"
                                    placeholder="{{translate('Ex: 15')}}"
                                    value="{{$settings->firstWhere('key_name', 'pagination_limit')->value ?? ''}}">
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="footer-sticky">
                <div class="container-fluid">
                    <div class="btn--container justify-content-end py-4">
                        <button type="reset" class="btn btn-secondary min-w-120 cmn_focus" tabindex="14">{{ translate('reset') }}</button>
                        <button type="submit"
                                class="btn btn-primary min-w-120 cmn_focus" tabindex="15">{{ translate('save_information') }}</button>
                    </div>
                </div>
            </div>
        </form>
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

        $('#settings_form').on('submit', function (e) {
            if (!permission) {
                toastr.error('{{ translate('you_do_not_have_enough_permission_to_update_this_settings') }}');
                e.preventDefault();
            }
        });

        $(document).ready(function () {
            $('.earning-model-radio').on('change', function() {
                if ($(this).val() === 'commission') {
                    $('#commission_model_settings').show();
                    $('#subscription_model_settings').hide();
                } else {
                    $('#commission_model_settings').hide();
                    $('#subscription_model_settings').show();
                }
            });

            //----- sticky footer
            $(window).on('scroll', function () {
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
