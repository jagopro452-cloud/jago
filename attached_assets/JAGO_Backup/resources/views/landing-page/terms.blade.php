@extends('landing-page.layouts.master')
@section('title', translate('Terms & Conditions') . ' - ' . (getSession('business_name') ?: 'JAGO'))

@section('content')

<div class="jago-page-hero jago-page-hero--legal">
    <div class="jago-page-hero-bg"></div>
    <div class="container position-relative" style="z-index:2">
        <nav class="jago-breadcrumb">
            <a href="{{ route('index') }}">{{ translate('Home') }}</a>
            <span class="jago-breadcrumb-sep">/</span>
            <span>{{ translate('Terms & Conditions') }}</span>
        </nav>
        <h1 class="jago-page-title">{{ translate('Terms & Conditions') }}</h1>
        <p class="jago-page-subtitle">{{ $data?->value['short_description'] ?? "Please read these terms carefully before using our services" }}</p>
    </div>
</div>

<section class="jago-trust-strip">
    <div class="container">
        <div class="jago-trust-badges">
            <div class="jago-trust-badge">
                <div class="jago-trust-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                </div>
                <span>{{ translate('Legally Binding') }}</span>
            </div>
            <div class="jago-trust-badge">
                <div class="jago-trust-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                </div>
                <span>{{ translate('User Protected') }}</span>
            </div>
            <div class="jago-trust-badge">
                <div class="jago-trust-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6l3 1m0 0l-3 9a5.002 5.002 0 006.001 0M6 7l3 9M6 7l6-2m6 2l3-1m-3 1l-3 9a5.002 5.002 0 006.001 0M18 7l3 9m-3-9l-6-2m0-2v2m0 16V5m0 16H9m3 0h3"/></svg>
                </div>
                <span>{{ translate('Fair & Transparent') }}</span>
            </div>
            <div class="jago-trust-badge">
                <div class="jago-trust-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/></svg>
                </div>
                <span>{{ translate('Registered Entity') }}</span>
            </div>
        </div>
    </div>
</section>

<section class="jago-legal-section">
    <div class="container">
        <div class="row g-5">
            <div class="col-lg-3">
                <div class="jago-legal-sidebar">
                    <div class="jago-legal-sidebar-title">{{ translate('Table of Contents') }}</div>
                    <nav class="jago-legal-nav">
                        <a href="#definitions">1. {{ translate('Definitions') }}</a>
                        <a href="#eligibility">2. {{ translate('Eligibility') }}</a>
                        <a href="#account">3. {{ translate('Account Registration') }}</a>
                        <a href="#services">4. {{ translate('Services') }}</a>
                        <a href="#payments">5. {{ translate('Payments') }}</a>
                        <a href="#cancellation">6. {{ translate('Cancellation Policy') }}</a>
                        <a href="#user-conduct">7. {{ translate('User Conduct') }}</a>
                        <a href="#driver-obligations">8. {{ translate('Driver Obligations') }}</a>
                        <a href="#intellectual-property">9. {{ translate('Intellectual Property') }}</a>
                        <a href="#liability">10. {{ translate('Limitation of Liability') }}</a>
                        <a href="#indemnification">11. {{ translate('Indemnification') }}</a>
                        <a href="#termination">12. {{ translate('Termination') }}</a>
                        <a href="#governing-law">13. {{ translate('Governing Law') }}</a>
                        <a href="#contact-terms">14. {{ translate('Contact Information') }}</a>
                    </nav>
                    <div class="jago-legal-updated">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:16px;height:16px"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg>
                        {{ translate('Last Updated: February 2026') }}
                    </div>
                </div>
            </div>
            <div class="col-lg-9">
                <div class="jago-legal-content">
                    {!! $data?->value['long_description'] !!}
                </div>
            </div>
        </div>
    </div>
</section>

<section class="jago-legal-cta">
    <div class="container">
        <div class="jago-legal-cta-card">
            <div class="row align-items-center g-4">
                <div class="col-md-8">
                    <h3>{{ translate('Need clarification on our terms?') }}</h3>
                    <p>{{ translate('Our support team is available 24/7 to answer your questions about our policies.') }}</p>
                </div>
                <div class="col-md-4 text-md-end">
                    <a href="{{ route('contact-us') }}" class="jago-cta-btn">{{ translate('Get In Touch') }}</a>
                </div>
            </div>
        </div>
    </div>
</section>
@endsection
