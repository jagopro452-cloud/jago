@extends('landing-page.layouts.master')
@section('title', translate('Contact Us') . ' - ' . ($businessName ?? 'JAGO'))

@section('content')

<div class="jago-page-hero">
    <div class="jago-page-hero-bg"></div>
    <div class="container position-relative" style="z-index:2">
        <nav class="jago-breadcrumb">
            <a href="{{ route('index') }}">{{ translate('Home') }}</a>
            <span class="jago-breadcrumb-sep">/</span>
            <span>{{ translate('Contact Us') }}</span>
        </nav>
        <h1 class="jago-page-title">{{ translate('Contact Us') }}</h1>
        <p class="jago-page-subtitle">{{ translate("We'd love to hear from you. Our team is always here to help.") }}</p>
    </div>
</div>

<section class="jago-contact-section">
    <div class="container">
        <div class="jago-contact-grid">
            <div class="jago-contact-card">
                <div class="jago-contact-card-icon" style="background:rgba(37,99,235,0.1);color:#2563EB">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>
                </div>
                <h4>{{ translate('Email Us') }}</h4>
                <p>{{ translate('For general inquiries and support') }}</p>
                <a href="mailto:{{ $businessEmail }}" class="jago-contact-link">{{ $businessEmail }}</a>
            </div>
            <div class="jago-contact-card">
                <div class="jago-contact-card-icon" style="background:rgba(16,185,129,0.1);color:#10B981">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/></svg>
                </div>
                <h4>{{ translate('Call Us') }}</h4>
                <p>{{ translate('Available 24/7 for urgent matters') }}</p>
                <a href="tel:{{ $businessPhone }}" class="jago-contact-link">{{ $businessPhone }}</a>
            </div>
            <div class="jago-contact-card">
                <div class="jago-contact-card-icon" style="background:rgba(139,92,246,0.1);color:#8B5CF6">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/><path d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
                </div>
                <h4>{{ translate('Visit Us') }}</h4>
                <p>{{ translate('Our registered office') }}</p>
                <span class="jago-contact-link">{{ $businessAddress }}</span>
            </div>
        </div>

        <div class="jago-contact-company-info">
            <div class="row g-4 align-items-center">
                <div class="col-lg-6">
                    <h3>{{ $businessName }}</h3>
                    <p>{{ translate('Building innovative logistics and mobility solutions for India and beyond.') }}</p>
                    <div class="jago-contact-meta">
                        <div class="jago-contact-meta-item">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:18px;height:18px"><path d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/></svg>
                            <span>{{ translate('Registered under Companies Act, 2013') }}</span>
                        </div>
                        <div class="jago-contact-meta-item">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:18px;height:18px"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg>
                            <span>{{ translate('Response Time: Within 24 hours') }}</span>
                        </div>
                        @if($businessEmail)
                        <div class="jago-contact-meta-item">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:18px;height:18px"><path d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>
                            <span>{{ $businessEmail }}</span>
                        </div>
                        @endif
                    </div>
                </div>
                <div class="col-lg-6">
                    <div class="jago-support-hours">
                        <h5>{{ translate('Support Hours') }}</h5>
                        <div class="jago-hours-grid">
                            <div class="jago-hours-item">
                                <span class="jago-hours-day">{{ translate('Customer Support') }}</span>
                                <span class="jago-hours-time jago-hours-open">24/7</span>
                            </div>
                            <div class="jago-hours-item">
                                <span class="jago-hours-day">{{ translate('Driver Support') }}</span>
                                <span class="jago-hours-time jago-hours-open">24/7</span>
                            </div>
                            <div class="jago-hours-item">
                                <span class="jago-hours-day">{{ translate('Business Inquiries') }}</span>
                                <span class="jago-hours-time">{{ translate('Mon - Sat, 9 AM - 7 PM') }}</span>
                            </div>
                            <div class="jago-hours-item">
                                <span class="jago-hours-day">{{ translate('Grievance Officer') }}</span>
                                <span class="jago-hours-time">{{ translate('Mon - Fri, 10 AM - 6 PM') }}</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>
@endsection
