@extends('adminmodule::layouts.master')

@section('title', translate('Shared Trip Details'))

@section('content')
    <div class="main-content">
        <div class="container-fluid">
            <div class="d-flex align-items-center justify-content-between mb-4">
                <h4 class="text-capitalize mb-0">{{ translate('shared_trip_details') }}</h4>
                <a href="{{ route('admin.trip.car-sharing.index') }}" class="btn btn-outline-primary btn-sm">
                    <i class="bi bi-arrow-left"></i> {{ translate('back_to_list') }}
                </a>
            </div>

            <div class="row mb-4">
                <div class="col-lg-6 mb-3">
                    <div class="card h-100">
                        <div class="card-header bg-primary text-white">
                            <h6 class="mb-0">{{ translate('trip_information') }}</h6>
                        </div>
                        <div class="card-body">
                            <table class="table table-borderless mb-0">
                                <tr>
                                    <td class="text-muted" style="width:40%">{{ translate('group_id') }}</td>
                                    <td><span class="badge bg-light text-dark" style="font-family:monospace;font-size:14px">{{ $trip->shared_group_id }}</span></td>
                                </tr>
                                <tr>
                                    <td class="text-muted">{{ translate('trip_id') }}</td>
                                    <td>{{ $trip->ref_id ?? $trip->id }}</td>
                                </tr>
                                <tr>
                                    <td class="text-muted">{{ translate('status') }}</td>
                                    <td>
                                        @php
                                            $statusColors = ['pending'=>'warning','accepted'=>'info','ongoing'=>'success','completed'=>'secondary','cancelled'=>'danger'];
                                        @endphp
                                        <span class="badge bg-{{ $statusColors[$trip->current_status] ?? 'dark' }} px-3 py-2">{{ ucfirst($trip->current_status) }}</span>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="text-muted">{{ translate('vehicle_category') }}</td>
                                    <td>{{ $trip->vehicleCategory->name ?? '-' }}</td>
                                </tr>
                                <tr>
                                    <td class="text-muted">{{ translate('created') }}</td>
                                    <td>{{ $trip->created_at?->format('d M Y, h:i A') }}</td>
                                </tr>
                            </table>
                        </div>
                    </div>
                </div>

                <div class="col-lg-6 mb-3">
                    <div class="row h-100">
                        <div class="col-sm-6 mb-3">
                            <div class="card h-100">
                                <div class="card-header bg-dark text-white">
                                    <h6 class="mb-0"><i class="bi bi-person-badge"></i> {{ translate('driver') }}</h6>
                                </div>
                                <div class="card-body">
                                    @if($trip->driver)
                                        <strong>{{ ($trip->driver->first_name ?? '') . ' ' . ($trip->driver->last_name ?? '') }}</strong><br>
                                        <small class="text-muted"><i class="bi bi-telephone"></i> {{ $trip->driver->phone ?? '-' }}</small><br>
                                        <small class="text-muted"><i class="bi bi-envelope"></i> {{ $trip->driver->email ?? '-' }}</small>
                                    @else
                                        <p class="text-muted mb-0">{{ translate('no_driver_assigned') }}</p>
                                    @endif
                                </div>
                            </div>
                        </div>
                        <div class="col-sm-6 mb-3">
                            <div class="card h-100">
                                <div class="card-header bg-info text-white">
                                    <h6 class="mb-0"><i class="bi bi-person"></i> {{ translate('trip_creator') }}</h6>
                                </div>
                                <div class="card-body">
                                    @if($trip->customer)
                                        <strong>{{ ($trip->customer->first_name ?? '') . ' ' . ($trip->customer->last_name ?? '') }}</strong><br>
                                        <small class="text-muted"><i class="bi bi-telephone"></i> {{ $trip->customer->phone ?? '-' }}</small><br>
                                        <small class="text-muted"><i class="bi bi-envelope"></i> {{ $trip->customer->email ?? '-' }}</small>
                                    @else
                                        <p class="text-muted mb-0">-</p>
                                    @endif
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row mb-4">
                <div class="col-lg-3 col-sm-6 mb-3">
                    <div class="card text-center border-primary">
                        <div class="card-body">
                            <h2 class="text-primary">{{ $stats['total_passengers'] }}</h2>
                            <p class="mb-0 text-muted">{{ translate('total_passengers') }}</p>
                        </div>
                    </div>
                </div>
                <div class="col-lg-3 col-sm-6 mb-3">
                    <div class="card text-center border-success">
                        <div class="card-body">
                            <h2 class="text-success">{{ $stats['active'] }}</h2>
                            <p class="mb-0 text-muted">{{ translate('active_passengers') }}</p>
                        </div>
                    </div>
                </div>
                <div class="col-lg-3 col-sm-6 mb-3">
                    <div class="card text-center border-secondary">
                        <div class="card-body">
                            <h2 class="text-secondary">{{ $stats['dropped_off'] }}</h2>
                            <p class="mb-0 text-muted">{{ translate('dropped_off') }}</p>
                        </div>
                    </div>
                </div>
                <div class="col-lg-3 col-sm-6 mb-3">
                    <div class="card text-center border-warning">
                        <div class="card-body">
                            <h2 class="text-warning">{{ $stats['total_seats'] }}</h2>
                            <p class="mb-0 text-muted">{{ translate('total_seats_booked') }}</p>
                        </div>
                    </div>
                </div>
            </div>

            <div class="card mb-4">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h5 class="mb-0">{{ translate('passengers') }} ({{ $stats['total_passengers'] }})</h5>
                    <span class="text-primary fw-bold">{{ translate('total_fare') }}: ₹{{ number_format($stats['total_fare'], 2) }}</span>
                </div>
                <div class="card-body">
                    <div class="table-responsive">
                        <table class="table table-borderless align-middle table-hover">
                            <thead class="table-light">
                                <tr>
                                    <th>{{ translate('SL') }}</th>
                                    <th>{{ translate('passenger') }}</th>
                                    <th>{{ translate('phone') }}</th>
                                    <th>{{ translate('seats') }}</th>
                                    <th>{{ translate('pickup') }}</th>
                                    <th>{{ translate('drop') }}</th>
                                    <th>{{ translate('distance') }}</th>
                                    <th>{{ translate('fare') }}</th>
                                    <th>{{ translate('otp') }}</th>
                                    <th>{{ translate('status') }}</th>
                                    <th>{{ translate('picked_up') }}</th>
                                    <th>{{ translate('dropped_off') }}</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($passengers as $key => $p)
                                    <tr>
                                        <td>{{ $key + 1 }}</td>
                                        <td>
                                            <strong>{{ ($p->user->first_name ?? '') . ' ' . ($p->user->last_name ?? '') }}</strong>
                                        </td>
                                        <td>{{ $p->user->phone ?? '-' }}</td>
                                        <td><span class="badge bg-primary">{{ $p->seats_booked }}</span></td>
                                        <td>
                                            <small>{{ \Illuminate\Support\Str::limit($p->pickup_address, 30) }}</small>
                                        </td>
                                        <td>
                                            <small>{{ \Illuminate\Support\Str::limit($p->drop_address, 30) }}</small>
                                        </td>
                                        <td>{{ number_format($p->distance_km, 1) }} km</td>
                                        <td><strong>₹{{ number_format($p->fare_amount, 2) }}</strong></td>
                                        <td>
                                            @if($p->otp_verified)
                                                <span class="badge bg-success"><i class="bi bi-check-circle"></i> {{ translate('verified') }}</span>
                                            @else
                                                <span class="badge bg-warning">{{ $p->otp }}</span>
                                            @endif
                                        </td>
                                        <td>
                                            @php
                                                $pStatusColors = ['pending'=>'warning','picked_up'=>'success','dropped_off'=>'secondary'];
                                            @endphp
                                            <span class="badge bg-{{ $pStatusColors[$p->status] ?? 'dark' }}">{{ ucfirst(str_replace('_', ' ', $p->status)) }}</span>
                                        </td>
                                        <td>{{ $p->picked_up_at ? \Carbon\Carbon::parse($p->picked_up_at)->format('h:i A') : '-' }}</td>
                                        <td>{{ $p->dropped_off_at ? \Carbon\Carbon::parse($p->dropped_off_at)->format('h:i A') : '-' }}</td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="12" class="text-center text-muted py-4">{{ translate('no_passengers_found') }}</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
@endsection
