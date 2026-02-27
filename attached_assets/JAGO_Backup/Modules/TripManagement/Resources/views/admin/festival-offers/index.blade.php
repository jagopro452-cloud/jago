@extends('adminmodule::layouts.master')

@section('title', translate('Festival Offers'))

@section('content')
    <div class="main-content">
        <div class="container-fluid">
            <div class="d-flex flex-wrap justify-content-between align-items-center mb-4">
                <h4 class="text-capitalize">{{ translate('festival_offers') }}</h4>
                <a href="{{ route('admin.trip.festival-offers.create') }}" class="btn btn-primary">
                    <i class="bi bi-plus-circle"></i> {{ translate('add_new_offer') }}
                </a>
            </div>

            <div class="card">
                <div class="card-body">
                    <div class="table-top d-flex flex-wrap gap-10 justify-content-between mb-4">
                        <form action="{{ route('admin.trip.festival-offers.index') }}" method="GET" class="d-flex gap-2 align-items-center flex-wrap">
                            <select name="sharing_type" class="form-select" style="max-width: 160px;" onchange="this.form.submit()">
                                <option value="all">{{ translate('all_types') }}</option>
                                <option value="city" {{ ($sharingType ?? '') == 'city' ? 'selected' : '' }}>{{ translate('city') }}</option>
                                <option value="outstation" {{ ($sharingType ?? '') == 'outstation' ? 'selected' : '' }}>{{ translate('outstation') }}</option>
                            </select>
                            <select name="status" class="form-select" style="max-width: 150px;" onchange="this.form.submit()">
                                <option value="all">{{ translate('all_status') }}</option>
                                <option value="active" {{ ($status ?? '') == 'active' ? 'selected' : '' }}>{{ translate('active') }}</option>
                                <option value="inactive" {{ ($status ?? '') == 'inactive' ? 'selected' : '' }}>{{ translate('inactive') }}</option>
                                <option value="expired" {{ ($status ?? '') == 'expired' ? 'selected' : '' }}>{{ translate('expired') }}</option>
                            </select>
                            <div class="input-group" style="max-width: 300px;">
                                <input type="text" name="search" class="form-control" placeholder="{{ translate('search_by_name') }}" value="{{ $search ?? '' }}">
                                <button type="submit" class="btn btn-primary"><i class="bi bi-search"></i></button>
                            </div>
                        </form>
                    </div>

                    <div class="table-responsive">
                        <table class="table table-borderless align-middle table-hover">
                            <thead class="table-light">
                                <tr>
                                    <th>{{ translate('SL') }}</th>
                                    <th>{{ translate('name') }}</th>
                                    <th>{{ translate('type') }}</th>
                                    <th>{{ translate('offer_type') }}</th>
                                    <th>{{ translate('value') }}</th>
                                    <th>{{ translate('period') }}</th>
                                    <th>{{ translate('uses') }}</th>
                                    <th>{{ translate('status') }}</th>
                                    <th>{{ translate('action') }}</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($offers as $key => $offer)
                                    <tr>
                                        <td>{{ $offers->firstItem() + $key }}</td>
                                        <td>{{ $offer->name }}</td>
                                        <td>
                                            @if($offer->sharing_type === 'city')
                                                <span class="badge bg-info">{{ translate('city') }}</span>
                                            @elseif($offer->sharing_type === 'outstation')
                                                <span class="badge bg-primary">{{ translate('outstation') }}</span>
                                            @else
                                                <span class="badge bg-secondary">{{ translate('all') }}</span>
                                            @endif
                                        </td>
                                        <td>
                                            @if($offer->offer_type === 'discount_percent')
                                                {{ translate('percentage') }}
                                            @elseif($offer->offer_type === 'flat_discount')
                                                {{ translate('flat') }}
                                            @else
                                                {{ translate('per_seat') }}
                                            @endif
                                        </td>
                                        <td>
                                            @if($offer->offer_type === 'discount_percent')
                                                {{ $offer->offer_value }}%
                                            @else
                                                ₹{{ number_format($offer->offer_value, 2) }}
                                            @endif
                                        </td>
                                        <td>
                                            <small>{{ $offer->starts_at?->format('d M Y') }}</small>
                                            <br>
                                            <small class="text-muted">{{ $offer->ends_at?->format('d M Y') }}</small>
                                        </td>
                                        <td>
                                            <span class="badge bg-light text-dark">{{ $offer->current_uses }}/{{ $offer->max_uses_total > 0 ? $offer->max_uses_total : '∞' }}</span>
                                        </td>
                                        <td>
                                            @if($offer->ends_at && $offer->ends_at < now())
                                                <span class="badge bg-warning">{{ translate('expired') }}</span>
                                            @elseif($offer->is_active)
                                                <span class="badge bg-success">{{ translate('active') }}</span>
                                            @else
                                                <span class="badge bg-danger">{{ translate('inactive') }}</span>
                                            @endif
                                        </td>
                                        <td>
                                            <div class="d-flex gap-1">
                                                <a href="{{ route('admin.trip.festival-offers.edit', $offer->id) }}" class="btn btn-sm btn-outline-primary">
                                                    <i class="bi bi-pencil"></i>
                                                </a>
                                                <form action="{{ route('admin.trip.festival-offers.toggle-status', $offer->id) }}" method="POST">
                                                    @csrf
                                                    <button type="submit" class="btn btn-sm btn-outline-{{ $offer->is_active ? 'warning' : 'success' }}" title="{{ $offer->is_active ? translate('deactivate') : translate('activate') }}">
                                                        <i class="bi bi-{{ $offer->is_active ? 'pause-circle' : 'play-circle' }}"></i>
                                                    </button>
                                                </form>
                                                <form action="{{ route('admin.trip.festival-offers.destroy', $offer->id) }}" method="POST" onsubmit="return confirm('{{ translate('are_you_sure') }}')">
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
                                        <td colspan="9" class="text-center text-muted py-4">{{ translate('no_festival_offers_found') }}</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>

                    <div class="d-flex justify-content-end mt-3">
                        {{ $offers->withQueryString()->links() }}
                    </div>
                </div>
            </div>
        </div>
    </div>
@endsection
