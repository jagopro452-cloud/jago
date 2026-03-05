@extends('adminmodule::layouts.master')

@section('title', translate('Corporate Accounts'))

@section('content')
<div class="main-content">
    <div class="container-fluid">
        <div class="d-flex align-items-center justify-content-between gap-3 mb-3">
            <h2 class="fs-22 text-capitalize">{{ translate('Corporate Accounts') }}</h2>
            <div class="d-flex gap-2">
                <a href="{{ route('admin.business.setup.corporate.b2b-plans') }}" class="btn btn-outline-primary">
                    <i class="bi bi-box-seam"></i> {{ translate('B2B Parcel Plans') }}
                </a>
                <a href="{{ route('admin.business.setup.corporate.create') }}" class="btn btn-primary">
                    <i class="bi bi-plus-lg"></i> {{ translate('Add Corporate Account') }}
                </a>
            </div>
        </div>

        <div class="card">
            <div class="card-header border-0">
                <div class="d-flex align-items-center gap-2">
                    <h5 class="text-capitalize">{{ translate('All Corporate Accounts') }}
                        <span class="badge bg-primary">{{ $corporates->total() }}</span>
                    </h5>
                </div>
                <div class="d-flex align-items-center gap-3">
                    <form action="" method="GET" class="search-form">
                        <div class="input-group">
                            <input type="search" name="search" class="form-control" placeholder="{{ translate('Search by name or code...') }}" value="{{ $search ?? '' }}">
                            <button type="submit" class="btn btn-primary"><i class="bi bi-search"></i></button>
                        </div>
                    </form>
                </div>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-borderless align-middle">
                        <thead class="table-light">
                            <tr>
                                <th>{{ translate('SL') }}</th>
                                <th>{{ translate('Company') }}</th>
                                <th>{{ translate('Code') }}</th>
                                <th>{{ translate('Plan') }}</th>
                                <th>{{ translate('Employees') }}</th>
                                <th>{{ translate('Credit') }}</th>
                                <th>{{ translate('Status') }}</th>
                                <th class="text-center">{{ translate('Action') }}</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($corporates as $key => $corporate)
                            <tr>
                                <td>{{ $corporates->firstItem() + $key }}</td>
                                <td>
                                    <div>
                                        <strong>{{ $corporate->company_name }}</strong>
                                        <br><small class="text-muted">{{ $corporate->contact_person }}</small>
                                    </div>
                                </td>
                                <td><code>{{ $corporate->company_code }}</code></td>
                                <td><span class="badge bg-info text-capitalize">{{ $corporate->plan_type }}</span></td>
                                <td>{{ $corporate->active_employees }}/{{ $corporate->max_employees }}</td>
                                <td>
                                    <span title="{{ translate('Used') }}: {{ number_format($corporate->used_credit, 2) }}">
                                        {{ number_format($corporate->remaining_credit, 2) }}
                                    </span>
                                </td>
                                <td>
                                    <form action="{{ route('admin.business.setup.corporate.status', $corporate->id) }}" method="POST">
                                        @csrf
                                        <label class="switcher">
                                            <input class="switcher_input" type="checkbox" {{ $corporate->is_active ? 'checked' : '' }}
                                                onchange="this.closest('form').submit()">
                                            <span class="switcher_control"></span>
                                        </label>
                                    </form>
                                </td>
                                <td>
                                    <div class="d-flex justify-content-center gap-2">
                                        <a href="{{ route('admin.business.setup.corporate.edit', $corporate->id) }}" class="btn btn-sm btn-outline-info">
                                            <i class="bi bi-pencil"></i>
                                        </a>
                                    </div>
                                </td>
                            </tr>
                            @empty
                            <tr>
                                <td colspan="8" class="text-center py-4">
                                    <p class="text-muted mb-0">{{ translate('No corporate accounts found') }}</p>
                                </td>
                            </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
            <div class="card-footer border-0">
                {{ $corporates->links() }}
            </div>
        </div>
    </div>
</div>
@endsection
