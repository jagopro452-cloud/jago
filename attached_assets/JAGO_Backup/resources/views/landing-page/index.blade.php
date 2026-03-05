@php
    use Jenssegers\Agent\Agent;
     $userAgent = new Agent();
     $solutionCount = $activeOurSolutions->count() ?? 0;
     $siteUrl = url('/');
     $siteName = $businessName ?? 'JAGO';
     $seoTitle = $siteName . ' - India\'s Smart Logistics & Mobility Platform | Book Rides & Parcel Delivery';
     $seoDescription = $siteName . ' is India\'s fastest-growing ride-sharing and parcel delivery platform. Book auto, bike, and car rides instantly. Send parcels across the city with real-time tracking. Download the ' . $siteName . ' app now!';
     $seoKeywords = 'JAGO, ride booking app India, auto booking, bike taxi, cab booking, parcel delivery, logistics platform, ride sharing India, book auto online, send parcel, courier service, last mile delivery, Rapido alternative, Ola alternative, Uber alternative, Porter alternative, bike ride booking, auto ride, car booking app';
@endphp
@extends('landing-page.layouts.master')
@section('title', $seoTitle)

@push('seo')
    <meta name="description" content="{{ $seoDescription }}">
    <meta name="keywords" content="{{ $seoKeywords }}">
    <meta name="robots" content="index, follow, max-snippet:-1, max-image-preview:large, max-video-preview:-1">
    <meta name="author" content="Mindwhile IT Solutions Pvt Ltd">
    <link rel="canonical" href="{{ $siteUrl }}">

    <meta property="og:type" content="website">
    <meta property="og:url" content="{{ $siteUrl }}">
    <meta property="og:title" content="{{ $seoTitle }}">
    <meta property="og:description" content="{{ $seoDescription }}">
    <meta property="og:site_name" content="{{ $siteName }}">
    <meta property="og:locale" content="en_IN">
    @if($introSection && $introSection['background_image'])
    <meta property="og:image" content="{{ dynamicStorage(path: 'storage/app/public/business/landing-pages/intro-section/'.$introSection['background_image']) }}">
    @endif

    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="{{ $seoTitle }}">
    <meta name="twitter:description" content="{{ $seoDescription }}">
    @if($introSection && $introSection['background_image'])
    <meta name="twitter:image" content="{{ dynamicStorage(path: 'storage/app/public/business/landing-pages/intro-section/'.$introSection['background_image']) }}">
    @endif

    <script type="application/ld+json">
    {
        "@@context": "https://schema.org",
        "@@type": "Organization",
        "name": "{{ $siteName }}",
        "url": "{{ $siteUrl }}",
        "description": "{{ $seoDescription }}",
        "founder": {
            "@@type": "Organization",
            "name": "Mindwhile IT Solutions Pvt Ltd"
        },
        "areaServed": {
            "@@type": "Country",
            "name": "India"
        },
        "serviceType": ["Ride Sharing", "Parcel Delivery", "Logistics", "Bike Taxi", "Auto Booking", "Cab Booking"]
    }
    </script>
    <script type="application/ld+json">
    {
        "@@context": "https://schema.org",
        "@@type": "MobileApplication",
        "name": "{{ $siteName }}",
        "operatingSystem": "Android, iOS",
        "applicationCategory": "TravelApplication",
        "description": "Book rides and send parcels instantly with {{ $siteName }}. Auto, bike, car rides and parcel delivery across India.",
        "offers": {
            "@@type": "Offer",
            "price": "0",
            "priceCurrency": "INR"
        }
    }
    </script>
    <script type="application/ld+json">
    {
        "@@context": "https://schema.org",
        "@@type": "WebSite",
        "name": "{{ $siteName }}",
        "url": "{{ $siteUrl }}",
        "potentialAction": {
            "@@type": "SearchAction",
            "target": "{{ $siteUrl }}?q={search_term_string}",
            "query-input": "required name=search_term_string"
        }
    }
    </script>
@endpush

@section('content')
    <!-- Intro Section Start -->
    <section class="banner-section">
        <div class="container">
            <div class="banner-wrapper justify-content-between bg__img wow animate__fadeInDown"
                 data-img="{{ $introSection && $introSection['background_image'] ? dynamicStorage(path: 'storage/app/public/business/landing-pages/intro-section/'.$introSection['background_image']) : dynamicAsset(path: 'public/landing-page/assets/img/banner/banner-bg.png') }}">
                <div class="banner-content text-center text-sm-start">
                    <h1 class="title fs-20-mobile max-w-100">{!! $introSection && $introSection['title'] ? change_text_color_or_bg($introSection['title']) : translate("Your Smart Logistics & Mobility Platform") !!}</h1>
                    <p class="txt fs-12-mobile">{!! $introSection && $introSection['sub_title'] ? change_text_color_or_bg($introSection['sub_title']) : translate("Powering seamless parcel delivery, smart fleet management, and real-time tracking — "). ($businessName  ??  "JAGO") .translate("is the all-in-one logistics and ride-sharing solution built for modern businesses.") !!}
                    </p>
                    @if($driverAppVersionControlForAndroid || $driverAppVersionControlForIos || $customerAppVersionControlForAndroid || $customerAppVersionControlForIos)
                        <div class="app--btns d-flex flex-wrap flex-column flex-sm-row">

                            @if($customerAppVersionControlForAndroid && $customerAppVersionControlForIos)
                                <div class="dropdown py-0">
                                    <a href="#" class="cmn--btn h-50 d-flex gap-2 lh-1"
                                       data-bs-toggle="dropdown">{{translate('Download User App')}} <i
                                            class="bi bi-chevron-down"></i></a>
                                    <div class="dropdown-menu dropdown-button-menu">
                                        <ul>
                                            <li class="border-bottom">
                                                <a href="{{$customerAppVersionControlForAndroid['app_url']}}"
                                                   target="_blank">
                                                    <img width="20" class="w-20px"
                                                         src="{{ dynamicAsset(path: 'public/landing-page/assets/img/play-fav.png') }}"
                                                         alt="">
                                                    <span>{{translate('Play Store')}}</span>
                                                </a>
                                            </li>
                                            <li>
                                                <a href="{{$customerAppVersionControlForIos['app_url']}}"
                                                   target="_blank">
                                                    <img width="20" class="w-20px"
                                                         src="{{ dynamicAsset(path: 'public/landing-page/assets/img/apple.png') }}"
                                                         alt="">
                                                    <span>{{translate('App Store')}}</span>
                                                </a>
                                            </li>
                                        </ul>
                                    </div>
                                </div>
                            @elseif($customerAppVersionControlForAndroid)
                                <a href="{{$customerAppVersionControlForAndroid['app_url']}}" target="_blank"
                                   class="cmn--btn h-50 d-flex gap-2 lh-1">
                                    {{translate('Download User App')}}
                                </a>
                            @elseif($customerAppVersionControlForIos)
                                <a href="{{$customerAppVersionControlForIos['app_url']}}" target="_blank"
                                   class="cmn--btn h-50 d-flex gap-2 lh-1">
                                    {{translate('Download User App')}}
                                </a>
                            @endif



                            @if($driverAppVersionControlForAndroid && $driverAppVersionControlForIos)
                                <div class="dropdown py-0">
                                    <a href="#"
                                       class="cmn--btn btn-white text-nowrap overflow-hidden text-truncate h-50 d-flex gap-2 lh-1"
                                       data-bs-toggle="dropdown">{{translate('Earn_From')}} {{ $businessName ?? "JAGO" }}
                                        <i
                                            class="bi bi-chevron-down"></i></a>
                                    <div class="dropdown-menu dropdown-button-menu">
                                        <ul>
                                            <li class="border-bottom">
                                                <a href="{{$driverAppVersionControlForAndroid['app_url']}}"
                                                   target="_blank">
                                                    <img width="20" class="w-20px"
                                                         src="{{ dynamicAsset(path: 'public/landing-page/assets/img/play-fav.png') }}"
                                                         alt="">
                                                    <span>{{translate('Play Store')}}</span>
                                                </a>
                                            </li>
                                            <li>
                                                <a href="{{$driverAppVersionControlForIos['app_url']}}"
                                                   target="_blank">
                                                    <img width="20" class="w-20px"
                                                         src="{{ dynamicAsset(path: 'public/landing-page/assets/img/apple.png') }}"
                                                         alt="">
                                                    <span>{{translate('App Store')}}</span>
                                                </a>
                                            </li>
                                        </ul>
                                    </div>
                                </div>
                            @elseif($driverAppVersionControlForAndroid)
                                <a href="{{$driverAppVersionControlForAndroid['app_url']}}" target="_blank"
                                   class="cmn--btn btn-white text-nowrap overflow-hidden text-truncate h-50">
                                    {{translate('Earn_From')}} {{ $businessName ?? "JAGO" }}
                                </a>
                            @elseif($driverAppVersionControlForIos)
                                <a href="{{$driverAppVersionControlForIos['app_url']}}" target="_blank"
                                   class="cmn--btn btn-white text-nowrap overflow-hidden text-truncate h-50">
                                    {{translate('Earn_From')}} {{ $businessName ?? "JAGO" }}
                                </a>
                            @endif
                        </div>
                    @endif
                </div>
            </div>
        </div>
    </section>
    <!-- Intro Section End -->

    <!-- Business Statistics Section Start -->
    @if($showBusinessStatisticsSection)
        <section class="basic-info-section">
            <div class="container position-relative">
                <div class="basic-info-wrapper wow animate__fadeInUp">
                    @foreach($businessStatistics as $key => $item)
                        @if($item?->value && $item?->value['status'] ?? 0)
                            <div
                                class="basic-info-item d-flex align-items-center justify-content-center justify-content-lg-start">
                                <img
                                    src="{{ $item?->value['image']  ? dynamicStorage(path: 'storage/app/public/business/landing-pages/business-statistics/'. str_replace('_', '-', $item?->key_name) .  '/' .$item?->value['image']) : dynamicAsset(path: 'public/landing-page/assets/img/icons/' . $key + 1 . '.png') }}"
                                    alt="">
                                <div class="content text-center text-lg-start">
                                    <h2 class="h5 fw-bold mb-3 fs-14-mobile line-clamp-1">{!! change_text_color_or_bg($item?->value['title'] ??  "1M+" ) !!}</h2>
                                    <p class="fs-16 fs-12-mobile line-clamp-2">{!! change_text_color_or_bg($item?->value['content'] ?? translate("Deliveries Completed")) !!}</p>
                                </div>
                            </div>
                        @endif
                    @endforeach
                </div>
            </div>
        </section>
    @endif
    <!-- Business Statistics Section End -->

    <!-- Why JAGO Section Start -->
    <section class="why-jago-section">
        <div class="container">
            <div class="mb-4 mb-sm-5 text-center">
                <h2 class="section-title mb-2 mb-sm-3 fs-16-mobile wow animate__fadeInUp">{{ translate('Why') }} <span style="color: var(--jago-primary, #2563EB);">{{ $businessName ?? 'JAGO' }}</span></h2>
                <p class="fs-18 mb-0 fs-12-mobile">{{ translate('Everything you need to power your logistics and mobility operations') }}</p>
            </div>
            <div class="row g-4 wow animate__fadeInUp">
                <div class="col-lg-4 col-md-6">
                    <div class="why-jago-card">
                        <div class="icon-circle">
                            <i class="bi bi-geo-alt"></i>
                        </div>
                        <h5>{{ translate('Real-Time Tracking') }}</h5>
                        <p>{{ translate('Track every delivery and vehicle in real time with precise GPS location updates and live status notifications.') }}</p>
                    </div>
                </div>
                <div class="col-lg-4 col-md-6">
                    <div class="why-jago-card">
                        <div class="icon-circle">
                            <i class="bi bi-truck"></i>
                        </div>
                        <h5>{{ translate('Smart Fleet Management') }}</h5>
                        <p>{{ translate('Optimize routes, monitor driver performance, and manage your entire fleet from a single powerful dashboard.') }}</p>
                    </div>
                </div>
                <div class="col-lg-4 col-md-6">
                    <div class="why-jago-card">
                        <div class="icon-circle">
                            <i class="bi bi-box-seam"></i>
                        </div>
                        <h5>{{ translate('Parcel Delivery') }}</h5>
                        <p>{{ translate('Fast and reliable parcel delivery with custom fare setup, weight-based pricing, and instant booking.') }}</p>
                    </div>
                </div>
                <div class="col-lg-4 col-md-6">
                    <div class="why-jago-card">
                        <div class="icon-circle">
                            <i class="bi bi-car-front"></i>
                        </div>
                        <h5>{{ translate('Ride Sharing') }}</h5>
                        <p>{{ translate('Comfortable and affordable rides at your fingertips. Book instantly and travel to any destination with ease.') }}</p>
                    </div>
                </div>
                <div class="col-lg-4 col-md-6">
                    <div class="why-jago-card">
                        <div class="icon-circle">
                            <i class="bi bi-shield-check"></i>
                        </div>
                        <h5>{{ translate('Secure Payments') }}</h5>
                        <p>{{ translate('Multiple secure payment options including digital wallets, cards, and cash on delivery for every transaction.') }}</p>
                    </div>
                </div>
                <div class="col-lg-4 col-md-6">
                    <div class="why-jago-card">
                        <div class="icon-circle">
                            <i class="bi bi-headset"></i>
                        </div>
                        <h5>{{ translate('24/7 Support') }}</h5>
                        <p>{{ translate('Round-the-clock customer support to ensure smooth operations and quick resolution of any issues.') }}</p>
                    </div>
                </div>
            </div>
        </div>
    </section>
    <!-- Why JAGO Section End -->

    <!-- How It Works - Logistics Flow Section Start -->
    <section class="how-it-works-section mt-4 mt-sm-60" id="jago-flow">
        <div class="container">
            <div class="text-center mb-4 mb-sm-5 wow animate__fadeInUp">
                <span class="jago-section-badge">{{ translate('How It Works') }}</span>
                <h2 class="jago-section-heading mt-3">{{ translate('Your Parcel,') }} <span class="text-gradient">{{ translate('Delivered Safely') }}</span></h2>
                <p class="jago-section-sub mx-auto">{{ translate('From booking to doorstep delivery — see how JAGO makes logistics simple, fast, and secure.') }}</p>
            </div>

            <div class="jago-flow-scene wow animate__fadeInUp">
                <div class="jago-flow-connector">
                    <svg class="jago-flow-svg" viewBox="0 0 1100 120" preserveAspectRatio="none">
                        <path class="jago-flow-path" d="M80,60 C200,60 200,60 300,60 C400,60 400,60 550,60 C700,60 700,60 800,60 C900,60 900,60 1020,60" fill="none" stroke="#DBEAFE" stroke-width="3" stroke-dasharray="8,6"/>
                        <path class="jago-flow-path-active" d="M80,60 C200,60 200,60 300,60 C400,60 400,60 550,60 C700,60 700,60 800,60 C900,60 900,60 1020,60" fill="none" stroke="url(#jagoGrad)" stroke-width="3"/>
                        <defs><linearGradient id="jagoGrad" x1="0%" y1="0%" x2="100%" y2="0%">
                            <stop offset="0%" style="stop-color:#2563EB"/>
                            <stop offset="50%" style="stop-color:#3B82F6"/>
                            <stop offset="100%" style="stop-color:#10B981"/>
                        </linearGradient></defs>
                    </svg>
                </div>

                <div class="jago-flow-nodes">
                    <div class="jago-flow-node" data-step="1">
                        <div class="jago-node-visual">
                            <div class="jago-node-phone">
                                <div class="jago-phone-screen">
                                    <div class="jago-phone-header"><span>JAGO</span></div>
                                    <div class="jago-phone-map">
                                        <i class="bi bi-geo-alt-fill"></i>
                                    </div>
                                    <div class="jago-phone-btn">{{ translate('Book Now') }}</div>
                                </div>
                            </div>
                            <div class="jago-node-badge">1</div>
                        </div>
                        <h5>{{ translate('Book on App') }}</h5>
                        <p>{{ translate('Enter pickup & drop location, select vehicle, confirm booking') }}</p>
                    </div>

                    <div class="jago-flow-node" data-step="2">
                        <div class="jago-node-visual">
                            <div class="jago-node-rider">
                                <div class="jago-rider-bike">
                                    <i class="bi bi-bicycle"></i>
                                </div>
                                <div class="jago-rider-parcel">
                                    <i class="bi bi-box-seam-fill"></i>
                                </div>
                            </div>
                            <div class="jago-node-badge">2</div>
                        </div>
                        <h5>{{ translate('Pilot Picks Up') }}</h5>
                        <p>{{ translate('Nearest Pilot arrives, collects parcel with OTP verification') }}</p>
                    </div>

                    <div class="jago-flow-node" data-step="3">
                        <div class="jago-node-visual">
                            <div class="jago-node-tracking">
                                <div class="jago-tracking-map">
                                    <div class="jago-tracking-route"></div>
                                    <div class="jago-tracking-dot jago-dot-start"><i class="bi bi-circle-fill"></i></div>
                                    <div class="jago-tracking-dot jago-dot-moving"><i class="bi bi-truck"></i></div>
                                    <div class="jago-tracking-dot jago-dot-end"><i class="bi bi-geo-alt-fill"></i></div>
                                </div>
                            </div>
                            <div class="jago-node-badge">3</div>
                        </div>
                        <h5>{{ translate('Live Tracking') }}</h5>
                        <p>{{ translate('Real-time GPS tracking on map with status notifications') }}</p>
                    </div>

                    <div class="jago-flow-node" data-step="4">
                        <div class="jago-node-visual">
                            <div class="jago-node-delivered">
                                <div class="jago-delivered-check">
                                    <i class="bi bi-patch-check-fill"></i>
                                </div>
                                <div class="jago-delivered-otp">
                                    <span>OTP</span>
                                    <div class="jago-otp-dots">
                                        <span></span><span></span><span></span><span></span>
                                    </div>
                                </div>
                            </div>
                            <div class="jago-node-badge jago-badge-success">4</div>
                        </div>
                        <h5>{{ translate('Delivered & Verified') }}</h5>
                        <p>{{ translate('Receiver OTP verified, payment processed automatically') }}</p>
                    </div>
                </div>
            </div>

            <div class="flow-features-bar mt-4 mt-sm-5 wow animate__fadeInUp">
                <div class="flow-feature-item">
                    <div class="flow-feature-icon"><i class="bi bi-lightning-charge-fill"></i></div>
                    <span>{{ translate('30 Min Avg Delivery') }}</span>
                </div>
                <div class="flow-feature-item">
                    <div class="flow-feature-icon"><i class="bi bi-shield-lock-fill"></i></div>
                    <span>{{ translate('OTP Secured') }}</span>
                </div>
                <div class="flow-feature-item">
                    <div class="flow-feature-icon"><i class="bi bi-pin-map-fill"></i></div>
                    <span>{{ translate('Live GPS Tracking') }}</span>
                </div>
                <div class="flow-feature-item">
                    <div class="flow-feature-icon"><i class="bi bi-cash-coin"></i></div>
                    <span>{{ translate('Transparent Pricing') }}</span>
                </div>
            </div>
        </div>
    </section>
    <!-- How It Works Section End -->

    <!-- Our Solution Section Start -->
    @if($showOurSolutionsSection)
        <section class="jago-solutions-section mt-4 mt-sm-60">
            <div class="container">
                <div class="text-center mb-5 wow animate__fadeInUp">
                    <span class="jago-section-badge">{{ translate('What We Offer') }}</span>
                    <h2 class="jago-section-heading mt-3">{{ translate('Our') }} <span class="text-gradient">{{ translate('Solutions') }}</span></h2>
                    <p class="jago-section-sub mx-auto">{{ translate('End-to-end logistics and mobility solutions built for speed, reliability, and scale.') }}</p>
                </div>

                    <div class="row g-4 wow animate__fadeInUp">
                        <div class="col-lg-4 col-md-6">
                            <div class="jago-solution-card">
                                <div class="jago-solution-icon-wrap">
                                    <i class="bi bi-box-seam"></i>
                                </div>
                                <div class="jago-solution-body">
                                    <h4 class="jago-solution-title">{{ translate('Parcel Delivery') }}</h4>
                                    <p class="jago-solution-desc">{{ translate('Send parcels anywhere with real-time tracking, weight-based pricing, and OTP-verified handoffs. Fast, reliable, and transparent.') }}</p>
                                    <div class="jago-solution-features">
                                        <span><i class="bi bi-check-circle-fill"></i> {{ translate('Real-time Tracking') }}</span>
                                        <span><i class="bi bi-check-circle-fill"></i> {{ translate('OTP Verified') }}</span>
                                        <span><i class="bi bi-check-circle-fill"></i> {{ translate('Weight-based Pricing') }}</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-lg-4 col-md-6">
                            <div class="jago-solution-card">
                                <div class="jago-solution-icon-wrap">
                                    <i class="bi bi-car-front"></i>
                                </div>
                                <div class="jago-solution-body">
                                    <h4 class="jago-solution-title">{{ translate('Ride Sharing') }}</h4>
                                    <p class="jago-solution-desc">{{ translate('Book rides instantly with smart route matching, fare estimation, and safe travel. Affordable commuting made simple.') }}</p>
                                    <div class="jago-solution-features">
                                        <span><i class="bi bi-check-circle-fill"></i> {{ translate('Instant Booking') }}</span>
                                        <span><i class="bi bi-check-circle-fill"></i> {{ translate('Fare Estimation') }}</span>
                                        <span><i class="bi bi-check-circle-fill"></i> {{ translate('Driver Tracking') }}</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-lg-4 col-md-6">
                            <div class="jago-solution-card">
                                <div class="jago-solution-icon-wrap">
                                    <i class="bi bi-calendar-check"></i>
                                </div>
                                <div class="jago-solution-body">
                                    <h4 class="jago-solution-title">{{ translate('Scheduled Trips') }}</h4>
                                    <p class="jago-solution-desc">{{ translate('Plan ahead with pre-scheduled rides and deliveries. Set your time, date, and destination — we handle the rest.') }}</p>
                                    <div class="jago-solution-features">
                                        <span><i class="bi bi-check-circle-fill"></i> {{ translate('Advance Booking') }}</span>
                                        <span><i class="bi bi-check-circle-fill"></i> {{ translate('Flexible Timing') }}</span>
                                        <span><i class="bi bi-check-circle-fill"></i> {{ translate('Auto Reminders') }}</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-lg-4 col-md-6">
                            <div class="jago-solution-card">
                                <div class="jago-solution-icon-wrap">
                                    <i class="bi bi-building"></i>
                                </div>
                                <div class="jago-solution-body">
                                    <h4 class="jago-solution-title">{{ translate('Business Logistics') }}</h4>
                                    <p class="jago-solution-desc">{{ translate('Scalable fleet management for businesses. Route optimization, driver management, and analytics all in one dashboard.') }}</p>
                                    <div class="jago-solution-features">
                                        <span><i class="bi bi-check-circle-fill"></i> {{ translate('Fleet Dashboard') }}</span>
                                        <span><i class="bi bi-check-circle-fill"></i> {{ translate('Route Optimization') }}</span>
                                        <span><i class="bi bi-check-circle-fill"></i> {{ translate('Analytics') }}</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-lg-4 col-md-6">
                            <div class="jago-solution-card">
                                <div class="jago-solution-icon-wrap">
                                    <i class="bi bi-wallet2"></i>
                                </div>
                                <div class="jago-solution-body">
                                    <h4 class="jago-solution-title">{{ translate('Digital Payments') }}</h4>
                                    <p class="jago-solution-desc">{{ translate('Seamless and secure payment options including digital wallets, cards, and cash on delivery for every transaction.') }}</p>
                                    <div class="jago-solution-features">
                                        <span><i class="bi bi-check-circle-fill"></i> {{ translate('Multiple Methods') }}</span>
                                        <span><i class="bi bi-check-circle-fill"></i> {{ translate('Wallet System') }}</span>
                                        <span><i class="bi bi-check-circle-fill"></i> {{ translate('Secure & Fast') }}</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-lg-4 col-md-6">
                            <div class="jago-solution-card">
                                <div class="jago-solution-icon-wrap">
                                    <i class="bi bi-geo-alt"></i>
                                </div>
                                <div class="jago-solution-body">
                                    <h4 class="jago-solution-title">{{ translate('Live Navigation') }}</h4>
                                    <p class="jago-solution-desc">{{ translate('Real-time GPS navigation for drivers with optimized routes, turn-by-turn directions, and traffic-aware ETA calculations.') }}</p>
                                    <div class="jago-solution-features">
                                        <span><i class="bi bi-check-circle-fill"></i> {{ translate('GPS Tracking') }}</span>
                                        <span><i class="bi bi-check-circle-fill"></i> {{ translate('Smart Routes') }}</span>
                                        <span><i class="bi bi-check-circle-fill"></i> {{ translate('Live ETA') }}</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
            </div>
        </section>
    @endif
    <!-- Our Solution Section End -->


    <!-- Our Services Section Start -->
    @if($showOurServicesSection)
        <section class="service-section bg-light py-4 py-sm-60 mt-4 mt-sm-60">
            <div class="container">
                <div class="mb-3 mb-sm-5 text-center">
                    <h3 class="section-title mb-2 mb-sm-3 fs-16-mobile wow animate__fadeInUp">
                        {!! $ourServicesSectionContent && $ourServicesSectionContent['title'] ? change_text_color_or_bg($ourServicesSectionContent['title']) :  translate('Our ') .change_text_color_or_bg(('**'. translate('Services') .'**')) !!}
                    </h3>
                    <p class="fs-18 mb-0 fs-12-mobile">{!! $ourServicesSectionContent && $ourServicesSectionContent['subtitle'] ? change_text_color_or_bg($ourServicesSectionContent['subtitle']) :  translate('Discover our innovative solutions designed to enhance daily operations.') !!}</p>
                </div>
                <ul class="nav nav-tabs nav--tabs" id="myTab" role="tablist">
                    @foreach($activeOurServices as $key => $ourService)
                        <li class="nav-item" role="presentation">
                            <button class="nav-link {{$key == 0 ? "active" : ""}}" id="areaTab{{$key}}"
                                    data-bs-toggle="tab" data-bs-target="#tab{{$key}}" type="button" role="tab"
                                    aria-controls="tab{{$key}}" aria-selected="true">
                                {!! change_text_color_or_bg($ourService?->value['tab_name']) !!}
                            </button>
                        </li>
                    @endforeach
                </ul>
                <div class="tab-content" id="myTabContent">
                    @foreach($activeOurServices as $key => $ourService)
                        @if($ourService?->value['status']??0)
                            <div class="tab-pane fade {{$key == 0 ? "show active" : ""}}" id="tab{{$key}}"
                                 role="tabpanel" aria-labelledby="areaTab{{$key}}">
                                <div class="row g-4">
                                    <div class="col-lg-6">
                                        <div class="mt-3 mt-sm-5">
                                            <h4 class="mb-3 fs-16-mobile">
                                                {!! change_text_color_or_bg($ourService?->value['title']) !!}
                                            </h4>
                                            <div class="editor-content">
                                                {!! change_text_color_or_bg($ourService?->value['description']) !!}
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-lg-6">
                                        <div class="w-475 w-220-mobile aspect-1 mx-auto overflow-hidden rounded">
                                            <img
                                                class="img-fluid w-100 h-100 object-cover"
                                                src="{{ $ourService?->value['image'] ? dynamicStorage(path: 'storage/app/public/business/landing-pages/our-services/' .$ourService?->value['image']) : dynamicAsset(path: 'public/landing-page/assets/img/service/demo.png') }}"
                                                alt=""
                                            >
                                        </div>
                                    </div>
                                </div>
                            </div>
                        @endif
                    @endforeach

                </div>
            </div>
        </section>

    @endif
    <!-- Our Services Section End -->

    <!-- Gallery Section Start -->
    @if($isGalleryEnabled)
        <section class="gallery-section p-0 mt-4 mt-sm-60">
            <div class="container">
                <div class="row g-4 pb-50">
                    <div class="col-lg-6">
                        <div class="h-100">
                            <div
                                class="w-100 h-345 h-200-mobile mx-auto overflow-hidden rounded-20 wow animate__fadeInDown">
                                <img
                                    class="img-fluid w-100 h-100 object-cover"
                                    src="{{$cardOneGallery['image'] ? dynamicStorage('storage/app/public/business/landing-pages/gallery/' .$cardOneGallery['image']) : dynamicAsset(path: 'public/landing-page/assets/img/gallery/card-1.png') }}"
                                    alt=""
                                >
                            </div>
                            <div class="mt-4 mt-sm-30">
                                <h3 class="mb-3 mb-sm-4 fs-16-mobile wow animate__fadeInUp">
                                    {!! $cardOneGallery['title'] ?  change_text_color_or_bg($cardOneGallery['title']) : translate('Deliveries Completed ') .change_text_color_or_bg(('**'. translate('On Time, Every Time') .'**'))  !!}
                                </h3>
                                <p class="fs-16 mb-0 fs-12-mobile wow animate__fadeInUp">
                                    {!! $cardOneGallery['subtitle'] ? change_text_color_or_bg($cardOneGallery['subtitle']) : translate('From pickup to drop-off, we ensure your parcels arrive safely and on schedule. Reliable logistics you can count on.') !!}
                                </p>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-6">
                        <div class="h-100">
                            <div class="mb-4 mb-sm-30">
                                <h3 class="mb-3 mb-sm-4 fs-16-mobile wow animate__fadeInUp">
                                    {!! $cardTwoGallery['title'] ? change_text_color_or_bg($cardTwoGallery['title'])  : translate("Smart Fleet Solutions") !!}
                                </h3>
                                <p class="fs-16 mb-0 fs-12-mobile wow animate__fadeInUp">
                                    {!!$cardTwoGallery['subtitle'] ? change_text_color_or_bg($cardTwoGallery['subtitle']) : translate('Manage your entire fleet with real-time GPS tracking, route optimization, and performance analytics — all in one platform.') !!}
                                </p>
                            </div>
                            <div
                                class="w-100 h-345 h-200-mobile mx-auto overflow-hidden rounded-20 wow animate__fadeInDown">
                                <img
                                    class="img-fluid w-100 h-100 object-cover"
                                    src="{{ $cardTwoGallery['image'] ?  dynamicStorage('storage/app/public/business/landing-pages/gallery/' .$cardTwoGallery['image']) : dynamicAsset(path: 'public/landing-page/assets/img/gallery/card-2.png') }}"
                                    alt=""
                                >
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    @endif
    <!-- Gallery Section End -->

    <!-- App Download Section Start -->
    @if($isCustomerAppDownloadEnabled)
        <section class="app-download-section p-0 mt-4 mt-sm-60">
            <div class="container">
                <div class="row g-4 align-items-center">
                    <div class="col-lg-6">
                        <div class="wow animate__fadeInDown">
                            <div class="mb-4 mb-sm-30">
                                <h3 class="mb-3 mb-sm-4 fs-16-mobile">
                                    {!! change_text_color_or_bg($customerAppDownloadSectionContent['title'])  !!}
                                </h3>
                                <p class="fs-16 mb-0 fs-12-mobile">
                                    {!! change_text_color_or_bg($customerAppDownloadSectionContent['subtitle']) !!}
                                </p>
                            </div>
                            <div
                                class="bg-fafafa border rounded-20 p-3 p-sm-4 d-flex justify-content-between align-items-center gap-3 gap-sm-4 w-auto">
                                <div>
                                    <h5 class="mb-2 fs-16-mobile">{!! change_text_color_or_bg($customerAppDownloadButtonContent['title']) !!}</h5>
                                    <p class="mb-0">{!! change_text_color_or_bg($customerAppDownloadButtonContent['subtitle']) !!}</p>
                                    <div class="d-flex gap-3 mt-3">
                                        @if($customerAppVersionControlForAndroid)
                                            <a target="_blank" class="no-gutter" type="button"
                                               href="{{ $customerAppVersionControlForAndroid['app_url'] }}">
                                                <img
                                                    src="{{ dynamicAsset(path: 'public/landing-page/assets/img/play-store.png') }}"
                                                    class="w-125px" alt="">
                                            </a>
                                        @endif
                                        @if($customerAppVersionControlForIos)
                                            <a target="_blank" class="no-gutter" type="button"
                                               href="{{ $customerAppVersionControlForIos['app_url'] }}">
                                                <img
                                                    src="{{ dynamicAsset(path: 'public/landing-page/assets/img/app-store.png') }}"
                                                    class="w-125px" alt="">
                                            </a>
                                        @endif
                                    </div>
                                </div>
                                <div
                                    class="bg-white rounded-10 p-3 d-flex justify-content-center align-items-center flex-column gap-2 h-100">
                                    <div class="border rounded-10 p-2">
                                        {!! \QrCode::size(64)->generate(route('blog.customer-app-download')) !!}
                                    </div>
                                    <p class="fs-12-mobile mb-0">{{ translate('Scan to DownLoad') }}</p>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-6">
                        <div class="w-475 w-220-mobile aspect-1 mx-auto overflow-hidden rounded wow animate__fadeInUp">
                            <img
                                class="img-fluid w-100 h-100 object-cover"
                                src="{{ $customerAppDownloadSectionContent['image'] ? dynamicStorage('storage/app/public/business/landing-pages/customer-app-download/' .$customerAppDownloadSectionContent['image']) : dynamicAsset(path: 'public/landing-page/assets/img/service/demo.png') }}"
                                alt=""
                            >
                        </div>
                    </div>
                </div>
            </div>
        </section>
    @endif
    <!-- App Download Section End -->

    <!-- Earn Money Section Start -->
    @if($isEarnMoneyEnabled)
        <section class="earn-money-section bg-light py-4 py-sm-60 mt-4 mt-sm-60">
            <div class="container">
                <div class="row g-4 align-items-center">
                    <div class="col-lg-6">
                        <div class="w-475 w-220-mobile aspect-1 mx-auto overflow-hidden rounded wow animate__fadeInUp">
                            <img
                                class="img-fluid w-100 h-100 object-cover"
                                src="{{ $earnMoneySectionContent['image'] ? dynamicStorage('storage/app/public/business/landing-pages/earn-money/'.$earnMoneySectionContent['image']) : dynamicAsset(path: 'public/landing-page/assets/img/service/demo.png') }}"
                                alt=""
                            >
                        </div>
                    </div>
                    <div class="col-lg-6">
                        <div class="h-100 wow animate__fadeInDown">
                            <div class="mb-4 mb-sm-30">
                                <h3 class="mb-3 mb-sm-4 fs-16-mobile">
                                    {!! change_text_color_or_bg($earnMoneySectionContent['title'])  !!}
                                </h3>
                                <p class="fs-16 mb-0 fs-12-mobile">
                                    {!! change_text_color_or_bg($earnMoneySectionContent['subtitle']) !!}
                                </p>
                            </div>
                            <div
                                class="bg-fafafa border rounded-20 p-3 p-sm-4 d-flex justify-content-between align-items-center gap-3 gap-sm-4 w-auto">
                                <div>
                                    <h5 class="mb-2 fs-16-mobile">{!! change_text_color_or_bg($earnMoneyButtonContent['title']) !!}</h5>
                                    <p class="mb-0">{!! $earnMoneyButtonContent['subtitle'] !!}</p>
                                    <div class="d-flex gap-3 mt-3">
                                        @if($driverAppVersionControlForAndroid)
                                            <a target="_blank" class="no-gutter" type="button"
                                               href="{{ $driverAppVersionControlForAndroid['app_url'] }}">
                                                <img
                                                    src="{{ dynamicAsset(path: 'public/landing-page/assets/img/app-store.png') }}"
                                                    class="w-125px" alt="">
                                            </a>
                                        @endif
                                        @if($driverAppVersionControlForIos)
                                            <a target="_blank" class="no-gutter" type="button"
                                               href="{{ $driverAppVersionControlForIos['app_url'] }}">
                                                <img
                                                    src="{{ dynamicAsset(path: 'public/landing-page/assets/img/play-store.png') }}"
                                                    class="w-125px" alt="">
                                            </a>
                                        @endif
                                    </div>
                                </div>
                                <div
                                    class="bg-white rounded-10 p-3 d-flex justify-content-center align-items-center flex-column gap-2 h-100">
                                    <div class="border rounded-10 p-2">
                                        {!! \QrCode::size(64)->generate(route('blog.driver-app-download')) !!}
                                    </div>
                                    <p class="fs-12-mobile mb-0">{{ translate('Scan to DownLoad') }}</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    @endif
    <!-- Earn Money Section End -->

@endsection

