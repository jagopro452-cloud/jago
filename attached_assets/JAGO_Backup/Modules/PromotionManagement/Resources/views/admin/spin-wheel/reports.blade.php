@section('title', translate('spin_wheel_reports'))

@extends('adminmodule::layouts.master')

@push('css_or_js')
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
.sw-page {
    --sw-primary: #2563EB;
    --sw-primary-dark: #1E3A8A;
    --sw-primary-deeper: #0F172A;
    --sw-accent: #3B82F6;
    --sw-success: #10B981;
    --sw-danger: #EF4444;
    --sw-warning: #F59E0B;
    --sw-purple: #8B5CF6;
    --sw-pink: #EC4899;
    --sw-cyan: #06B6D4;
    --sw-orange: #F97316;
    --sw-bg: #F8FAFC;
    --sw-card-bg: #FFFFFF;
    --sw-text: #0F172A;
    --sw-text-secondary: #64748B;
    --sw-border: #E2E8F0;
    --sw-radius: 16px;
    --sw-radius-sm: 10px;
    --sw-shadow: 0 1px 3px rgba(0,0,0,0.04), 0 4px 12px rgba(0,0,0,0.06);
    --sw-shadow-lg: 0 4px 6px rgba(0,0,0,0.04), 0 10px 30px rgba(0,0,0,0.08);
    font-family: 'Poppins', sans-serif;
    background: var(--sw-bg);
}
.sw-page * { box-sizing: border-box; }

@keyframes fadeInUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
@keyframes float { 0%, 100% { transform: translateY(0px); } 50% { transform: translateY(-8px); } }
@keyframes count-up { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
@keyframes bar-grow { from { width: 0; } }
@keyframes bar-height-grow { from { height: 0; } }

.sw-hero {
    background: linear-gradient(135deg, var(--sw-primary-deeper) 0%, var(--sw-primary-dark) 35%, var(--sw-primary) 65%, var(--sw-accent) 100%);
    border-radius: 20px;
    padding: 32px 36px;
    color: white;
    position: relative;
    overflow: hidden;
    margin-bottom: 28px;
    animation: fadeInUp 0.6s ease;
}
.sw-hero::before {
    content: '';
    position: absolute;
    top: -80px; right: -80px;
    width: 280px; height: 280px;
    border-radius: 50%;
    background: radial-gradient(circle, rgba(255,255,255,0.08) 0%, transparent 70%);
    animation: float 6s ease-in-out infinite;
}
.sw-hero::after {
    content: '';
    position: absolute;
    bottom: -60px; left: 20%;
    width: 200px; height: 200px;
    border-radius: 50%;
    background: radial-gradient(circle, rgba(255,255,255,0.04) 0%, transparent 70%);
    animation: float 8s ease-in-out infinite reverse;
}
.sw-hero-content { position: relative; z-index: 2; }
.sw-hero h2 {
    font-weight: 800; font-size: 26px; margin-bottom: 6px;
    letter-spacing: -0.3px; text-shadow: 0 2px 10px rgba(0,0,0,0.15);
}
.sw-hero p { opacity: 0.85; font-size: 14px; margin: 0; font-weight: 400; }
.sw-hero-btn {
    display: inline-flex; align-items: center; gap: 6px;
    padding: 10px 20px; border-radius: 10px; font-weight: 600; font-size: 13px;
    text-decoration: none; transition: all 0.3s;
    border: 1.5px solid rgba(255,255,255,0.25);
    background: rgba(255,255,255,0.1); backdrop-filter: blur(8px); color: white;
}
.sw-hero-btn:hover { background: rgba(255,255,255,0.2); border-color: rgba(255,255,255,0.4); transform: translateY(-2px); color: white; }

.sw-filter-bar {
    background: var(--sw-card-bg);
    border-radius: var(--sw-radius);
    padding: 20px 24px;
    box-shadow: var(--sw-shadow);
    border: 1px solid var(--sw-border);
    margin-bottom: 24px;
    animation: fadeInUp 0.6s ease 0.05s both;
}
.sw-filter-form { display: flex; flex-wrap: wrap; align-items: flex-end; gap: 16px; }
.sw-filter-group label {
    display: block; font-weight: 600; font-size: 11px;
    color: var(--sw-text-secondary); text-transform: uppercase;
    letter-spacing: 0.8px; margin-bottom: 6px;
}
.sw-filter-input {
    border: 1.5px solid var(--sw-border); border-radius: var(--sw-radius-sm);
    padding: 10px 14px; font-size: 14px; font-family: 'Poppins', sans-serif;
    transition: all 0.25s; background: #FAFBFC; color: var(--sw-text);
    min-width: 160px;
}
.sw-filter-input:focus { border-color: var(--sw-primary); box-shadow: 0 0 0 3px rgba(37,99,235,0.08); outline: none; }
.sw-btn {
    display: inline-flex; align-items: center; justify-content: center; gap: 8px;
    padding: 10px 24px; border-radius: var(--sw-radius-sm); font-weight: 700;
    font-size: 13px; cursor: pointer; transition: all 0.3s; border: none;
    font-family: 'Poppins', sans-serif; letter-spacing: 0.3px;
}
.sw-btn-primary {
    background: linear-gradient(135deg, var(--sw-primary), var(--sw-primary-dark));
    color: white; box-shadow: 0 4px 12px rgba(37,99,235,0.25);
}
.sw-btn-primary:hover { transform: translateY(-2px); box-shadow: 0 6px 20px rgba(37,99,235,0.35); color: white; }
.sw-btn-outline {
    background: white; color: var(--sw-primary);
    border: 1.5px solid var(--sw-primary); box-shadow: 0 2px 6px rgba(37,99,235,0.08);
}
.sw-btn-outline:hover { background: #EFF6FF; transform: translateY(-1px); }

.sw-stats-grid {
    display: grid; grid-template-columns: repeat(4, 1fr);
    gap: 16px; margin-bottom: 28px; animation: fadeInUp 0.6s ease 0.1s both;
}
@media (max-width: 992px) { .sw-stats-grid { grid-template-columns: repeat(2, 1fr); } }
@media (max-width: 576px) { .sw-stats-grid { grid-template-columns: 1fr; } }
.sw-stat-card {
    background: var(--sw-card-bg); border-radius: var(--sw-radius); padding: 24px;
    box-shadow: var(--sw-shadow); border: 1px solid var(--sw-border);
    transition: all 0.3s; position: relative; overflow: hidden;
}
.sw-stat-card::before {
    content: ''; position: absolute; top: 0; left: 0; right: 0; height: 3px;
    border-radius: var(--sw-radius) var(--sw-radius) 0 0;
}
.sw-stat-card:hover { transform: translateY(-4px); box-shadow: var(--sw-shadow-lg); }
.sw-stat-card:nth-child(1)::before { background: linear-gradient(90deg, var(--sw-primary), var(--sw-accent)); }
.sw-stat-card:nth-child(2)::before { background: linear-gradient(90deg, var(--sw-success), #34D399); }
.sw-stat-card:nth-child(3)::before { background: linear-gradient(90deg, var(--sw-warning), var(--sw-orange)); }
.sw-stat-card:nth-child(4)::before { background: linear-gradient(90deg, var(--sw-pink), var(--sw-purple)); }
.sw-stat-icon {
    width: 52px; height: 52px; border-radius: 14px;
    display: flex; align-items: center; justify-content: center; font-size: 24px; flex-shrink: 0;
}
.sw-stat-value {
    font-size: 30px; font-weight: 800; color: var(--sw-text);
    line-height: 1.1; letter-spacing: -0.5px; animation: count-up 0.6s ease 0.3s both;
}
.sw-stat-label {
    font-size: 11px; color: var(--sw-text-secondary); text-transform: uppercase;
    letter-spacing: 1px; font-weight: 600; margin-top: 4px;
}

.sw-card {
    background: var(--sw-card-bg); border-radius: var(--sw-radius);
    box-shadow: var(--sw-shadow); border: 1px solid var(--sw-border);
    overflow: hidden; transition: box-shadow 0.3s; animation: fadeInUp 0.6s ease 0.2s both;
}
.sw-card:hover { box-shadow: var(--sw-shadow-lg); }
.sw-card-header {
    background: linear-gradient(135deg, var(--sw-primary-deeper), var(--sw-primary-dark), var(--sw-primary));
    color: white; padding: 18px 24px; font-weight: 600; font-size: 15px;
    display: flex; align-items: center; justify-content: space-between; gap: 12px;
}
.sw-card-header-icon {
    width: 36px; height: 36px; border-radius: 10px; background: rgba(255,255,255,0.15);
    display: flex; align-items: center; justify-content: center; font-size: 16px; flex-shrink: 0;
}
.sw-card-body { padding: 24px; }

.sw-chart-area {
    position: relative; height: 220px; display: flex; align-items: flex-end;
    gap: 3px; overflow-x: auto; padding-bottom: 32px; padding-top: 16px;
}
.sw-chart-bar {
    flex: 1; min-width: 12px; border-radius: 6px 6px 0 0;
    position: relative; cursor: pointer; transition: opacity 0.2s;
    animation: bar-height-grow 0.8s ease both;
}
.sw-chart-bar:hover { opacity: 0.85; }
.sw-chart-bar:hover .sw-chart-tooltip { display: block; }
.sw-chart-tooltip {
    display: none; position: absolute; bottom: calc(100% + 8px); left: 50%;
    transform: translateX(-50%); background: var(--sw-primary-deeper); color: white;
    padding: 8px 12px; border-radius: 8px; font-size: 11px; white-space: nowrap;
    z-index: 10; box-shadow: 0 4px 12px rgba(0,0,0,0.2); font-weight: 500;
    line-height: 1.5;
}
.sw-chart-tooltip::after {
    content: ''; position: absolute; top: 100%; left: 50%; transform: translateX(-50%);
    border: 5px solid transparent; border-top-color: var(--sw-primary-deeper);
}
.sw-chart-x-labels {
    display: flex; justify-content: space-between; margin-top: 8px;
    color: var(--sw-text-secondary); font-size: 11px; font-weight: 500;
}
.sw-chart-y-label {
    position: absolute; left: 0; font-size: 10px; color: var(--sw-text-secondary);
    font-weight: 500; transform: translateY(50%);
}
.sw-chart-grid-line {
    position: absolute; left: 0; right: 0; height: 1px;
    background: #EEF2F6; pointer-events: none;
}

.sw-dist-item {
    display: flex; align-items: center; gap: 12px;
    padding: 12px 0; border-bottom: 1px solid #F1F5F9;
}
.sw-dist-item:last-child { border-bottom: none; }
.sw-dist-color {
    width: 14px; height: 14px; border-radius: 4px;
    flex-shrink: 0; box-shadow: 0 1px 3px rgba(0,0,0,0.15);
}
.sw-dist-label { font-weight: 700; font-size: 14px; color: var(--sw-text); min-width: 50px; }
.sw-dist-bar-track {
    flex: 1; height: 24px; background: #F1F5F9; border-radius: 8px;
    overflow: hidden; position: relative;
}
.sw-dist-bar-fill {
    height: 100%; border-radius: 8px; display: flex; align-items: center;
    padding-left: 10px; font-size: 11px; font-weight: 700; color: white;
    text-shadow: 0 1px 2px rgba(0,0,0,0.2); transition: width 0.8s ease;
    animation: bar-grow 1s ease both;
    min-width: fit-content;
}
.sw-dist-amount {
    font-size: 12px; font-weight: 600; color: var(--sw-text-secondary);
    min-width: 65px; text-align: right;
}

.sw-table-wrap { overflow-x: auto; }
.sw-table { width: 100%; border-collapse: collapse; font-size: 14px; }
.sw-table thead th {
    background: linear-gradient(135deg, #F1F5F9, #E2E8F0);
    font-weight: 700; font-size: 11px; text-transform: uppercase;
    letter-spacing: 1px; color: var(--sw-text-secondary);
    padding: 14px 16px; border: none; white-space: nowrap;
    position: sticky; top: 0; z-index: 5;
}
.sw-table tbody td {
    padding: 14px 16px; vertical-align: middle; border-bottom: 1px solid #F1F5F9;
}
.sw-table tbody tr { transition: background 0.15s; }
.sw-table tbody tr:hover { background: #F8FAFC; }
.sw-badge {
    display: inline-flex; align-items: center; gap: 4px;
    padding: 5px 12px; border-radius: 8px; font-weight: 600; font-size: 12px;
}
.sw-badge-blue { background: #EFF6FF; color: var(--sw-primary); }
.sw-badge-green { background: #ECFDF5; color: var(--sw-success); }
.sw-badge-amber { background: #FFFBEB; color: var(--sw-warning); }

.sw-rank {
    width: 32px; height: 32px; border-radius: 50%;
    display: inline-flex; align-items: center; justify-content: center;
    font-weight: 800; font-size: 13px;
}
.sw-rank-1 { background: linear-gradient(135deg, #F59E0B, #D97706); color: white; box-shadow: 0 2px 8px rgba(245,158,11,0.4); }
.sw-rank-2 { background: linear-gradient(135deg, #94A3B8, #64748B); color: white; box-shadow: 0 2px 8px rgba(148,163,184,0.4); }
.sw-rank-3 { background: linear-gradient(135deg, #CD7F32, #A0522D); color: white; box-shadow: 0 2px 8px rgba(205,127,50,0.4); }
.sw-rank-default { background: #F1F5F9; color: var(--sw-text-secondary); }

.sw-user-row { display: flex; align-items: center; gap: 10px; }
.sw-user-avatar {
    width: 36px; height: 36px; border-radius: 10px;
    background: linear-gradient(135deg, var(--sw-primary), var(--sw-accent));
    display: flex; align-items: center; justify-content: center;
    color: white; font-weight: 700; font-size: 14px; flex-shrink: 0;
    text-transform: uppercase;
}
.sw-user-name { font-weight: 600; font-size: 13px; color: var(--sw-text); }
.sw-user-phone { font-size: 11px; color: var(--sw-text-secondary); }

.sw-empty-state {
    text-align: center; padding: 60px 24px; color: var(--sw-text-secondary);
}
.sw-empty-state i { font-size: 56px; margin-bottom: 16px; opacity: 0.4; display: block; }
.sw-empty-state p { font-size: 14px; margin: 0; font-weight: 500; }

.sw-pagination { padding: 16px 24px; display: flex; justify-content: center; }
</style>
@endpush

@section('content')
<div class="main-content sw-page">
    <div class="container-fluid">

        <div class="sw-hero">
            <div class="sw-hero-content">
                <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
                    <div>
                        <h2><i class="bi bi-graph-up-arrow me-2"></i>{{ translate('spin_wheel_analytics') }}</h2>
                        <p>{{ translate('comprehensive_insights_and_performance_tracking') }}</p>
                    </div>
                    <div class="d-flex gap-2" style="position: relative; z-index: 2;">
                        <a href="{{ route('admin.promotion.spin-wheel.index') }}" class="sw-hero-btn">
                            <i class="bi bi-arrow-left"></i>{{ translate('back_to_setup') }}
                        </a>
                    </div>
                </div>
            </div>
        </div>

        <div class="sw-filter-bar">
            <form action="{{ route('admin.promotion.spin-wheel.reports') }}" method="GET" class="sw-filter-form">
                <div class="sw-filter-group">
                    <label>{{ translate('from_date') }}</label>
                    <input type="date" name="date_from" class="sw-filter-input" value="{{ $dateFrom->format('Y-m-d') }}">
                </div>
                <div class="sw-filter-group">
                    <label>{{ translate('to_date') }}</label>
                    <input type="date" name="date_to" class="sw-filter-input" value="{{ $dateTo->format('Y-m-d') }}">
                </div>
                <button type="submit" class="sw-btn sw-btn-primary">
                    <i class="bi bi-funnel-fill"></i>{{ translate('apply_filter') }}
                </button>
                <a href="{{ route('admin.promotion.spin-wheel.reports.export', ['date_from' => $dateFrom->format('Y-m-d'), 'date_to' => $dateTo->format('Y-m-d')]) }}" class="sw-btn sw-btn-outline">
                    <i class="bi bi-download"></i>{{ translate('export_csv') }}
                </a>
            </form>
        </div>

        <div class="sw-stats-grid">
            <div class="sw-stat-card">
                <div class="d-flex align-items-center gap-3">
                    <div class="sw-stat-icon" style="background: #EFF6FF; color: var(--sw-primary);">
                        <i class="bi bi-arrow-repeat"></i>
                    </div>
                    <div>
                        <div class="sw-stat-value">{{ number_format($totalSpins) }}</div>
                        <div class="sw-stat-label">{{ translate('total_spins') }}</div>
                    </div>
                </div>
            </div>
            <div class="sw-stat-card">
                <div class="d-flex align-items-center gap-3">
                    <div class="sw-stat-icon" style="background: #ECFDF5; color: var(--sw-success);">
                        <i class="bi bi-wallet2"></i>
                    </div>
                    <div>
                        <div class="sw-stat-value">₹{{ number_format($totalCredits, 0) }}</div>
                        <div class="sw-stat-label">{{ translate('credits_disbursed') }}</div>
                    </div>
                </div>
            </div>
            <div class="sw-stat-card">
                <div class="d-flex align-items-center gap-3">
                    <div class="sw-stat-icon" style="background: #FFFBEB; color: var(--sw-warning);">
                        <i class="bi bi-people-fill"></i>
                    </div>
                    <div>
                        <div class="sw-stat-value">{{ number_format($uniqueUsers) }}</div>
                        <div class="sw-stat-label">{{ translate('unique_participants') }}</div>
                    </div>
                </div>
            </div>
            <div class="sw-stat-card">
                <div class="d-flex align-items-center gap-3">
                    <div class="sw-stat-icon" style="background: #FDF2F8; color: var(--sw-pink);">
                        <i class="bi bi-calculator"></i>
                    </div>
                    <div>
                        <div class="sw-stat-value">₹{{ number_format($avgReward, 2) }}</div>
                        <div class="sw-stat-label">{{ translate('avg_reward_per_spin') }}</div>
                    </div>
                </div>
            </div>
        </div>

        <div class="row g-4 mb-4">
            <div class="col-lg-8">
                <div class="sw-card">
                    <div class="sw-card-header">
                        <div class="d-flex align-items-center gap-2">
                            <div class="sw-card-header-icon"><i class="bi bi-bar-chart-fill"></i></div>
                            <span>{{ translate('daily_spin_activity') }}</span>
                        </div>
                        <span class="badge bg-white bg-opacity-25 text-white" style="font-size: 11px; border-radius: 6px;">
                            {{ $dateFrom->format('d M') }} - {{ $dateTo->format('d M Y') }}
                        </span>
                    </div>
                    <div class="sw-card-body">
                        @if($dailyStats->count() > 0)
                            @php $maxDailySpins = $dailyStats->max('spins') ?: 1; @endphp
                            <div class="position-relative">
                                <div class="sw-chart-grid-line" style="bottom: 25%;"></div>
                                <div class="sw-chart-grid-line" style="bottom: 50%;"></div>
                                <div class="sw-chart-grid-line" style="bottom: 75%;"></div>
                                <div class="sw-chart-area">
                                    @foreach($dailyStats as $i => $day)
                                    <div class="sw-chart-bar" style="
                                        height: {{ max(12, ($day->spins / $maxDailySpins) * 190) }}px;
                                        background: linear-gradient(to top, var(--sw-primary-dark), var(--sw-primary), var(--sw-accent));
                                        animation-delay: {{ $i * 30 }}ms;
                                    ">
                                        <div class="sw-chart-tooltip">
                                            <strong>{{ \Carbon\Carbon::parse($day->date)->format('d M Y') }}</strong><br>
                                            {{ $day->spins }} {{ translate('spins') }}<br>
                                            ₹{{ number_format($day->credits, 0) }} {{ translate('credited') }}
                                        </div>
                                    </div>
                                    @endforeach
                                </div>
                            </div>
                            <div class="sw-chart-x-labels">
                                <span>{{ $dateFrom->format('d M') }}</span>
                                <span>{{ $dateTo->format('d M') }}</span>
                            </div>
                        @else
                            <div class="sw-empty-state">
                                <i class="bi bi-bar-chart"></i>
                                <p>{{ translate('no_activity_in_selected_period') }}</p>
                            </div>
                        @endif
                    </div>
                </div>
            </div>

            <div class="col-lg-4">
                <div class="sw-card" style="height: 100%;">
                    <div class="sw-card-header">
                        <div class="d-flex align-items-center gap-2">
                            <div class="sw-card-header-icon"><i class="bi bi-pie-chart-fill"></i></div>
                            <span>{{ translate('prize_distribution') }}</span>
                        </div>
                    </div>
                    <div class="sw-card-body">
                        @if($segmentStats->count() > 0)
                            @php
                                $maxSegWins = $segmentStats->max('times_won') ?: 1;
                                $distColors = ['#2563EB', '#10B981', '#EF4444', '#F59E0B', '#8B5CF6', '#06B6D4', '#EC4899', '#F97316'];
                            @endphp
                            @foreach($segmentStats as $i => $seg)
                            <div class="sw-dist-item">
                                <div class="sw-dist-color" style="background: {{ $distColors[$i % count($distColors)] }};"></div>
                                <div class="sw-dist-label">₹{{ $seg->discount_value }}</div>
                                <div class="sw-dist-bar-track">
                                    <div class="sw-dist-bar-fill" style="
                                        width: {{ max(8, ($seg->times_won / $maxSegWins) * 100) }}%;
                                        background: linear-gradient(90deg, {{ $distColors[$i % count($distColors)] }}, {{ $distColors[$i % count($distColors)] }}CC);
                                        animation-delay: {{ $i * 100 }}ms;
                                    ">
                                        {{ $seg->times_won }}x
                                    </div>
                                </div>
                                <div class="sw-dist-amount">₹{{ number_format($seg->total_amount, 0) }}</div>
                            </div>
                            @endforeach
                        @else
                            <div class="sw-empty-state">
                                <i class="bi bi-pie-chart"></i>
                                <p>{{ translate('no_prize_data_yet') }}</p>
                            </div>
                        @endif
                    </div>
                </div>
            </div>
        </div>

        <div class="sw-card">
            <div class="sw-card-header">
                <div class="d-flex align-items-center gap-2">
                    <div class="sw-card-header-icon"><i class="bi bi-trophy-fill"></i></div>
                    <span>{{ translate('user_leaderboard') }}</span>
                </div>
                <span class="badge bg-white bg-opacity-25 text-white" style="font-size: 11px; border-radius: 6px;">
                    {{ $userStats->total() }} {{ translate('participants') }}
                </span>
            </div>
            <div class="sw-card-body p-0">
                <div class="sw-table-wrap">
                    <table class="sw-table">
                        <thead>
                            <tr>
                                <th style="width: 60px;">{{ translate('rank') }}</th>
                                <th>{{ translate('customer') }}</th>
                                <th>{{ translate('total_spins') }}</th>
                                <th>{{ translate('total_earned') }}</th>
                                <th>{{ translate('avg_per_spin') }}</th>
                                <th>{{ translate('last_activity') }}</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($userStats as $key => $stat)
                            <tr>
                                <td>
                                    @php $rank = ($userStats->currentPage() - 1) * $userStats->perPage() + $key + 1; @endphp
                                    <span class="sw-rank {{ $rank <= 3 ? 'sw-rank-' . $rank : 'sw-rank-default' }}">
                                        @if($rank === 1) <i class="bi bi-trophy-fill" style="font-size: 14px;"></i>
                                        @else {{ $rank }}
                                        @endif
                                    </span>
                                </td>
                                <td>
                                    <div class="sw-user-row">
                                        <div class="sw-user-avatar">
                                            {{ $stat->user ? strtoupper(substr($stat->user->first_name, 0, 1)) : '?' }}
                                        </div>
                                        <div>
                                            <div class="sw-user-name">{{ $stat->user ? $stat->user->first_name . ' ' . $stat->user->last_name : 'N/A' }}</div>
                                            <div class="sw-user-phone">{{ $stat->user->phone ?? '' }}</div>
                                        </div>
                                    </div>
                                </td>
                                <td><span class="sw-badge sw-badge-blue"><i class="bi bi-arrow-repeat me-1"></i>{{ $stat->spin_count }}</span></td>
                                <td><span class="sw-badge sw-badge-green"><i class="bi bi-wallet2 me-1"></i>₹{{ number_format($stat->total_earned, 2) }}</span></td>
                                <td><span class="sw-badge sw-badge-amber">₹{{ $stat->spin_count > 0 ? number_format($stat->total_earned / $stat->spin_count, 2) : '0.00' }}</span></td>
                                <td><span class="text-muted" style="font-size: 12px;">{{ \Carbon\Carbon::parse($stat->last_spin)->format('d M Y, h:i A') }}</span></td>
                            </tr>
                            @empty
                            <tr>
                                <td colspan="6">
                                    <div class="sw-empty-state">
                                        <i class="bi bi-people"></i>
                                        <p>{{ translate('no_participants_found_for_this_period') }}</p>
                                    </div>
                                </td>
                            </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
                @if($userStats->hasPages())
                <div class="sw-pagination">
                    {{ $userStats->appends(request()->query())->links() }}
                </div>
                @endif
            </div>
        </div>
    </div>
</div>
@endsection
