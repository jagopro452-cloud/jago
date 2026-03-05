@extends('landing-page.layouts.master')
@section('title', translate('About Us') . ' - ' . ($businessName ?? 'JAGO'))

@section('content')
@php($logo = getSession('header_logo'))

<div class="jago-page-hero">
    <div class="jago-page-hero-bg"></div>
    <div class="container position-relative" style="z-index:2">
        <nav class="jago-breadcrumb">
            <a href="{{ route('index') }}">{{ translate('Home') }}</a>
            <span class="jago-breadcrumb-sep">/</span>
            <span>{{ translate('About Us') }}</span>
        </nav>
        <h1 class="jago-page-title">{{ translate('About Us') }}</h1>
        <p class="jago-page-subtitle">{{ $data?->value['short_description'] ?? translate('Empowering mobility and logistics with cutting-edge technology') }}</p>
    </div>
</div>

<section class="jago-trust-strip">
    <div class="container">
        <div class="jago-trust-badges">
            <div class="jago-trust-badge">
                <div class="jago-trust-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                </div>
                <span>{{ translate('SSL Secured') }}</span>
            </div>
            <div class="jago-trust-badge">
                <div class="jago-trust-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                </div>
                <span>{{ translate('Verified Company') }}</span>
            </div>
            <div class="jago-trust-badge">
                <div class="jago-trust-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87m-4-12a4 4 0 010 7.75"/></svg>
                </div>
                <span>{{ translate('24/7 Support') }}</span>
            </div>
            <div class="jago-trust-badge">
                <div class="jago-trust-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 15l-2 5l9-11h-5l2-5l-9 11h5z"/></svg>
                </div>
                <span>{{ translate('Fast & Reliable') }}</span>
            </div>
        </div>
    </div>
</section>

<section class="jago-about-intro">
    <div class="container">
        <div class="row align-items-center g-5">
            <div class="col-lg-5">
                <div class="jago-about-logo-card">
                    <img src="{{ $logo ? dynamicStorage(path: 'storage/app/public/business/'.$logo) : dynamicAsset(path: 'public/jago-logo.png') }}" alt="{{ $businessName }}" class="jago-about-logo-img">
                    <div class="jago-about-logo-tagline">{{ translate('Move Smarter.') }}</div>
                    <div class="jago-about-company-badge">
                        <span>{{ translate('A Product of') }}</span>
                        <strong>{{ $copyrightText ?: $businessName }}</strong>
                    </div>
                </div>
            </div>
            <div class="col-lg-7">
                <div class="jago-about-content-card">
                    {!! $data?->value['long_description'] ?? '' !!}
                </div>
            </div>
        </div>
    </div>
</section>

@if($activeBusinessStatistics->isNotEmpty())
<section class="jago-stats-section">
    <div class="container">
        <div class="jago-stats-grid">
            @foreach($activeBusinessStatistics as $stat)
            <div class="jago-stat-card">
                <div class="jago-stat-number">{{ $stat->value['title'] ?? '' }}</div>
                <div class="jago-stat-label">{{ translate($stat->value['content'] ?? '') }}</div>
            </div>
            @endforeach
        </div>
    </div>
</section>
@endif

<section class="jago-values-section">
    <div class="container">
        <div class="text-center mb-5">
            <h2 class="jago-section-heading">{{ translate('Why Choose') }} {{ $businessName }}?</h2>
            <p class="jago-section-subheading">{{ translate('Built on values that put you first') }}</p>
        </div>
        <div class="jago-values-grid">
            <div class="jago-value-card">
                <div class="jago-value-icon" style="background:rgba(37,99,235,0.1);color:#2563EB">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                </div>
                <h4>{{ translate('Safety First') }}</h4>
                <p>{{ translate('Real-time tracking, verified drivers, SOS button, and 24/7 safety monitoring for every ride and delivery') }}</p>
            </div>
            <div class="jago-value-card">
                <div class="jago-value-icon" style="background:rgba(16,185,129,0.1);color:#10B981">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                </div>
                <h4>{{ translate('Transparent Pricing') }}</h4>
                <p>{{ translate('No hidden charges, no surge surprises. See your fare upfront with our smart AI-powered fare calculation') }}</p>
            </div>
            <div class="jago-value-card">
                <div class="jago-value-icon" style="background:rgba(139,92,246,0.1);color:#8B5CF6">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M13 10V3L4 14h7v7l9-11h-7z"/></svg>
                </div>
                <h4>{{ translate('Lightning Fast') }}</h4>
                <p>{{ translate('AI-powered driver matching, optimized routes, and real-time dispatching for the fastest pickup times') }}</p>
            </div>
            <div class="jago-value-card">
                <div class="jago-value-icon" style="background:rgba(245,158,11,0.1);color:#F59E0B">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/></svg>
                </div>
                <h4>{{ translate('Driver Empowerment') }}</h4>
                <p>{{ translate('Fair earnings, flexible schedules, subscription options, and performance rewards for our driver partners') }}</p>
            </div>
            <div class="jago-value-card">
                <div class="jago-value-icon" style="background:rgba(236,72,153,0.1);color:#EC4899">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/></svg>
                </div>
                <h4>{{ translate('Parcel Delivery') }}</h4>
                <p>{{ translate('Send parcels across the city with real-time tracking, secure handling, and doorstep delivery guaranteed') }}</p>
            </div>
            <div class="jago-value-card">
                <div class="jago-value-icon" style="background:rgba(6,182,212,0.1);color:#06B6D4">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>
                </div>
                <h4>{{ translate('Data Privacy') }}</h4>
                <p>{{ translate('Enterprise-grade encryption, secure payments, and strict data protection policies to keep your information safe') }}</p>
            </div>
        </div>
    </div>
</section>

<section class="jago-company-section">
    <div class="container">
        <div class="jago-company-card">
            <div class="row align-items-center g-4">
                <div class="col-md-8">
                    <div class="jago-company-reg-badge">{{ translate('Registered Company') }}</div>
                    <h3>{{ $copyrightText ? preg_replace('/^©\s*\d{4}\s*/','', str_replace('. All rights reserved.', '', $copyrightText)) : $businessName }}</h3>
                    <p>{{ translate('Registered under the Companies Act, 2013') }}</p>
                    <div class="jago-company-details">
                        @if($businessAddress)
                        <div class="jago-company-detail">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/><path d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
                            <span>{{ $businessAddress }}</span>
                        </div>
                        @endif
                        @if($businessEmail)
                        <div class="jago-company-detail">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>
                            <span>{{ $businessEmail }}</span>
                        </div>
                        @endif
                        @if($businessPhone)
                        <div class="jago-company-detail">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/></svg>
                            <span>{{ $businessPhone }}</span>
                        </div>
                        @endif
                    </div>
                </div>
                <div class="col-md-4 text-center">
                    <div class="jago-compliance-badges">
                        <div class="jago-compliance-badge">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            <span>{{ translate('IT Act 2000') }}</span>
                        </div>
                        <div class="jago-compliance-badge">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            <span>{{ translate('GST Compliant') }}</span>
                        </div>
                        <div class="jago-compliance-badge">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            <span>{{ translate('Data Protected') }}</span>
                        </div>
                        <div class="jago-compliance-badge">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            <span>{{ translate('PCI DSS') }}</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>
@endsection
