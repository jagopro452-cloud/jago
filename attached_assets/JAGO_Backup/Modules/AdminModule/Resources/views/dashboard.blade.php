@section('title', translate('dashboard'))

@extends('adminmodule::layouts.master')

@push('css_or_js')
    <link rel="stylesheet" href="{{dynamicAsset('public/assets/admin-module/plugins/apex/apexcharts.css')}}"/>
    <style>
        .jd-banner {
            background: linear-gradient(135deg, #2563EB 0%, #1E3A8A 60%, #1e40af 100%) !important;
            border-radius: 16px !important;
            padding: 30px 32px !important;
            color: #fff !important;
            position: relative;
            overflow: hidden;
            margin-bottom: 24px;
            border: none !important;
            box-shadow: 0 4px 20px rgba(37,99,235,0.25) !important;
        }
        .jd-banner::before {
            content: '';
            position: absolute;
            top: -60px;
            right: -40px;
            width: 200px;
            height: 200px;
            background: rgba(255,255,255,0.08);
            border-radius: 50%;
            pointer-events: none;
        }
        .jd-banner::after {
            content: '';
            position: absolute;
            bottom: -80px;
            right: 25%;
            width: 160px;
            height: 160px;
            background: rgba(255,255,255,0.05);
            border-radius: 50%;
            pointer-events: none;
        }
        .jd-banner-inner {
            display: flex;
            align-items: center;
            justify-content: space-between;
            position: relative;
            z-index: 1;
            flex-wrap: wrap;
            gap: 16px;
        }
        .jd-avatar {
            width: 56px;
            height: 56px;
            border-radius: 14px;
            background: rgba(255,255,255,0.18) !important;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 26px;
            color: #fff !important;
            flex-shrink: 0;
        }
        .jd-banner h3 {
            font-size: 24px !important;
            font-weight: 700 !important;
            margin-bottom: 4px !important;
            color: #fff !important;
        }
        .jd-banner p {
            font-size: 14px !important;
            margin: 0 !important;
            color: rgba(255,255,255,0.85) !important;
        }
        .jd-date-badge {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: rgba(255,255,255,0.15) !important;
            padding: 10px 18px;
            border-radius: 12px;
            font-size: 13px;
            font-weight: 500;
            color: #fff !important;
            backdrop-filter: blur(8px);
        }

        .jd-stat {
            border-radius: 16px !important;
            padding: 24px 20px !important;
            position: relative;
            overflow: hidden;
            border: none !important;
            transition: transform 0.25s ease, box-shadow 0.25s ease !important;
            min-height: 140px;
        }
        .jd-stat:hover {
            transform: translateY(-4px) !important;
            box-shadow: 0 12px 30px rgba(0,0,0,0.12) !important;
        }
        .jd-stat::after {
            content: '';
            position: absolute;
            top: -30px;
            right: -30px;
            width: 100px;
            height: 100px;
            border-radius: 50%;
            opacity: 0.15;
            pointer-events: none;
        }
        .jd-stat-blue {
            background: linear-gradient(135deg, #EFF6FF 0%, #DBEAFE 100%) !important;
            box-shadow: 0 2px 12px rgba(37,99,235,0.1) !important;
        }
        .jd-stat-blue::after { background: #2563EB; }
        .jd-stat-blue .jd-s-icon { background: #2563EB !important; color: #fff !important; }

        .jd-stat-green {
            background: linear-gradient(135deg, #F0FDF4 0%, #DCFCE7 100%) !important;
            box-shadow: 0 2px 12px rgba(22,163,74,0.1) !important;
        }
        .jd-stat-green::after { background: #16A34A; }
        .jd-stat-green .jd-s-icon { background: #16A34A !important; color: #fff !important; }

        .jd-stat-amber {
            background: linear-gradient(135deg, #FFFBEB 0%, #FEF3C7 100%) !important;
            box-shadow: 0 2px 12px rgba(217,119,6,0.1) !important;
        }
        .jd-stat-amber::after { background: #D97706; }
        .jd-stat-amber .jd-s-icon { background: #D97706 !important; color: #fff !important; }

        .jd-stat-purple {
            background: linear-gradient(135deg, #F5F3FF 0%, #EDE9FE 100%) !important;
            box-shadow: 0 2px 12px rgba(124,58,237,0.1) !important;
        }
        .jd-stat-purple::after { background: #7C3AED; }
        .jd-stat-purple .jd-s-icon { background: #7C3AED !important; color: #fff !important; }

        .jd-s-icon {
            width: 50px;
            height: 50px;
            border-radius: 14px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 22px;
            margin-bottom: 14px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        .jd-s-num {
            font-size: 30px !important;
            font-weight: 800 !important;
            margin-bottom: 4px !important;
            line-height: 1.1 !important;
            color: #1E293B !important;
        }
        .jd-s-label {
            font-size: 13px !important;
            color: #64748B !important;
            margin: 0 !important;
            font-weight: 500 !important;
        }
        .jd-s-sub {
            font-size: 12px;
            color: #94A3B8;
            font-weight: 600;
            margin-top: 6px;
            display: inline-block;
            background: rgba(0,0,0,0.04);
            padding: 2px 10px;
            border-radius: 20px;
        }

        .jd-ride-card {
            border-radius: 14px !important;
            padding: 20px 24px !important;
            border: none !important;
            transition: transform 0.25s ease, box-shadow 0.25s ease !important;
        }
        .jd-ride-card:hover {
            transform: translateY(-2px) !important;
            box-shadow: 0 8px 20px rgba(0,0,0,0.08) !important;
        }
        .jd-ride-green {
            background: #fff !important;
            box-shadow: 0 2px 8px rgba(0,0,0,0.04) !important;
            border-left: 4px solid #16A34A !important;
        }
        .jd-ride-orange {
            background: #fff !important;
            box-shadow: 0 2px 8px rgba(0,0,0,0.04) !important;
            border-left: 4px solid #F59E0B !important;
        }
        .jd-ride-icon {
            width: 44px;
            height: 44px;
            min-width: 44px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 18px;
        }
        .jd-ride-green .jd-ride-icon { background: #F0FDF4 !important; color: #16A34A !important; }
        .jd-ride-orange .jd-ride-icon { background: #FFFBEB !important; color: #F59E0B !important; }

        .jd-chart-card {
            border-radius: 16px !important;
            border: 1px solid rgba(0,0,0,0.06) !important;
            box-shadow: 0 2px 12px rgba(0,0,0,0.04) !important;
            overflow: hidden;
        }
        .jd-chart-card > .card-header {
            background: transparent !important;
            border-bottom: 1px solid rgba(0,0,0,0.06) !important;
            padding: 18px 22px !important;
        }
        .jd-chart-card > .card-body {
            padding: 20px 22px !important;
        }
        .jd-chart-card .card-header h5,
        .jd-chart-card .card-header h6 {
            font-weight: 600 !important;
        }

        [theme="dark"] .jd-banner {
            background: linear-gradient(135deg, #1E3A8A 0%, #1e2a5e 50%, #0f172a 100%) !important;
            box-shadow: 0 4px 20px rgba(0,0,0,0.3) !important;
        }
        [theme="dark"] .jd-stat {
            border: 1px solid rgba(255,255,255,0.06) !important;
        }
        [theme="dark"] .jd-stat-blue { background: linear-gradient(135deg, rgba(37,99,235,0.12) 0%, rgba(37,99,235,0.06) 100%) !important; }
        [theme="dark"] .jd-stat-green { background: linear-gradient(135deg, rgba(22,163,74,0.12) 0%, rgba(22,163,74,0.06) 100%) !important; }
        [theme="dark"] .jd-stat-amber { background: linear-gradient(135deg, rgba(217,119,6,0.12) 0%, rgba(217,119,6,0.06) 100%) !important; }
        [theme="dark"] .jd-stat-purple { background: linear-gradient(135deg, rgba(124,58,237,0.12) 0%, rgba(124,58,237,0.06) 100%) !important; }
        [theme="dark"] .jd-s-num { color: #E2E8F0 !important; }
        [theme="dark"] .jd-s-label { color: #94A3B8 !important; }
        [theme="dark"] .jd-ride-card { border-color: rgba(255,255,255,0.06) !important; }
        [theme="dark"] .jd-ride-green { background: var(--bs-card-bg, #1e293b) !important; border-left-color: #16A34A !important; }
        [theme="dark"] .jd-ride-orange { background: var(--bs-card-bg, #1e293b) !important; border-left-color: #F59E0B !important; }
        [theme="dark"] .jd-chart-card { border-color: rgba(255,255,255,0.06) !important; }
        [theme="dark"] .jd-chart-card > .card-header { border-bottom-color: rgba(255,255,255,0.06) !important; }
    </style>
@endpush

@section('content')
    <div class="main-content">
        <div class="container-fluid">
            <div class="jd-banner">
                <div class="jd-banner-inner">
                    <div class="d-flex align-items-center gap-3">
                        <div class="jd-avatar">
                            <i class="bi bi-speedometer2"></i>
                        </div>
                        <div>
                            <h3>{{ translate('welcome')}}, {{auth('web')->user()?->first_name}}!</h3>
                            <p>{{ translate('monitor_your')}}
                                <strong>{{ getSession('business_name') ?? 'JAGO' }}</strong> {{ translate('business_statistics')}}
                            </p>
                        </div>
                    </div>
                    <div class="jd-date-badge">
                        <i class="bi bi-calendar3"></i>
                        <span>{{ date('D, d M Y') }}</span>
                    </div>
                </div>
            </div>

            @can('dashboard')
                <div class="row g-3 mb-4">
                    <div class="col-xl-3 col-sm-6">
                        <div class="jd-stat jd-stat-blue">
                            <div class="jd-s-icon">
                                <i class="bi bi-people-fill"></i>
                            </div>
                            <h2 class="jd-s-num">{{abbreviateNumber($customers)}}</h2>
                            <p class="jd-s-label">{{ translate('Total Active Customers')}}</p>
                        </div>
                    </div>
                    <div class="col-xl-3 col-sm-6">
                        <div class="jd-stat jd-stat-green">
                            <div class="jd-s-icon">
                                <i class="bi bi-car-front-fill"></i>
                            </div>
                            <h2 class="jd-s-num">{{ abbreviateNumber($drivers) }}</h2>
                            <p class="jd-s-label">{{ translate('Total Active Drivers')}}</p>
                        </div>
                    </div>
                    <div class="col-xl-3 col-sm-6">
                        <div class="jd-stat jd-stat-amber">
                            <div class="jd-s-icon">
                                <i class="bi bi-currency-rupee"></i>
                            </div>
                            <h2 class="jd-s-num">{{abbreviateNumberWithSymbol($totalEarning) }}</h2>
                            <p class="jd-s-label">{{ translate('Total Earnings')}}</p>
                        </div>
                    </div>
                    <div class="col-xl-3 col-sm-6">
                        <div class="jd-stat jd-stat-purple">
                            <div class="jd-s-icon">
                                <i class="bi bi-box-seam-fill"></i>
                            </div>
                            <h2 class="jd-s-num">{{ abbreviateNumber($totalParcels) }}</h2>
                            <p class="jd-s-label">{{ translate('Total Parcel')}}</p>
                            <span class="jd-s-sub">{{ abbreviateNumberWithSymbol($totalParcelsEarning) }} {{translate('Earn')}}</span>
                        </div>
                    </div>
                </div>

                <div class="row g-3 mb-4">
                    <div class="col-sm-6">
                        <div class="jd-ride-card jd-ride-green">
                            <div class="d-flex align-items-center gap-3">
                                <div class="jd-ride-icon">
                                    <i class="bi bi-geo-alt-fill"></i>
                                </div>
                                <div>
                                    <h4 class="mb-1 fw-bold" style="font-size:20px;">{{ abbreviateNumberWithSymbol($totalRegularRideEarning) }}</h4>
                                    <small style="color:#64748B;font-size:13px;">{{ translate('Regular Ride')}} &middot; {{ abbreviateNumber($totalRegularRide) }} {{translate('trips')}}</small>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-sm-6">
                        <div class="jd-ride-card jd-ride-orange">
                            <div class="d-flex align-items-center gap-3">
                                <div class="jd-ride-icon">
                                    <i class="bi bi-clock-fill"></i>
                                </div>
                                <div>
                                    <h4 class="mb-1 fw-bold" style="font-size:20px;">{{ abbreviateNumberWithSymbol($totalScheduledRideEarning) }}</h4>
                                    <small style="color:#64748B;font-size:13px;">{{ translate('Schedule Ride')}} &middot; {{ abbreviateNumber($totalScheduledRide) }} {{translate('trips')}}</small>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row g-3 mb-4">
                    <div class="col-lg-6">
                        <div class="card jd-chart-card h-100">
                            <div class="card-header d-flex flex-wrap justify-content-between gap-10 align-items-center">
                                <div>
                                    <h6 class="mb-1 text-capitalize">{{ translate('zone-wise_trip_statistics')}}</h6>
                                    <p class="text-muted fs-12 mb-0">{{ translate('total')}} {{$zones->count()}} {{ translate('zones')}}</p>
                                </div>
                                <select class="js-select cmn_focus" id="zoneWiseRideDate">
                                    <option disabled>{{ translate('Select_Duration')}}</option>
                                    <option value="{{TODAY}}" {{ config('app.mode') != 'demo' ? "selected" : "" }}>{{ translate(TODAY)}}</option>
                                    <option value="{{PREVIOUS_DAY}}">{{ translate(PREVIOUS_DAY)}}</option>
                                    <option value="{{LAST_7_DAYS}}">{{translate(LAST_7_DAYS)}}</option>
                                    <option value="{{THIS_WEEK}}">{{translate(THIS_WEEK)}}</option>
                                    <option value="{{LAST_WEEK}}">{{translate(LAST_WEEK)}}</option>
                                    <option value="{{THIS_MONTH}}">{{translate(THIS_MONTH)}}</option>
                                    <option value="{{LAST_MONTH}}">{{translate(LAST_MONTH)}}</option>
                                    <option value="{{ALL_TIME}}" {{ config('app.mode') != 'demo' ?  "" : "selected" }}>{{translate(ALL_TIME)}}</option>
                                </select>
                            </div>
                            <div class="card-body">
                                <div class="load-all-data">
                                    <div id="zoneWiseTripStatistics"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-6">
                        <div class="card jd-chart-card h-100">
                            <div class="card-header d-flex flex-wrap justify-content-between gap-10 align-items-center">
                                <div>
                                    <h6 class="mb-1 text-capitalize">{{translate('admin_earning_statistics')}}</h6>
                                    <p class="text-muted fs-12 mb-0">{{translate('total')}} {{$zones->count()}} {{translate('zone')}}</p>
                                </div>
                                <div class="d-flex flex-wrap gap-2 align-items-center">
                                    <select class="js-select cmn_focus" id="rideZone">
                                        <option disabled>{{translate('Select_Area')}}</option>
                                        <option selected value="all">{{translate('all')}}</option>
                                        @forelse($zones as $zone)
                                            <option value="{{$zone->id}}">{{$zone->name}}</option>
                                        @empty
                                        @endforelse
                                    </select>
                                    <select class="js-select cmn_focus" id="rideDate">
                                        <option disabled>{{translate('Select_Duration')}}</option>
                                        <option value="{{ALL_TIME}}" {{ config('app.mode') != 'demo' ? "" : "selected" }}>{{translate(ALL_TIME)}}</option>
                                        <option value="{{TODAY}}" {{ config('app.mode') != 'demo' ? "selected" : "" }}>{{translate(TODAY)}}</option>
                                        <option value="{{PREVIOUS_DAY}}">{{translate(PREVIOUS_DAY)}}</option>
                                        <option value="{{LAST_7_DAYS}}">{{translate(LAST_7_DAYS)}}</option>
                                        <option value="{{THIS_WEEK}}">{{translate(THIS_WEEK)}}</option>
                                        <option value="{{LAST_WEEK}}">{{translate(LAST_WEEK)}}</option>
                                        <option value="{{THIS_MONTH}}">{{translate(THIS_MONTH)}}</option>
                                        <option value="{{LAST_MONTH}}">{{translate(LAST_MONTH)}}</option>
                                        <option value="{{THIS_YEAR}}">{{translate(THIS_YEAR)}}</option>
                                    </select>
                                </div>
                            </div>
                            <div class="card-body hide-2nd-line-of-chart" id="updating_line_chart">
                                <div id="apex_line-chart"></div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row g-3 mb-4">
                    <div class="col-lg-8">
                        <div class="card jd-chart-card h-100">
                            <div class="card-header d-flex flex-wrap justify-content-between align-items-center gap-3">
                                <div class="d-flex align-items-center gap-2">
                                    <h5 class="text-capitalize mb-0">{{translate('leader_board')}}</h5>
                                    <span class="badge bg-primary rounded-pill px-3">{{translate('driver')}}</span>
                                </div>
                                <ul class="nav nav--tabs p-1 rounded bg-white" role="tablist">
                                    <li class="nav-item" role="presentation">
                                        <button value="{{TODAY}}"
                                                class="nav-link text-capitalize leader-board-driver {{ config('app.mode') != 'demo' ? "active" : "" }}"
                                                data-bs-toggle="tab"
                                                data-bs-target="#today-tab-pane" aria-selected="{{ config('app.mode') != 'demo' ? "true" : "false" }}"
                                                role="tab">{{translate(TODAY)}}</button>
                                    </li>
                                    <li class="nav-item" role="presentation">
                                        <button value="{{THIS_WEEK}}"
                                                class="nav-link text-capitalize leader-board-driver"
                                                data-bs-toggle="tab"
                                                data-bs-target="#week-tab-pane" aria-selected="false"
                                                role="tab" tabindex="-1">{{translate(THIS_WEEK)}}</button>
                                    </li>
                                    <li class="nav-item" role="presentation">
                                        <button value="{{THIS_MONTH}}"
                                                class="nav-link text-capitalize leader-board-driver"
                                                data-bs-toggle="tab"
                                                data-bs-target="#month-tab-pane" aria-selected="false"
                                                role="tab" tabindex="-1">{{translate(THIS_MONTH)}}</button>
                                    </li>
                                    <li class="nav-item" role="presentation">
                                        <button value="{{ALL_TIME}}"
                                                class="nav-link text-capitalize leader-board-driver {{ config('app.mode') != 'demo' ? "" : "active" }}"
                                                data-bs-toggle="tab"
                                                data-bs-target="#all-time-tab-pane" aria-selected="{{ config('app.mode') != 'demo' ? "false" : "true" }}"
                                                role="tab" tabindex="-1">{{translate(ALL_TIME)}}</button>
                                    </li>
                                </ul>
                            </div>
                            <div class="card-body">
                                <div class="tab-content">
                                    <div id="leader-board-driver"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-4">
                        <div class="card jd-chart-card recent-transactions max-h-460px">
                            <div class="card-header">
                                <h4 class="mb-2">{{translate('recent_transactions')}}</h4>
                                <div class="d-flex justify-content-between">
                                    <div class="d-flex align-items-center gap-3">
                                        <i class="bi bi-arrow-up text-primary"></i>
                                        <p class="opacity-75">{{ translate('last') }} {{$transactions->count()}} {{ translate('transactions_this_month') }}</p>
                                    </div>
                                    <a href="{{route('admin.transaction.index')}}"
                                       class="btn-link text-capitalize">{{translate('view_all')}}</a>
                                </div>
                            </div>
                            <div class="card-body overflow-y-auto">
                                <div class="events">
                                    @forelse ($transactions as $transaction)
                                        <div class="event">
                                            <div class="knob"></div>
                                            <div class="title">
                                                @if($transaction->debit>0)
                                                    <h5>{{ getCurrencyFormat($transaction->debit ?? 0) }} {{translate("Debited from ")}}
                                                        {{translate($transaction->account)}}</h5>
                                                @else
                                                    <h5>{{ getCurrencyFormat($transaction->credit ?? 0) }} {{translate("Credited to ")}}
                                                        {{translate($transaction->account)}}</h5>
                                                @endif
                                            </div>
                                            @php($time_format = getSession('time_format'))
                                            <div class="description d-flex gap-3">
                                                @if($transaction?->readable_id)
                                                    <span>#{{ $transaction?->readable_id ?? '' }}</span>
                                                @endif
                                                <span>{{date(DASHBOARD_DATE_FORMAT,strtotime($transaction->created_at))}}</span>
                                            </div>
                                        </div>
                                    @empty
                                    @endforelse
                                    <div class="line"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row g-3">
                    <div class="col-lg-8">
                        <div class="card jd-chart-card h-100">
                            <div class="card-header d-flex flex-wrap justify-content-between align-items-center gap-3">
                                <div class="d-flex align-items-center gap-2">
                                    <h5 class="text-capitalize mb-0">{{translate('leader_board')}}</h5>
                                    <span class="badge bg-primary rounded-pill px-3">{{translate('customer')}}</span>
                                </div>
                                <ul class="nav nav--tabs p-1 rounded bg-white" role="tablist">
                                    <li class="nav-item" role="presentation">
                                        <button value="{{TODAY}}"
                                                class="nav-link text-capitalize leader-board-customer {{ config('app.mode') != 'demo' ? "active" : "" }}"
                                                data-bs-toggle="tab"
                                                data-bs-target="#today-tab-pane" aria-selected="{{ config('app.mode') != 'demo' ? "true" : "false" }}"
                                                role="tab">{{translate(TODAY)}}</button>
                                    </li>
                                    <li class="nav-item" role="presentation">
                                        <button value="{{THIS_WEEK}}"
                                                class="nav-link text-capitalize leader-board-customer"
                                                data-bs-toggle="tab"
                                                data-bs-target="#today-tab-pane" aria-selected="false"
                                                role="tab">{{translate(THIS_WEEK)}}</button>
                                    </li>
                                    <li class="nav-item" role="presentation">
                                        <button value="{{THIS_MONTH}}"
                                                class="nav-link text-capitalize leader-board-customer"
                                                data-bs-toggle="tab"
                                                data-bs-target="#today-tab-pane" aria-selected="false"
                                                role="tab">{{translate(THIS_MONTH)}}</button>
                                    </li>
                                    <li class="nav-item" role="presentation">
                                        <button value="{{ALL_TIME}}"
                                                class="nav-link text-capitalize leader-board-customer {{ config('app.mode') != 'demo' ? "" : "active" }}"
                                                data-bs-toggle="tab"
                                                data-bs-target="#today-tab-pane" aria-selected="{{ config('app.mode') != 'demo' ? "false" : "true" }}"
                                                role="tab">{{translate(ALL_TIME)}}</button>
                                    </li>
                                </ul>
                            </div>
                            <div class="card-body">
                                <div class="tab-content">
                                    <div id="leader-board-customer"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-4">
                        <div class="card jd-chart-card recent-activities max-h-460px">
                            <div class="card-header d-flex justify-content-between gap-10">
                                <div class="d-flex flex-column gap-1">
                                    <h5 class="text-capitalize">{{translate('recent_trips_activity')}}</h5>
                                    <p class="text-capitalize">{{translate('all_activities')}}</p>
                                </div>
                                <a href="{{route('admin.trip.index', ['all'])}}"
                                   class="btn-link text-capitalize">{{translate('view_all')}}</a>
                            </div>
                            <div class="card-body overflow-y-auto" id="recent_trips_activity">
                            </div>
                        </div>
                    </div>
                </div>
            @endcan
        </div>
    </div>
@endsection

@push('script')
    <!-- Apex Chart -->
    <script src="{{dynamicAsset('public/assets/admin-module/plugins/apex/apexcharts.min.js')}}"></script>
    <script src="{{dynamicAsset('public/assets/admin-module/js/admin-module/dashboard.js')}}"></script>
    <!-- Google Map -->

    <script>
        "use strict";

        $(".leader-board-customer").on('click', function () {
            let data = $(this).val();
            loadPartialView('{{route('admin.leader-board-customer')}}', '#leader-board-customer', data)
        })
        $(".leader-board-driver").on('click', function () {
            let data = $(this).val();
            loadPartialView('{{route('admin.leader-board-driver')}}', '#leader-board-driver', data)
        })


        $("#rideZone,#rideDate").on('change', function () {
            let date = $("#rideDate").val();
            let zone = $("#rideZone").val();
            adminEarningStatistics(date, zone)
        })

        function adminEarningStatistics(date, zone = null) {
            $.get({
                url: '{{route('admin.earning-statistics')}}',
                dataType: 'json',
                data: {date: date, zone: zone},
                beforeSend: function () {
                    $('#resource-loader').show();
                },
                success: function (response) {
                    let hours = response.label;
                    // Remove double quotes from each string value
                    hours = hours.map(function (hour) {
                        return hour.replace(/"/g, '');
                    });
                    document.getElementById('apex_line-chart').remove();
                    let graph = document.createElement('div');
                    graph.setAttribute("id", "apex_line-chart");
                    document.getElementById("updating_line_chart").appendChild(graph);
                    let options = {
                        series: [
                            {
                                name: '{{translate("Admin Commission")}} ($)',
                                data: [0].concat(Object.values(response.totalAdminCommission))
                            },
                            {
                                name: '{{translate("Ride")}}',
                                data: [0].concat(Object.values(response.totalRideCount))
                            },
                            {
                                name: '{{translate("Parcel")}}',
                                data: [0].concat(Object.values(response.totalParcelCount))
                            },

                        ],
                        chart: {
                            height: 366,
                            type: 'line',
                            dropShadow: {
                                enabled: true,
                                color: '#000',
                                top: 18,
                                left: 0,
                                blur: 10,
                                opacity: 0.1
                            },
                            toolbar: {
                                show: false
                            },
                        },
                        colors: ['#14B19E'],
                        dataLabels: {
                            enabled: false,
                        },
                        stroke: {
                            curve: 'smooth',
                            width: 2,
                        },
                        grid: {
                            yaxis: {
                                lines: {
                                    show: true
                                }
                            },
                            borderColor: '#ddd',
                        },
                        markers: {
                            size: 1,
                            strokeColors: [ '#14B19E'],
                            strokeWidth: 1,
                            fillOpacity: 0,
                            hover: {
                                sizeOffset: 2
                            }
                        },
                        theme: {
                            mode: 'light',
                        },
                        xaxis: {
                            categories: ['00'].concat(hours),
                            labels: {
                                offsetX: 0,
                            },
                        },
                        legend: {
                            show: false,
                            position: 'bottom',
                            horizontalAlign: 'left',
                            floating: false,
                            offsetY: -10,
                            itemMargin: {
                                vertical: 10
                            },
                        },
                        yaxis: {
                            tickAmount: 10,
                            labels: {
                                offsetX: 0,
                            },
                        }
                    };

                    if (localStorage.getItem('dir') === 'rtl') {
                        options.yaxis.labels.offsetX = -20;
                    }

                    let chart = new ApexCharts(document.querySelector("#apex_line-chart"), options);
                    chart.render();
                },
                complete: function () {
                    $('#resource-loader').hide();
                },
                error: function (xhr, status, error) {
                    let err = JSON.parse(xhr.responseText);
                    // alert(err.Message);
                    $('#resource-loader').hide();
                    toastr.error('{{translate('failed_to_load_data')}}')
                },
            });

        }

        $("#zoneWiseRideDate").on('change', function () {
            let date = $("#zoneWiseRideDate").val()
            zoneWiseTripStatistics(date)
        })

        function zoneWiseTripStatistics(date) {
            $.get({
                url: '{{route('admin.zone-wise-statistics')}}',
                dataType: 'json',
                data: {date: date},
                beforeSend: function () {
                    $('#resource-loader').show();
                },
                success: function (response) {
                    $('#zoneWiseTripStatistics').empty().html(response)
                },
                complete: function () {
                    $('#resource-loader').hide();
                },
                error: function (xhr, status, error) {
                    $('#resource-loader').hide();
                    toastr.error('{{translate('failed_to_load_data')}}')
                },
            });

        }

        // partial view
        loadPartialView('{{route('admin.recent-trip-activity')}}', '#recent_trips_activity', null);
        loadPartialView('{{route('admin.leader-board-driver')}}', '#leader-board-driver', '{{ config('app.mode') != 'demo' ? "today" : "all_time" }}');
        loadPartialView('{{route('admin.leader-board-customer')}}', '#leader-board-customer', '{{ config('app.mode') != 'demo' ? "today" : "all_time" }}');
        zoneWiseTripStatistics(document.getElementById('zoneWiseRideDate').value);
        adminEarningStatistics('{{ config('app.mode') != 'demo' ? "today" : "all_time" }}', 'all')

    </script>
    @include('adminmodule::partials.dashboard.map')

@endpush
