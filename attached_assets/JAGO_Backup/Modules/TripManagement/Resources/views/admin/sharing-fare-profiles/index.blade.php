@extends('adminmodule::layouts.master')

@section('title', translate('Sharing Fare Profiles'))

@section('content')
    <div class="main-content">
        <div class="container-fluid">
            <div class="d-flex flex-wrap justify-content-between align-items-center mb-4">
                <h4 class="text-capitalize">{{ translate('sharing_fare_profiles') }}</h4>
                <a href="{{ route('admin.trip.sharing-fare-profiles.create') }}" class="btn btn-primary">
                    <i class="bi bi-plus-circle"></i> {{ translate('add_new_profile') }}
                </a>
            </div>

            <div class="card">
                <div class="card-body">
                    <div class="table-top d-flex flex-wrap gap-10 justify-content-between mb-4">
                        <form action="{{ route('admin.trip.sharing-fare-profiles.index') }}" method="GET" class="d-flex gap-2 align-items-center flex-wrap">
                            <select name="sharing_type" class="form-select" style="max-width: 160px;" onchange="this.form.submit()">
                                <option value="all">{{ translate('all_types') }}</option>
                                <option value="city" {{ ($sharingType ?? '') == 'city' ? 'selected' : '' }}>{{ translate('city') }}</option>
                                <option value="outstation" {{ ($sharingType ?? '') == 'outstation' ? 'selected' : '' }}>{{ translate('outstation') }}</option>
                            </select>
                            <select name="zone_id" class="form-select" style="max-width: 200px;" onchange="this.form.submit()">
                                <option value="all">{{ translate('all_zones') }}</option>
                                @foreach($zones as $zone)
                                    <option value="{{ $zone->id }}" {{ ($zoneId ?? '') == $zone->id ? 'selected' : '' }}>{{ $zone->name }}</option>
                                @endforeach
                            </select>
                        </form>
                    </div>

                    <div class="table-responsive">
                        <table class="table table-borderless align-middle table-hover">
                            <thead class="table-light">
                                <tr>
                                    <th>{{ translate('SL') }}</th>
                                    <th>{{ translate('zone') }}</th>
                                    <th>{{ translate('vehicle_category') }}</th>
                                    <th>{{ translate('sharing_type') }}</th>
                                    <th>{{ translate('base_fare_seat') }}</th>
                                    <th>{{ translate('per_km_fare_seat') }}</th>
                                    <th>{{ translate('discount') }}%</th>
                                    <th>{{ translate('commission') }}%</th>
                                    <th>{{ translate('gst') }}%</th>
                                    <th>{{ translate('min_fare') }}</th>
                                    <th>{{ translate('status') }}</th>
                                    <th>{{ translate('action') }}</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($profiles as $key => $profile)
                                    <tr>
                                        <td>{{ $profiles->firstItem() + $key }}</td>
                                        <td>{{ $profile->zone->name ?? '-' }}</td>
                                        <td>{{ $profile->vehicleCategory->name ?? '-' }}</td>
                                        <td>
                                            <span class="badge bg-{{ $profile->sharing_type === 'city' ? 'info' : 'primary' }}">{{ ucfirst($profile->sharing_type) }}</span>
                                        </td>
                                        <td>₹{{ number_format($profile->base_fare_per_seat, 2) }}</td>
                                        <td>₹{{ number_format($profile->per_km_fare_per_seat, 2) }}</td>
                                        <td>{{ $profile->discount_percent }}%</td>
                                        <td>{{ $profile->commission_percent }}%</td>
                                        <td>{{ $profile->gst_percent }}%</td>
                                        <td>₹{{ number_format($profile->min_fare_per_seat, 2) }}</td>
                                        <td>
                                            @if($profile->is_active)
                                                <span class="badge bg-success">{{ translate('active') }}</span>
                                            @else
                                                <span class="badge bg-danger">{{ translate('inactive') }}</span>
                                            @endif
                                        </td>
                                        <td>
                                            <div class="d-flex gap-1">
                                                <a href="{{ route('admin.trip.sharing-fare-profiles.edit', $profile->id) }}" class="btn btn-sm btn-outline-primary">
                                                    <i class="bi bi-pencil"></i>
                                                </a>
                                                <form action="{{ route('admin.trip.sharing-fare-profiles.toggle-status', $profile->id) }}" method="POST">
                                                    @csrf
                                                    <button type="submit" class="btn btn-sm btn-outline-{{ $profile->is_active ? 'warning' : 'success' }}" title="{{ $profile->is_active ? translate('deactivate') : translate('activate') }}">
                                                        <i class="bi bi-{{ $profile->is_active ? 'pause-circle' : 'play-circle' }}"></i>
                                                    </button>
                                                </form>
                                                <form action="{{ route('admin.trip.sharing-fare-profiles.destroy', $profile->id) }}" method="POST" onsubmit="return confirm('{{ translate('are_you_sure') }}')">
                                                    @csrf
                                                    @method('DELETE')
                                                    <button type="submit" class="btn btn-sm btn-outline-danger">
                                                        <i class="bi bi-trash"></i>
                                                    </button>
                                                </form>
                                            </div>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="12" class="text-center text-muted py-4">{{ translate('no_sharing_fare_profiles_found') }}</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>

                    <div class="d-flex justify-content-end mt-3">
                        {{ $profiles->withQueryString()->links() }}
                    </div>
                </div>
            </div>
        </div>
    </div>
@endsection
