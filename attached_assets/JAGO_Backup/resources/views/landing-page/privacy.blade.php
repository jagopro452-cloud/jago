@extends('landing-page.layouts.master')
@section('title', translate('Privacy Policy') . ' - ' . (getSession('business_name') ?: 'JAGO'))

@section('content')

<div class="jago-page-hero jago-page-hero--legal">
    <div class="jago-page-hero-bg"></div>
    <div class="container position-relative" style="z-index:2">
        <nav class="jago-breadcrumb">
            <a href="{{ route('index') }}">{{ translate('Home') }}</a>
            <span class="jago-breadcrumb-sep">/</span>
            <span>{{ translate('Privacy Policy') }}</span>
        </nav>
        <h1 class="jago-page-title">{{ translate('Privacy Policy') }}</h1>
        <p class="jago-page-subtitle">{{ $data?->value['short_description'] ?? "Your privacy matters to us" }}</p>
    </div>
</div>

<section class="jago-trust-strip">
    <div class="container">
        <div class="jago-trust-badges">
            <div class="jago-trust-badge">
                <div class="jago-trust-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                </div>
                <span>{{ translate('256-bit Encryption') }}</span>
            </div>
            <div class="jago-trust-badge">
                <div class="jago-trust-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>
                </div>
                <span>{{ translate('Data Protected') }}</span>
            </div>
            <div class="jago-trust-badge">
                <div class="jago-trust-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                </div>
                <span>{{ translate('IT Act Compliant') }}</span>
            </div>
            <div class="jago-trust-badge">
                <div class="jago-trust-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M8 11V7a4 4 0 118 0m-4 8v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2z"/></svg>
                </div>
                <span>{{ translate('Secure Payments') }}</span>
            </div>
        </div>
    </div>
</section>

<section class="jago-legal-section">
    <div class="container">
        <div class="row g-5">
            <div class="col-lg-3">
                <div class="jago-legal-sidebar">
                    <div class="jago-legal-sidebar-title">{{ translate('Quick Navigation') }}</div>
                    <nav class="jago-legal-nav">
                        <a href="#info-collect">1. {{ translate('Information We Collect') }}</a>
                        <a href="#how-use">2. {{ translate('How We Use Your Info') }}</a>
                        <a href="#info-sharing">3. {{ translate('Information Sharing') }}</a>
                        <a href="#data-security">4. {{ translate('Data Security') }}</a>
                        <a href="#data-retention">5. {{ translate('Data Retention') }}</a>
                        <a href="#your-rights">6. {{ translate('Your Rights') }}</a>
                        <a href="#cookies">7. {{ translate('Cookies & Tracking') }}</a>
                        <a href="#children">8. {{ translate("Children's Privacy") }}</a>
                        <a href="#changes">9. {{ translate('Policy Changes') }}</a>
                        <a href="#contact-privacy">10. {{ translate('Contact Us') }}</a>
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
                    <h3>{{ translate('Have questions about your privacy?') }}</h3>
                    <p>{{ translate('Our dedicated privacy team is here to help. Reach out to us anytime.') }}</p>
                </div>
                <div class="col-md-4 text-md-end">
                    <a href="{{ route('contact-us') }}" class="jago-cta-btn">{{ translate('Contact Us') }}</a>
                </div>
            </div>
        </div>
    </div>
</section>
@endsection
