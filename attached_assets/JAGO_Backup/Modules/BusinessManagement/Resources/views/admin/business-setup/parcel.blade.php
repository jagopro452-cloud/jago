@extends('adminmodule::layouts.master')

@section('title', translate('Parcel Settings'))

@section('content')
    <!-- Main Content -->
    <div class="main-content">
        <div class="container-fluid">
            <h2 class="fs-22 mb-4 text-capitalize">{{ translate('business_management') }}</h2>

            <div class="mb-3">
                <div class="">
                    @include('businessmanagement::admin.business-setup.partials._business-setup-inline')
                </div>
            </div>

            <div class="card mb-3 text-capitalize">
                <form action="{{ route('admin.business.setup.parcel.tracking-store') . '?type=' . PARCEL_SETTINGS }}"
                      id="parcel_form" method="POST">
                    @csrf
                    <div class="collapsible-card-body">
                        <div class="card-header flex-wrap d-flex align-items-center justify-content-between gap-3">
                            <div class="w-0 flex-grow-1">
                                <h5 class="mb-2">{{ translate('Sent Parcel tracking Link to Customer') }}</h5>
                                <div class="fs-14">
                                    {{ translate('Enabling this option will send the parcel tracking link to the customer via SMS when they place any parcel booking') }}
                                </div>
                            </div>
                            <div class="d-flex max-w-280px w-100 align-items-center gap-2 justify-content-between border rounded py-2 px-3">
                                <label for="parcelTrackingStatus" class="fs-14 text-dark">Status</label>
                                <label class="switcher rounded-pill cmn_focus">
                                    <input class="switcher_input collapsible-card-switcher update-business-setting" tabindex="1"
                                           id="parcelTrackingStatus" type="checkbox" name="parcel_tracking_status"
                                           data-name="parcel_tracking_status" data-type="{{ PARCEL_SETTINGS }}"
                                           data-url="{{ route('admin.business.setup.update-business-setting') }}"
                                           data-icon=" {{ dynamicAsset('public/assets/admin-module/img/parcel_tracking.png') }}"
                                           data-title="{{ translate('Are you sure?') }}"
                                           data-sub-title="{{ ($settings->firstWhere('key_name', 'parcel_tracking_status')->value ?? 0) == 1 ? translate('Do you want to turn OFF Parcel Tracking Link for customer? When it’s off the customer don’t received any parcel tracking link message.') : translate('Do you want to turn ON Parcel Tracking Link for customer? When turned ON, customers will receive a tracking link once the parcel is confirmed.') }}"
                                           data-confirm-btn="{{ ($settings->firstWhere('key_name', 'parcel_tracking_status')->value ?? 0) == 1 ? translate('Turn Off') : translate('Turn On') }}"
                                        {{ ($settings->firstWhere('key_name', 'parcel_tracking_status')->value ?? 0) == 1 ? 'checked' : '' }}>
                                    <span class="switcher_control"></span>
                                </label>
                            </div>
                        </div>
                        <div class="card-body collapsible-card-content">
                            <div>
                                <div class="mb-4">
                                    <h5 class="mb-2">{{ translate('Tracking Link Template Setup') }}</h5>
                                    <div class="fs-14">
                                        {{ translate('Hear you can write a massage body. Customer Name, Parcel ID & Tracking link will generate automatically for each individual parcel.') }}
                                    </div>
                                </div>
                                <div class="row g-4 align-items-end">
                                    <div class="col-md-7">
                                        <div class="bg-F6F6F6 rounded p-4 p-md-30px">
                                            <div class="mb-3">
                                                <label for="trackingLinkTemplate"
                                                       class="form-label">{{ translate('Message') }}</label>
                                                <div class="character-count">
                                                    <textarea class="form-control character-count-field" maxlength="200"
                                                              data-max-character="200" id="trackingLinkTemplate"
                                                              name="parcel_tracking_message" rows="4" tabindex="2"
                                                              placeholder="{{ translate('Write your message here') }}">{{ $settings->firstWhere('key_name', 'parcel_tracking_message')->value ?? old('parcel_tracking_message') }}</textarea>
                                                    <span class="text-end text-right d-block text-muted mt-1">{{ translate('0/200') }}</span>
                                                </div>
                                            </div>
                                            <div class="d-flex gap-3 justify-content-end">
                                                <button
                                                    class="btn btn-secondary h-40px min-w-100px justify-content-center"
                                                    type="reset" tabindex="3">{{ translate('Reset') }}</button>
                                                <button
                                                    class="btn btn-primary h-40px min-w-100px justify-content-center" type="submit" tabindex="4">{{ translate('Save') }}</button>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-md-5">
                                        <div class="order-track-mocup">
                                            <div class="text-center">
                                                <img
                                                    src="{{ dynamicAsset('public/assets/admin-module/img/order-track-mocup.png') }}"
                                                    alt="">
                                            </div>
                                            <div class="order-track-mocup-text bg-F6F6F6">
                                                {{ translate('Dear Receiver') }}
                                                <br>
                                                <br>
                                                {{ translate('Parcel ID is') }}
                                                #123456. {{ translate('You can track this parcel from this link') }}
                                                <br>
                                                <a href="" class="text-0177CD">
                                                    {{ url('/') }}/track_order/123456876548
                                                </a>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-md-12">
                                        <div class="card bg-primary-light border-0">
                                            <div class="card-body">
                                                <span class="title-color d-flex align-items-center gap-2">
                                                    <i class="bi bi-lightbulb fs-18"></i>
                                                    <span class="fs-12 lh-base">
                                                        {{ translate('In Message field you can’t change the') }}
                                                        {CustomerName}, {ParcelId} & {TrackingLink}.
                                                        {{ translate('They will automatically generate. You can only edit other text.') }}
                                                    </span>
                                                </span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </form>
            </div>

            <div class="card mb-3 text-capitalize">
                <form action="{{ route('admin.business.setup.parcel.store') . '?type=' . PARCEL_SETTINGS }}"
                      id="receiver_otp_form" method="POST">
                    @csrf
                    <div class="collapsible-card-body">
                        <div class="card-header border-0 d-flex align-items-center justify-content-between gap-2">
                            <div class="w-0 flex-grow-1">
                                <h5 class="mb-2">{{ translate('Receiver OTP Verification') }}</h5>
                                <div class="fs-12">
                                    {{ translate('When enabled, a one-time password (OTP) will be sent to the parcel receiver. The pilot must verify this OTP before completing the delivery.') }}
                                </div>
                            </div>
                            <label class="switcher">
                                <input class="switcher_input" type="checkbox" name="parcel_receiver_otp_verification"
                                       {{ ($settings->firstWhere('key_name', 'parcel_receiver_otp_verification')->value ?? 0) == 1 ? 'checked' : '' }}>
                                <span class="switcher_control"></span>
                            </label>
                        </div>
                        <div class="d-flex gap-3 flex-wrap justify-content-end p-3">
                            <button class="btn btn-secondary text-uppercase cmn_focus" type="reset">{{ translate('Reset') }}</button>
                            <button type="submit" class="btn btn-primary text-uppercase cmn_focus">{{ translate('submit') }}</button>
                        </div>
                    </div>
                </form>
            </div>

            <div class="card mb-3 text-capitalize">
                <form action="{{ route('admin.business.setup.parcel.store') . '?type=' . PARCEL_SETTINGS }}"
                      id="parcel_discount_form" method="POST">
                    @csrf
                    <div class="card-header border-0">
                        <div class="w-0 flex-grow-1">
                            <h5 class="mb-2">{{ translate('Parcel Special Discounts & Fare Settings') }}</h5>
                            <div class="fs-14">
                                {{ translate('Configure special discount programs and outstation fare settings for parcel deliveries.') }}
                            </div>
                        </div>
                    </div>
                    <div class="card-body">
                        <div class="row g-3 mb-4">
                            <div class="col-12">
                                <h6 class="text-primary mb-2">{{ translate('Senior Citizen Discount') }}</h6>
                            </div>
                            <div class="col-lg-4">
                                <div class="p-3 rounded bg-F6F6F6">
                                    <label class="text-capitalize mb-2">
                                        {{ translate('Enable Senior Citizen Discount') }}
                                        <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                            data-bs-toggle="tooltip"
                                            title="{{ translate('Enable discount for verified senior citizen customers on parcel deliveries.') }}"></i>
                                    </label>
                                    <label class="form-control d-flex align-items-center justify-content-between">
                                        <span class="fs-14 lh-1 text-dark">{{ translate('Status') }}</span>
                                        <label class="switcher">
                                            <input class="switcher_input" type="checkbox" name="senior_citizen_discount_enabled"
                                                {{ ($settings->firstWhere('key_name', 'senior_citizen_discount_enabled')->value ?? 0) == 1 ? 'checked' : '' }}>
                                            <span class="switcher_control"></span>
                                        </label>
                                    </label>
                                </div>
                            </div>
                            <div class="col-lg-4">
                                <div class="p-3 rounded bg-F6F6F6">
                                    <label class="text-capitalize mb-2">
                                        {{ translate('Senior Discount (%)') }}
                                        <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                            data-bs-toggle="tooltip"
                                            title="{{ translate('Percentage discount applied on parcel fares for verified senior citizens.') }}"></i>
                                    </label>
                                    <input type="number" name="senior_citizen_discount_percent"
                                        class="form-control" step="0.01" min="0" max="50"
                                        placeholder="{{ translate('Ex: 10') }}"
                                        value="{{ $settings->firstWhere('key_name', 'senior_citizen_discount_percent')->value ?? '10' }}">
                                </div>
                            </div>
                            <div class="col-lg-4">
                                <div class="p-3 rounded bg-F6F6F6">
                                    <label class="text-capitalize mb-2">
                                        {{ translate('Minimum Age') }}
                                        <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                            data-bs-toggle="tooltip"
                                            title="{{ translate('Minimum age to qualify for senior citizen discount.') }}"></i>
                                    </label>
                                    <input type="number" name="senior_citizen_min_age"
                                        class="form-control" min="50" max="100"
                                        placeholder="{{ translate('Ex: 60') }}"
                                        value="{{ $settings->firstWhere('key_name', 'senior_citizen_min_age')->value ?? '60' }}">
                                </div>
                            </div>
                        </div>

                        <div class="row g-3 mb-4">
                            <div class="col-12">
                                <h6 class="text-primary mb-2">{{ translate('Student Discount') }}</h6>
                            </div>
                            <div class="col-lg-4">
                                <div class="p-3 rounded bg-F6F6F6">
                                    <label class="text-capitalize mb-2">
                                        {{ translate('Enable Student Discount') }}
                                        <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                            data-bs-toggle="tooltip"
                                            title="{{ translate('Enable discount for verified student customers on parcel deliveries.') }}"></i>
                                    </label>
                                    <label class="form-control d-flex align-items-center justify-content-between">
                                        <span class="fs-14 lh-1 text-dark">{{ translate('Status') }}</span>
                                        <label class="switcher">
                                            <input class="switcher_input" type="checkbox" name="student_discount_enabled"
                                                {{ ($settings->firstWhere('key_name', 'student_discount_enabled')->value ?? 0) == 1 ? 'checked' : '' }}>
                                            <span class="switcher_control"></span>
                                        </label>
                                    </label>
                                </div>
                            </div>
                            <div class="col-lg-4">
                                <div class="p-3 rounded bg-F6F6F6">
                                    <label class="text-capitalize mb-2">
                                        {{ translate('Student Discount (%)') }}
                                        <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                            data-bs-toggle="tooltip"
                                            title="{{ translate('Percentage discount applied on parcel fares for verified students.') }}"></i>
                                    </label>
                                    <input type="number" name="student_discount_percent"
                                        class="form-control" step="0.01" min="0" max="50"
                                        placeholder="{{ translate('Ex: 15') }}"
                                        value="{{ $settings->firstWhere('key_name', 'student_discount_percent')->value ?? '15' }}">
                                </div>
                            </div>
                        </div>

                        <div class="row g-3 mb-3">
                            <div class="col-12">
                                <h6 class="text-primary mb-2">{{ translate('Outstation / Long Distance Parcel Delivery') }}</h6>
                            </div>
                            <div class="col-lg-4">
                                <div class="p-3 rounded bg-F6F6F6">
                                    <label class="text-capitalize mb-2">
                                        {{ translate('Outstation Service') }}
                                        <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                            data-bs-toggle="tooltip"
                                            title="{{ translate('Enable outstation/long-distance parcel delivery service.') }}"></i>
                                    </label>
                                    <label class="form-control d-flex align-items-center justify-content-between">
                                        <span class="fs-14 lh-1 text-dark">{{ translate('Status') }}</span>
                                        <label class="switcher">
                                            <input class="switcher_input" type="checkbox" name="outstation_service_enabled"
                                                {{ ($settings->firstWhere('key_name', 'outstation_service_enabled')->value ?? 0) == 1 ? 'checked' : '' }}>
                                            <span class="switcher_control"></span>
                                        </label>
                                    </label>
                                </div>
                            </div>
                            <div class="col-lg-4">
                                <div class="p-3 rounded bg-F6F6F6">
                                    <label class="text-capitalize mb-2">
                                        {{ translate('Min Distance (KM)') }}
                                        <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                            data-bs-toggle="tooltip"
                                            title="{{ translate('Minimum distance in KM for a parcel to qualify as outstation delivery.') }}"></i>
                                    </label>
                                    <input type="number" name="outstation_min_distance_km"
                                        class="form-control" min="10"
                                        placeholder="{{ translate('Ex: 50') }}"
                                        value="{{ $settings->firstWhere('key_name', 'outstation_min_distance_km')->value ?? '50' }}">
                                </div>
                            </div>
                            <div class="col-lg-4">
                                <div class="p-3 rounded bg-F6F6F6">
                                    <label class="text-capitalize mb-2">
                                        {{ translate('Fare Multiplier') }}
                                        <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                            data-bs-toggle="tooltip"
                                            title="{{ translate('Fare multiplier applied for outstation parcel deliveries. E.g., 1.5 means 1.5x the normal fare.') }}"></i>
                                    </label>
                                    <input type="number" name="outstation_fare_multiplier"
                                        class="form-control" step="0.1" min="1" max="5"
                                        placeholder="{{ translate('Ex: 1.5') }}"
                                        value="{{ $settings->firstWhere('key_name', 'outstation_fare_multiplier')->value ?? '1.5' }}">
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="d-flex gap-3 flex-wrap justify-content-end p-3">
                        <button class="btn btn-secondary text-uppercase" type="reset">{{ translate('Reset') }}</button>
                        <button type="submit" class="btn btn-primary text-uppercase">{{ translate('Save') }}</button>
                    </div>
                </form>
            </div>

            <div class="card mb-3 text-capitalize">
                <form action="{{ route('admin.business.setup.parcel.store') . '?type=' . PARCEL_SETTINGS }}"
                      id="parcel_form" method="POST">
                    @csrf
                    <div class="collapsible-card-body">
                        <div class="card-header border-0 d-flex align-items-center justify-content-between gap-2">
                            <div class="w-0 flex-grow-1">
                                <h5 class="mb-2">{{ translate('Parcel Return Time & Fee') }}</h5>
                                <div class="fs-14">
                                    {{ translate('When the toggle is turned ON, the parcel return time and fee are activated.') }} {{ translate(' when turned OFF, they are deactivated.') }}
                                </div>
                            </div>
                            <div class="d-flex align-items-center gap-2">
                                <a href="javascript:"
                                class="text-info fw-semibold fs-12 text-nowrap d-flex view-btn">
                                    <span class="text-underline">{{ translate('View') }}</span>
                                    <span><i class="tio-arrow-downward"></i> </span>
                                </a>
                                <label class="switcher cmn_focus rounded-pill">
                                    <input class="switcher_input collapsible-card-switcher update-business-setting"
                                           id="parcelReturnTimeFeeStatus" type="checkbox"
                                           name="parcel_return_time_fee_status" tabindex="5"
                                           data-name="parcel_return_time_fee_status" data-type="{{ PARCEL_SETTINGS }}"
                                           data-url="{{ route('admin.business.setup.update-business-setting') }}"
                                           data-icon=" {{ dynamicAsset('public/assets/admin-module/img/parcel_return.png') }}"
                                           data-title="{{ translate('Are you sure?') }}"
                                           data-sub-title="{{ ($settings->firstWhere('key_name', 'parcel_return_time_fee_status')->value ?? 0) == 1 ? translate('Do you want to turn OFF Parcel Return Time & Fee for driver? When it’s off the driver don’t need to pay return fee for delay. ') : translate('Do you want to turn ON Parcel Return Time & Fee for driver? When it’s ON, the driver need to pay parcel return delay fee. ') }}"
                                           data-confirm-btn="{{ ($settings->firstWhere('key_name', 'parcel_return_time_fee_status')->value ?? 0) == 1 ? translate('Turn Off') : translate('Turn On') }}"
                                        {{ ($settings->firstWhere('key_name', 'parcel_return_time_fee_status')->value ?? 0) == 1 ? 'checked' : '' }}>
                                    <span class="switcher_control"></span>
                                </label>
                            </div>
                        </div>


                        <div class="card-body collapsible-card-content">
                            <div>
                                <div class="bg-F6F6F6 rounded p-lg-4 p-3">
                                    <div class="row g-4">
                                        <div class="col-sm-6">
                                            <label for="returnTimeForDriver"
                                                   class="form-label">{{ translate('Limit Return Time for Driver') }} <i
                                                    class="bi bi-info-circle-fill text-primary cursor-pointer"
                                                    data-bs-toggle="tooltip"
                                                    data-bs-title="{{ translate('Set the maximum time after a parcel delivery is canceled that the driver must return the parcel to the customer.') }}"></i></label>
                                            <div class="input-group input--group">
                                                <input type="number" name="return_time_for_driver" id="returnTimeForDriver"
                                                       step="1" min="1" max="99999999" class="form-control"
                                                       value="{{ $settings->firstWhere('key_name', 'return_time_for_driver')?->value }}"
                                                       placeholder="Ex : 5" tabindex="6">
                                                <select class="form-select" name="return_time_type_for_driver" tabindex="7">
                                                    <option value="day"
                                                        {{ $settings->firstWhere('key_name', 'return_time_type_for_driver')?->value == 'day' ? 'selected' : '' }}>
                                                        {{ translate('Day') }}</option>
                                                    <option value="hour"
                                                        {{ $settings->firstWhere('key_name', 'return_time_type_for_driver')?->value == 'hour' ? 'selected' : '' }}>
                                                        {{ translate('Hour') }}</option>
                                                </select>
                                            </div>
                                        </div>
                                        <div class="col-sm-6">
                                            <label for="returnFeeForDriverTimeExceed"
                                                   class="form-label">{{ translate('Set Driver Late Return Penalty') }}
                                                ({{ getSession('currency_symbol') }}) <i
                                                    class="bi bi-info-circle-fill text-primary cursor-pointer"
                                                    data-bs-toggle="tooltip"
                                                    data-bs-title="{{ translate('Set the charge that drivers will pay if they fail to return a canceled parcel within the specified time limit.') }}"></i></label>
                                            <input type="number" name="return_fee_for_driver_time_exceed" min="0"
                                                   max="99999999" step="{{ stepValue() }}" id="returnFeeForDriverTimeExceed"
                                                   class="form-control" placeholder="Ex : 2.50"
                                                   value="{{ $settings->firstWhere('key_name', 'return_fee_for_driver_time_exceed')?->value }}" tabindex="8">
                                        </div>
                                        <div class="col-sm-6">
                                            <div
                                                class="form-control h-auto cmn_focus gap-2 align-items-center d-flex justify-content-between">
                                                <div class="fw-medium gap-2 text-capitalize">
                                                    <div class="form-check form-check-inline d-flex align-items-center mb-0">
                                                        <input class="form-check-input mt-1" type="checkbox" id="inlineCheckbox2"
                                                               value="on" name="do_not_charge_customer_return_fee" {{ ($settings->firstWhere('key_name', 'do_not_charge_customer_return_fee')?->value ?? 1) ? 'checked' : '' }}>
                                                        <label class="form-check-label lh-1 ms-2"
                                                               for="inlineCheckbox2">{{ translate('Do Not Charge Customer Return Fee If Deliveryman Cancels') }}</label>
                                                    </div>
                                                </div>
                                                <div class="position-relative">
                                                    <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                                       data-bs-toggle="tooltip"
                                                       data-bs-title="{{ translate('Set the maximum time allowed (in minutes or hours) for a driver to return undelivered parcels.')  }}">
                                                    </i>
                                                </div>

                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div class="d-flex gap-3 justify-content-end mt-4">
                                    <button type="reset" class="btn btn-light justify-content-center fw-semibold cmn_focus">
                                        Reset
                                    </button>
                                    <button type="submit"
                                            class="btn btn-primary cmn_focus" tabindex="9">{{ translate('submit') }}</button>
                                </div>
                            </div>
                        </div>
                    </div>
                </form>
            </div>
            <div class="row">
                <div class="col-lg-6">
                    <div class="card mb-3">
                        <div class="card-header border-0">
                            <h5 class="mb-2">
                                {{ translate('Parcel weight Unit') }}
                            </h5>
                            <div class="fs-14">
                                {{ translate('Choose the Weight unit from the dropdown list. This selected Unit will be applicable for all weight measurements') }}
                            </div>
                        </div>
                        <div class="card-body">
                            <form action="{{ route('admin.business.setup.parcel.store-parcel-weight-unit') }}"
                                  method="post">
                                @csrf
                                <div class="bg-F6F6F6 rounded p-lg-4 p-3">
                                    <div class="input-group input--group">
                                        <label for="" class="form-label">
                                            {{ translate('Set Unit') }}
                                        </label>
                                        <select class="js-select cmn_focus" id="" name="parcel_weight_unit" tabindex="10">
                                            @foreach(WEIGHT_UNIT as $key => $value)
                                                <option value="{{ $key }}"
                                                    {{ $settings->firstWhere('key_name', 'parcel_weight_unit')?->value == $key ? 'selected' : '' }}>
                                                    {{ translate($key) }} ({{ translate($value) }})
                                                </option>
                                            @endforeach
                                        </select>
                                    </div>
                                </div>
                                <div class="d-flex gap-3 flex-wrap justify-content-end mt-4">
                                    <button type="reset" class="btn btn-light justify-content-center fw-semibold cmn_focus">
                                        Reset
                                    </button>
                                    <button type="submit"
                                            class="btn btn-primary text-capitalize cmn_focus" tabindex="11">{{ translate('submit') }}</button>
                                </div>
                            </form>

                        </div>
                    </div>
                </div>
                <div class="col-lg-6">
                    <div class="card mb-3">
                        <form action="{{ route('admin.business.setup.parcel.store-maximum-parcel-weight') }}"
                              id="parcel_form" method="POST">
                            @csrf
                            <div class="collapsible-card-body">
                                <div class="card-header border-0 d-flex align-items-center justify-content-between gap-2">
                                    <div class="w-0 flex-grow-1">
                                        <h5 class="mb-2">{{ translate('Parcel weight limit') }}</h5>
                                        <div class="fs-14">
                                            {{ translate('If turned ON, customer will notify if their requested weight exceeds the capacity.') }}
                                        </div>
                                    </div>
                                    <a href="javascript:"
                                       class="text-info fw-semibold fs-12 text-nowrap d-flex view-btn">
                                        <span class="text-underline">{{ translate('View') }}</span>
                                        @if(($settings->firstWhere('key_name', 'max_parcel_weight_status')->value ?? 0) == 1 )
                                            <span><i class="tio-arrow-upward"></i> </span>
                                        @else
                                            <span><i class="tio-arrow-downward"></i> </span>
                                        @endif
                                    </a>
                                    <label class="switcher cmn_focus rounded-pill">
                                        <input class="switcher_input collapsible-card-switcher update-business-setting"
                                               id="maxParcelWeightStatus" type="checkbox" tabindex="12"
                                               name="max_parcel_weight_status"
                                               data-name="max_parcel_weight_status" data-type="{{ PARCEL_SETTINGS }}"
                                               data-url="{{ route('admin.business.setup.update-business-setting') }}"
                                               data-icon=" {{ dynamicAsset('public/assets/admin-module/img/parcel_return.png') }}"
                                               data-title="{{ translate('Are you sure?') }}"
                                               data-sub-title="{{ ($settings->firstWhere('key_name', 'max_parcel_weight_status')->value ?? 0) == 1 ? translate('If the toggle is turned OFF, Customer will not notify if their requested weight exceeds the capacity.') : translate('If the toggle is turned ON, Customer will notify if their requested weight exceeds the capacity.') }}"
                                               data-confirm-btn="{{ ($settings->firstWhere('key_name', 'max_parcel_weight_status')->value ?? 0) == 1 ? translate('Turn Off') : translate('Turn On') }}"
                                            {{ ($settings->firstWhere('key_name', 'max_parcel_weight_status')->value ?? 0) == 1 ? 'checked' : '' }}>
                                        <span class="switcher_control"></span>
                                    </label>
                                </div>

                                <div class="card-body collapsible-card-content">
                                    <div>
                                        <div class="bg-F6F6F6 rounded p-lg-4 p-3">
                                            <div class="row g-3">
                                                <div class="col-sm-12">
                                                    <label for=""
                                                           class="form-label">{{ translate('Max Parcel weight Limit') .' ('.$settings->firstWhere('key_name', 'parcel_weight_unit')?->value.')' }}
                                                    </label>
                                                    <div class="input-group input--group">
                                                        <input type="number" name="max_parcel_weight" id="maxParcelWeight"
                                                               step="0.01" min="0.01" max="99999999" tabindex="13"
                                                               class="form-control"
                                                               value="{{ $settings->firstWhere('key_name', 'max_parcel_weight')?->value }}"
                                                               {{ ($settings->firstWhere('key_name', 'max_parcel_weight_status')->value ?? 0) == 1 ? '' : 'disabled' }}
                                                               placeholder="{{translate("Ex: 15 ").$settings->firstWhere('key_name', 'parcel_weight_unit')?->value}}">

                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="d-flex gap-3 justify-content-end mt-4">
                                            <button type="reset" class="btn btn-light justify-content-center fw-semibold cmn_focus">
                                                Reset
                                            </button>
                                            <button type="submit"
                                                    class="btn btn-primary text-capitalize cmn_focus" tabindex="14" {{ ($settings->firstWhere('key_name', 'max_parcel_weight_status')->value ?? 0) == 1 ? '' : 'disabled' }}>{{ translate('submit') }}</button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
            <div class="card mb-3 text-capitalize">
                <div class="card-header border-0">
                    <h5 class="mb-2">
                        <i class="bi bi-person-fill-gear"></i>
                        {{ translate('Parcel cancellation Reason') }}
                        <i class="bi bi-info-circle-fill fs-14 text-primary cursor-pointer" data-bs-toggle="tooltip"
                           title="{{ translate('changes_may_take_some_hours_in_app') }}"></i>
                    </h5>
                    <div class="fs-14">
                        {{ translate('Here you can add the reasons that customer & user will select for cancel parcel') }}
                    </div>
                </div>
                <div class="card-body">
                    <form action="{{ route('admin.business.setup.parcel.cancellation_reason.store') }}" method="post">
                        @csrf
                        <div class="bg-F6F6F6 rounded p-lg-4 p-3">
                            <div class="row gy-3 align-items-start">
                                <div class="col-sm-6 col-md-6">
                                    <label for="title" class="mb-3 d-flex align-items-center fw-medium gap-2">
                                        {{ translate('parcel_cancellation_reason') }}
                                        <small>({{ translate('Max 255 character') }})</small>
                                        <i class="bi bi-info-circle-fill text-primary cursor-pointer"
                                           data-bs-toggle="tooltip"
                                           title="{{ translate('Add or manage standard reasons customers can choose when cancelling parcel deliveries.=') }}">
                                        </i>
                                    </label>
                                    <div class="character-count">
                                        <input id="title" name="title" type="text"
                                               placeholder="{{ translate('Ex : vehicle problem') }}" tabindex="15"
                                               class="form-control character-count-field" maxlength="255"
                                               data-max-character="255" required>
                                        <span class="d-flex justify-content-end mt-1 text-muted">{{ translate('0/255') }}</span>
                                    </div>
                                </div>
                                <div class="col-sm-6 col-md-3">
                                    <label for="cancellationType" class="mb-3 d-flex align-items-center fw-medium gap-2">
                                        {{ translate('cancellation_type') }}
                                    </label>
                                    <select class="js-select cmn_focus" id="cancellationType" name="cancellation_type" tabindex="16" required>
                                        <option value="" disabled selected>{{ translate('select_cancellation_type') }}
                                        </option>
                                        @foreach (CANCELLATION_TYPE as $key => $item)
                                            <option value="{{ $key }}">{{ translate($item) }}</option>
                                        @endforeach
                                    </select>
                                </div>
                                <div class="col-sm-6 col-md-3">
                                    <label for="userType" class="mb-3 d-flex align-items-center fw-medium gap-2">
                                        {{ translate('user_type') }}
                                    </label>
                                    <select class="js-select cmn_focus" id="userType" name="user_type" required tabindex="17">
                                        <option value="" disabled selected>{{ translate('select_user_type') }}</option>
                                        <option value="driver">{{ translate('driver') }}</option>
                                        <option value="customer">{{ translate('customer') }}</option>
                                    </select>
                                </div>
                            </div>
                        </div>
                        <div class="d-flex gap-3 flex-wrap justify-content-end mt-4">
                             <button type="reset" class="btn btn-light justify-content-center fw-semibold cmn_focus">
                                Reset
                            </button>
                            <button type="submit"
                                    class="btn btn-primary text-capitalize cmn_focus" tabindex="18">{{ translate('submit') }}</button>
                        </div>
                    </form>
                    <div class=" border-top pt-4 mt-4">
                        <div class="mb-20 border-0 d-flex flex-wrap gap-3 justify-content-between align-items-center">
                            <h5 class="d-flex align-items-center gap-2 m-0">
                                <i class="bi bi-person-fill-gear"></i>
                                {{ translate('Parcel Cancellation Reason List') }}
                            </h5>
                        </div>
                        <div class="card-body p-0">
                            <div class="table-responsive">
                                <table class="table table-borderless align-middle">
                                    <thead class="table-light align-middle">
                                    <tr>
                                        <th class="sl">{{ translate('SL') }}</th>
                                        <th class="text-capitalize">{{ translate('Reason') }}</th>
                                        <th class="text-capitalize text-nowrap">{{ translate('cancellation_type') }}</th>
                                        <th class="text-capitalize text-nowrap">{{ translate('user_type') }}</th>
                                        <th class="text-capitalize">{{ translate('Status') }}</th>
                                        <th class="text-center action">{{ translate('Action') }}</th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                    @forelse($cancellationReasons as $key => $cancellationReason)
                                        <tr>
                                            <td class="sl">{{ $key + $cancellationReasons->firstItem() }}</td>
                                            <td>
                                                <p class="m-0 max-w-450 min-w-200">{{ $cancellationReason->title }}</p>
                                            </td>
                                            <td class="text-nowrap">
                                                {{ CANCELLATION_TYPE[$cancellationReason->cancellation_type] }}
                                            </td>
                                            <td>
                                                {{ $cancellationReason->user_type == 'driver' ? translate('driver') : translate('customer') }}
                                                {{ $cancellationReason->status }}
                                            </td>
                                            <td class="text-center">
                                                <label class="switcher mx-auto">
                                                    <input class="switcher_input status-change"
                                                           data-url="{{ route('admin.business.setup.parcel.cancellation_reason.status') }}"
                                                           id="{{ $cancellationReason->id }}" type="checkbox" name="status"
                                                        {{ $cancellationReason->is_active == 1 ? 'checked' : '' }}>
                                                    <span class="switcher_control"></span>
                                                </label>
                                            </td>
                                            <td>
                                                <div class="d-flex justify-content-center gap-2 align-items-center">
                                                    <button class="btn btn-outline-primary btn-action editData"
                                                            data-id="{{ $cancellationReason->id }}">
                                                        <i class="bi bi-pencil-fill"></i>
                                                    </button>
                                                    <button data-id="delete-{{ $cancellationReason?->id }}"
                                                            data-message="{{ translate('want_to_delete_this_cancellation_reason?') }}"
                                                            type="button" class="btn btn-outline-danger btn-action form-alert">
                                                        <i class="bi bi-trash-fill"></i>
                                                    </button>
                                                    <form
                                                        action="{{ route('admin.business.setup.parcel.cancellation_reason.delete', ['id' => $cancellationReason?->id]) }}"
                                                        id="delete-{{ $cancellationReason?->id }}" method="post">
                                                        @csrf
                                                        @method('delete')
                                                    </form>
                                                </div>
                                            </td>
                                        </tr>
                                    @empty
                                        <tr>
                                            <td colspan="6">
                                                <div
                                                    class="d-flex flex-column justify-content-center align-items-center gap-2 py-3">
                                                    <img
                                                        src="{{ dynamicAsset('public/assets/admin-module/img/empty-icons/no-data-found.svg') }}"
                                                        alt="" width="100">
                                                    <p class="text-center">{{ translate('no_data_available') }}</p>
                                                </div>
                                            </td>
                                        </tr>
                                    @endforelse
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <!-- End Main Content -->
    <div class="d-flex justify-content-end mt-3">
        {{ $cancellationReasons->links() }}
    </div>

    <div class="modal fade" id="editDataModal">
        <div class="modal-dialog" role="document">
            <div class="modal-content">
                <!-- End Main Content -->
            </div>
        </div>
    </div>

@endsection

@push('script')
    <script>
        "use strict";
        if ({{ $smsConfiguration }}) {
            let bootstrapModal = new bootstrap.Modal(document.getElementById("smsGatewayWarningModal"));
            bootstrapModal.show();
            let url = "{{ route('admin.business.configuration.third-party.sms-gateway.index') }}"
            $("#smsGatewayWarningModalConfirmBtn").attr('href', url)
        }

        // Collapse card with switcher
        function collapsibleCard(thisInput) {
            let $card = thisInput.closest('.collapsible-card-body');
            let $content = $card.children('.collapsible-card-content');
            if (thisInput.prop('checked')) {
                $content.slideDown();
            } else {
                $content.slideUp();
            }
        }

        $('.collapsible-card-switcher').each(function () {
            collapsibleCard($(this))
        });
        // Collapse card with switcher ends

        let permission = false;
        @can('business_edit')
            permission = true;
        @endcan

        $('#trips_form').on('submit', function (e) {
            if (!permission) {
                toastr.error('{{ translate('you_do_not_have_enough_permission_to_update_this_settings') }}');
                e.preventDefault();
            }
        });
        $(document).ready(function () {
            $('.editData').click(function () {
                let id = $(this).data('id');
                let url = "{{ route('admin.business.setup.parcel.cancellation_reason.edit', ':id') }}";
                url = url.replace(':id', id);
                $.get({
                    url: url,
                    success: function(data) {
                        $('#editDataModal .modal-content').html(data);
                        $('#updateForm').removeClass('d-none');
                        $('#editDataModal').modal('show');
                        $('.character-count-field').on('keyup change', function() {
                            initialCharacterCount($(this));
                        });
                        $('.character-count-field').each(function() {
                            initialCharacterCount($(this));
                        });
                    },
                    error: function(xhr, status, error) {
                        console.log(error);
                    }
                });
            });
        });
    </script>
@endpush
