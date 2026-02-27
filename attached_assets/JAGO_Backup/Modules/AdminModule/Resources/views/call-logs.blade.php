@extends('adminmodule::layouts.master')

@section('title', translate('Call Logs'))

@section('content')
<div class="main-content">
    <div class="container-fluid">
        <h2 class="fs-22 mb-4 text-capitalize">{{ translate('call_management') }}</h2>

        <div class="row mb-4">
            <div class="col-lg-3 col-sm-6 mb-3">
                <div class="card h-100">
                    <div class="card-body d-flex align-items-center gap-3">
                        <div style="width:48px;height:48px;border-radius:12px;background:linear-gradient(135deg,#2563EB,#1E3A8A);display:flex;align-items:center;justify-content:center;">
                            <i class="bi bi-telephone-fill text-white fs-5"></i>
                        </div>
                        <div>
                            <div class="text-muted fs-12 text-uppercase fw-semibold">{{ translate('total_calls') }}</div>
                            <h4 class="mb-0 text-primary">{{ $calls->total() }}</h4>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-lg-3 col-sm-6 mb-3">
                <div class="card h-100">
                    <div class="card-body d-flex align-items-center gap-3">
                        <div style="width:48px;height:48px;border-radius:12px;background:linear-gradient(135deg,#16A34A,#166534);display:flex;align-items:center;justify-content:center;">
                            <i class="bi bi-check-circle-fill text-white fs-5"></i>
                        </div>
                        <div>
                            <div class="text-muted fs-12 text-uppercase fw-semibold">{{ translate('completed') }}</div>
                            <h4 class="mb-0" style="color:#16A34A;">{{ \App\Models\Call::where('status','ended')->count() }}</h4>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-lg-3 col-sm-6 mb-3">
                <div class="card h-100">
                    <div class="card-body d-flex align-items-center gap-3">
                        <div style="width:48px;height:48px;border-radius:12px;background:linear-gradient(135deg,#DC2626,#991B1B);display:flex;align-items:center;justify-content:center;">
                            <i class="bi bi-x-circle-fill text-white fs-5"></i>
                        </div>
                        <div>
                            <div class="text-muted fs-12 text-uppercase fw-semibold">{{ translate('missed_rejected') }}</div>
                            <h4 class="mb-0" style="color:#DC2626;">{{ \App\Models\Call::whereIn('status',['rejected','failed'])->count() }}</h4>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-lg-3 col-sm-6 mb-3">
                <div class="card h-100">
                    <div class="card-body d-flex align-items-center gap-3">
                        <div style="width:48px;height:48px;border-radius:12px;background:linear-gradient(135deg,#7C3AED,#5B21B6);display:flex;align-items:center;justify-content:center;">
                            <i class="bi bi-headset text-white fs-5"></i>
                        </div>
                        <div>
                            <div class="text-muted fs-12 text-uppercase fw-semibold">{{ translate('support_calls') }}</div>
                            <h4 class="mb-0" style="color:#7C3AED;">{{ \App\Models\Call::where('call_type','support')->count() }}</h4>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="card">
            <div class="card-body">
                <div class="table-top d-flex flex-wrap gap-10 justify-content-between">
                    <form class="search-form search-form_style-two" method="GET" action="{{ route('admin.call.logs') }}">
                        <div class="input-group search-form__input_group">
                            <span class="search-form__icon"><i class="bi bi-search"></i></span>
                            <input type="search" name="search" value="{{ request('search') }}"
                                class="theme-input-style search-form__input"
                                placeholder="{{ translate('Search by name or phone') }}">
                        </div>
                        <button type="submit" class="btn btn-primary">{{ translate('search') }}</button>
                    </form>

                    <div class="d-flex flex-wrap gap-3">
                        <select name="call_type" class="js-select form-select" style="min-width:130px;" onchange="this.form.submit()" form="filter-form">
                            <option value="">{{ translate('all_types') }}</option>
                            <option value="trip" {{ request('call_type') == 'trip' ? 'selected' : '' }}>{{ translate('trip_calls') }}</option>
                            <option value="support" {{ request('call_type') == 'support' ? 'selected' : '' }}>{{ translate('support_calls') }}</option>
                        </select>
                        <select name="status" class="js-select form-select" style="min-width:130px;" onchange="this.form.submit()" form="filter-form">
                            <option value="">{{ translate('all_status') }}</option>
                            <option value="ended" {{ request('status') == 'ended' ? 'selected' : '' }}>{{ translate('completed') }}</option>
                            <option value="rejected" {{ request('status') == 'rejected' ? 'selected' : '' }}>{{ translate('rejected') }}</option>
                            <option value="failed" {{ request('status') == 'failed' ? 'selected' : '' }}>{{ translate('missed') }}</option>
                        </select>
                        <form id="filter-form" method="GET" action="{{ route('admin.call.logs') }}" style="display:none;">
                            <input type="hidden" name="search" value="{{ request('search') }}">
                        </form>
                    </div>
                </div>

                <div class="table-responsive mt-3">
                    <table class="table table-borderless align-middle">
                        <thead>
                            <tr>
                                <th>{{ translate('SL') }}</th>
                                <th>{{ translate('caller') }}</th>
                                <th>{{ translate('receiver') }}</th>
                                <th>{{ translate('type') }}</th>
                                <th>{{ translate('status') }}</th>
                                <th>{{ translate('duration') }}</th>
                                <th>{{ translate('date') }}</th>
                                <th>{{ translate('recording') }}</th>
                            </tr>
                        </thead>
                        <tbody>
                        @forelse($calls as $key => $call)
                            <tr>
                                <td>{{ $calls->firstItem() + $key }}</td>
                                <td>
                                    <div class="d-flex align-items-center gap-2">
                                        <div style="width:36px;height:36px;border-radius:10px;background:{{ $call->caller_type == 'customer' ? 'rgba(37,99,235,0.08)' : 'rgba(22,163,74,0.08)' }};display:flex;align-items:center;justify-content:center;">
                                            <i class="bi {{ $call->caller_type == 'customer' ? 'bi-person-fill' : 'bi-car-front-fill' }}"
                                               style="color:{{ $call->caller_type == 'customer' ? '#2563EB' : '#16A34A' }};"></i>
                                        </div>
                                        <div>
                                            <div class="fw-semibold fs-14">{{ $call->caller ? $call->caller->first_name . ' ' . ($call->caller->last_name ?? '') : 'N/A' }}</div>
                                            <div class="fs-12 text-muted">{{ $call->caller ? preg_replace('/(\d{2})\d{4,}(\d{2})/', '$1****$2', $call->caller->phone ?? '') : '' }}</div>
                                        </div>
                                    </div>
                                </td>
                                <td>
                                    <div class="d-flex align-items-center gap-2">
                                        <div style="width:36px;height:36px;border-radius:10px;background:{{ $call->callee_type == 'driver' ? 'rgba(22,163,74,0.08)' : ($call->callee_type == 'support' ? 'rgba(124,58,237,0.08)' : 'rgba(37,99,235,0.08)') }};display:flex;align-items:center;justify-content:center;">
                                            <i class="bi {{ $call->callee_type == 'driver' ? 'bi-car-front-fill' : ($call->callee_type == 'support' ? 'bi-headset' : 'bi-person-fill') }}"
                                               style="color:{{ $call->callee_type == 'driver' ? '#16A34A' : ($call->callee_type == 'support' ? '#7C3AED' : '#2563EB') }};"></i>
                                        </div>
                                        <div>
                                            <div class="fw-semibold fs-14">
                                                @if($call->callee_type == 'support')
                                                    {{ translate('Support Team') }}
                                                @else
                                                    {{ $call->callee ? $call->callee->first_name . ' ' . ($call->callee->last_name ?? '') : 'N/A' }}
                                                @endif
                                            </div>
                                            <div class="fs-12 text-muted">
                                                @if($call->callee && $call->callee_type != 'support')
                                                    {{ preg_replace('/(\d{2})\d{4,}(\d{2})/', '$1****$2', $call->callee->phone ?? '') }}
                                                @endif
                                            </div>
                                        </div>
                                    </div>
                                </td>
                                <td>
                                    @if($call->call_type == 'trip')
                                        <span class="badge bg-primary bg-opacity-10 text-primary">
                                            <i class="bi bi-car-front-fill me-1"></i>{{ translate('Trip') }}
                                        </span>
                                    @else
                                        <span class="badge" style="background:rgba(124,58,237,0.1);color:#7C3AED;">
                                            <i class="bi bi-headset me-1"></i>{{ translate('Support') }}
                                        </span>
                                    @endif
                                </td>
                                <td>
                                    @php
                                        $statusColors = [
                                            'ended' => ['bg' => 'rgba(22,163,74,0.1)', 'color' => '#16A34A', 'icon' => 'bi-check-circle-fill'],
                                            'accepted' => ['bg' => 'rgba(37,99,235,0.1)', 'color' => '#2563EB', 'icon' => 'bi-telephone-fill'],
                                            'ringing' => ['bg' => 'rgba(234,179,8,0.1)', 'color' => '#D97706', 'icon' => 'bi-bell-fill'],
                                            'initiated' => ['bg' => 'rgba(100,116,139,0.1)', 'color' => '#64748B', 'icon' => 'bi-arrow-up-right'],
                                            'rejected' => ['bg' => 'rgba(220,38,38,0.1)', 'color' => '#DC2626', 'icon' => 'bi-x-circle-fill'],
                                            'failed' => ['bg' => 'rgba(220,38,38,0.1)', 'color' => '#DC2626', 'icon' => 'bi-exclamation-triangle-fill'],
                                        ];
                                        $s = $statusColors[$call->status] ?? $statusColors['initiated'];
                                    @endphp
                                    <span class="badge" style="background:{{ $s['bg'] }};color:{{ $s['color'] }};">
                                        <i class="bi {{ $s['icon'] }} me-1"></i>{{ translate($call->status) }}
                                    </span>
                                </td>
                                <td>
                                    @if($call->duration_seconds > 0)
                                        <span class="fw-semibold">
                                            {{ gmdate('i:s', $call->duration_seconds) }}
                                        </span>
                                    @else
                                        <span class="text-muted">-</span>
                                    @endif
                                </td>
                                <td>
                                    <div class="fs-14">{{ $call->created_at->format('d M Y') }}</div>
                                    <div class="fs-12 text-muted">{{ $call->created_at->format('h:i A') }}</div>
                                </td>
                                <td>
                                    @if($call->recordings->count() > 0)
                                        @foreach($call->recordings as $rec)
                                            <button class="btn btn-sm btn-outline-primary d-inline-flex align-items-center gap-1 play-recording-btn"
                                                    data-url="{{ route('admin.call.recording', $rec->id) }}"
                                                    title="{{ translate('Play Recording') }}">
                                                <i class="bi bi-play-fill"></i>
                                                <span class="fs-12">{{ gmdate('i:s', $rec->duration_seconds) }}</span>
                                            </button>
                                        @endforeach
                                    @else
                                        <span class="text-muted fs-12">{{ translate('no_recording') }}</span>
                                    @endif
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="8" class="text-center py-4">
                                    <div class="d-flex flex-column align-items-center gap-2">
                                        <i class="bi bi-telephone-x fs-1 text-muted"></i>
                                        <span class="text-muted">{{ translate('no_call_logs_found') }}</span>
                                    </div>
                                </td>
                            </tr>
                        @endforelse
                        </tbody>
                    </table>
                </div>

                <div class="d-flex justify-content-end mt-3">
                    {{ $calls->links() }}
                </div>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="audioPlayerModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered modal-sm">
        <div class="modal-content">
            <div class="modal-header">
                <h6 class="modal-title"><i class="bi bi-soundwave me-2"></i>{{ translate('Call Recording') }}</h6>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body text-center py-4">
                <div style="width:64px;height:64px;border-radius:50%;background:linear-gradient(135deg,#2563EB,#1E3A8A);display:flex;align-items:center;justify-content:center;margin:0 auto 16px;">
                    <i class="bi bi-soundwave text-white fs-3"></i>
                </div>
                <audio id="modalAudioPlayer" controls style="width:100%;border-radius:10px;"></audio>
            </div>
        </div>
    </div>
</div>
@endsection

@push('script')
<script>
    document.querySelectorAll('.play-recording-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            const url = this.dataset.url;
            const player = document.getElementById('modalAudioPlayer');
            player.src = url;
            const modal = new bootstrap.Modal(document.getElementById('audioPlayerModal'));
            modal.show();
            player.play().catch(() => {});
        });
    });

    document.getElementById('audioPlayerModal').addEventListener('hidden.bs.modal', function() {
        document.getElementById('modalAudioPlayer').pause();
    });
</script>
@endpush
