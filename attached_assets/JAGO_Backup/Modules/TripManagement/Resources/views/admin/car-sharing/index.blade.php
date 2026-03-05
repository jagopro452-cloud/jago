@extends('adminmodule::layouts.master')

@section('title', translate('Car Sharing Trips'))

@section('content')
    <div class="main-content">
        <div class="container-fluid">
            <h4 class="text-capitalize mb-4">{{ translate('car_sharing_management') }}</h4>

            <div class="row mb-4">
                <div class="col-lg-3 col-sm-6 mb-3">
                    <div class="card bg-primary text-white">
                        <div class="card-body text-center">
                            <h3>{{ $trips->total() }}</h3>
                            <p class="mb-0">{{ translate('total_shared_trips') }}</p>
                        </div>
                    </div>
                </div>
                <div class="col-lg-3 col-sm-6 mb-3">
                    <div class="card bg-success text-white">
                        <div class="card-body text-center">
                            <h3>{{ $trips->where('current_status', 'ongoing')->count() }}</h3>
                            <p class="mb-0">{{ translate('ongoing') }}</p>
                        </div>
                    </div>
                </div>
                <div class="col-lg-3 col-sm-6 mb-3">
                    <div class="card bg-info text-white">
                        <div class="card-body text-center">
                            <h3>{{ $trips->where('current_status', 'pending')->count() }}</h3>
                            <p class="mb-0">{{ translate('pending') }}</p>
                        </div>
                    </div>
                </div>
                <div class="col-lg-3 col-sm-6 mb-3">
                    <div class="card bg-secondary text-white">
                        <div class="card-body text-center">
                            <h3>{{ $trips->where('current_status', 'completed')->count() }}</h3>
                            <p class="mb-0">{{ translate('completed') }}</p>
                        </div>
                    </div>
                </div>
            </div>

            <div class="card">
                <div class="card-body">
                    <div class="table-top d-flex flex-wrap gap-10 justify-content-between mb-4">
                        <form action="{{ route('admin.trip.car-sharing.index') }}" method="GET" class="d-flex gap-2 align-items-center">
                            <div class="input-group" style="max-width: 300px;">
                                <input type="text" name="search" class="form-control" placeholder="{{ translate('search_by_group_id') }}" value="{{ $search ?? '' }}">
                                <button type="submit" class="btn btn-primary"><i class="bi bi-search"></i></button>
                            </div>
                            <select name="status" class="form-select" style="max-width: 150px;" onchange="this.form.submit()">
                                <option value="all">{{ translate('all_status') }}</option>
                                <option value="pending" {{ ($status ?? '') == 'pending' ? 'selected' : '' }}>{{ translate('pending') }}</option>
                                <option value="accepted" {{ ($status ?? '') == 'accepted' ? 'selected' : '' }}>{{ translate('accepted') }}</option>
                                <option value="ongoing" {{ ($status ?? '') == 'ongoing' ? 'selected' : '' }}>{{ translate('ongoing') }}</option>
                                <option value="completed" {{ ($status ?? '') == 'completed' ? 'selected' : '' }}>{{ translate('completed') }}</option>
                                <option value="cancelled" {{ ($status ?? '') == 'cancelled' ? 'selected' : '' }}>{{ translate('cancelled') }}</option>
                            </select>
                        </form>
                    </div>

                    <div class="table-responsive">
                        <table class="table table-borderless align-middle table-hover">
                            <thead class="table-light">
                                <tr>
                                    <th>{{ translate('SL') }}</th>
                                    <th>{{ translate('group_id') }}</th>
                                    <th>{{ translate('driver') }}</th>
                                    <th>{{ translate('customer') }}</th>
                                    <th>{{ translate('vehicle') }}</th>
                                    <th>{{ translate('passengers') }}</th>
                                    <th>{{ translate('active') }}</th>
                                    <th>{{ translate('status') }}</th>
                                    <th>{{ translate('date') }}</th>
                                    <th>{{ translate('action') }}</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($trips as $key => $trip)
                                    <tr>
                                        <td>{{ $trips->firstItem() + $key }}</td>
                                        <td>
                                            <span class="badge bg-light text-dark" style="font-family: monospace;">{{ $trip->shared_group_id }}</span>
                                        </td>
                                        <td>
                                            @if($trip->driver)
                                                {{ ($trip->driver->first_name ?? '') . ' ' . ($trip->driver->last_name ?? '') }}
                                                <br><small class="text-muted">{{ $trip->driver->phone ?? '' }}</small>
                                            @else
                                                <span class="text-muted">{{ translate('no_driver') }}</span>
                                            @endif
                                        </td>
                                        <td>
                                            @if($trip->customer)
                                                {{ ($trip->customer->first_name ?? '') . ' ' . ($trip->customer->last_name ?? '') }}
                                            @else
                                                <span class="text-muted">-</span>
                                            @endif
                                        </td>
                                        <td>{{ $trip->vehicleCategory->name ?? '-' }}</td>
                                        <td><span class="badge bg-primary">{{ $trip->total_passengers ?? 0 }}</span></td>
                                        <td><span class="badge bg-success">{{ $trip->active_passengers ?? 0 }}</span></td>
                                        <td>
                                            @php
                                                $statusColors = [
                                                    'pending' => 'warning',
                                                    'accepted' => 'info',
                                                    'ongoing' => 'success',
                                                    'completed' => 'secondary',
                                                    'cancelled' => 'danger',
                                                ];
                                                $color = $statusColors[$trip->current_status] ?? 'dark';
                                            @endphp
                                            <span class="badge bg-{{ $color }}">{{ ucfirst($trip->current_status) }}</span>
                                        </td>
                                        <td>{{ $trip->created_at?->format('d M Y, h:i A') }}</td>
                                        <td>
                                            <a href="{{ route('admin.trip.car-sharing.show', $trip->id) }}" class="btn btn-sm btn-outline-primary">
                                                <i class="bi bi-eye"></i> {{ translate('view') }}
                                            </a>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="10" class="text-center text-muted py-4">{{ translate('no_shared_trips_found') }}</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>

                    <div class="d-flex justify-content-end mt-3">
                        {{ $trips->withQueryString()->links() }}
                    </div>
                </div>
            </div>
        </div>
    </div>
@endsection
