<!-- Newsletters Section Start -->
@if(landingPageConfig(key: 'is_newsletter_enabled',settingsType: NEWSLETTER)?->value == 1 )
    @php($newsLetter = landingPageConfig(key: INTRO_CONTENTS,settingsType: NEWSLETTER)?->value ?? null)
    <section class="newsletter-section p-0 mt-4 mt-sm-60">
        <div class="container">
            <div class="newsletter--wrapper bg__img"
                 data-img="{{ $newsLetter && $newsLetter['background_image'] ? dynamicStorage('storage/app/public/business/landing-pages/newsletter/'.$newsLetter['background_image']) :dynamicAsset(path: 'public/landing-page/assets/img/newsletter-new-bg.png') }}">
                <div class="position-relative p-4 p-sm-5">
                    <div class="row g-4 align-items-center">
                        <div class="col-lg-8">
                            <div class="wow animate__fadeInDown">
                                <h4 class="text-white text-uppercase mb-2 fs-16-mobile">{!! $newsLetter && $newsLetter['title'] ? change_text_color_or_bg($newsLetter['title']) :  translate('GET ALL UPDATES & EXCITING NEWS') !!}</h4>
                                <p class="text-white opacity-75 lh-base fs-12-mobile">{!! $newsLetter && $newsLetter['subtitle'] ? change_text_color_or_bg($newsLetter['subtitle']) :translate('Subscribe to out newsletters to receive all the latest activity we provide for you') !!}</p>
                            </div>
                        </div>
                        <div class="col-lg-4">
                            <div class="wow animate__fadeInUp">
                                <div class="newsletter-right">
                                    <form action="{{ route('newsletter-subscription.store') }}" method="POST" class="newsletter-form">
                                        @csrf
                                        <input type="email" class="form-control"
                                               placeholder="{{ translate('Type email...') }}" name="email" autocomplete="off" required>
                                        <button type="submit"
                                                class="btn cmn--btn">{{ translate('Subscribe ') }}</button>
                                    </form>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
@endif
<!-- Newsletters Section End -->

<footer class="jago-footer mt-4 mt-sm-60">
    @php($logo = getSession('header_logo'))
    @php($footerLogo = getSession('footer_logo'))
    @php($email = getSession('business_contact_email'))
    @php($contactNumber = getSession('business_contact_phone'))
    @php($businessAddress = getSession('business_address'))
    @php($businessName = getSession('business_name'))
    @php($footerContent = landingPageConfig(key: 'footer_contents', settingsType: FOOTER)?->value ?? null)
    @php($links = \Modules\BusinessManagement\Entities\SocialLink::where(['is_active'=>1])->orderBy('name','asc')->get())
    @php($driverAppVersionControlForAndroid = businessConfig(key: DRIVER_APP_VERSION_CONTROL_FOR_ANDROID, settingsType: APP_VERSION)?->value ?? null)
    @php($driverAppVersionControlForIos = businessConfig(key: DRIVER_APP_VERSION_CONTROL_FOR_IOS, settingsType: APP_VERSION)?->value ?? null)
    @php($customerAppVersionControlForAndroid = businessConfig(key: CUSTOMER_APP_VERSION_CONTROL_FOR_ANDROID, settingsType: APP_VERSION)?->value ?? null)
    @php($customerAppVersionControlForIos = businessConfig(key: CUSTOMER_APP_VERSION_CONTROL_FOR_IOS, settingsType: APP_VERSION)?->value ?? null)

    <div class="footer-top">
        <div class="container">
            <div class="row g-4 g-lg-5">
                <div class="col-lg-4 col-md-6">
                    <div class="footer-brand">
                        <a href="{{ route('index') }}" class="footer-logo d-inline-block mb-3">
                            <img
                                src="{{ $footerLogo ? dynamicStorage(path: "storage/app/public/business/".$footerLogo) : dynamicAsset(path: 'public/jago-logo.png') }}"
                                alt="JAGO Logo" class="footer-logo-img">
                        </a>
                        <p class="footer-desc">
                            {!! $footerContent && $footerContent['title'] ? change_text_color_or_bg($footerContent['title']) : translate('Your trusted logistics and mobility platform. Delivering parcels, connecting rides, and powering seamless transportation — anytime, anywhere.')!!}
                        </p>
                        <div class="footer-social">
                            @foreach($links as $link)
                                @if($link->name == "facebook")
                                    <a href="{{$link->link}}" target="_blank" class="social-link" title="Facebook">
                                        <i class="bi bi-facebook"></i>
                                    </a>
                                @elseif($link->name == "instagram")
                                    <a href="{{$link->link}}" target="_blank" class="social-link" title="Instagram">
                                        <i class="bi bi-instagram"></i>
                                    </a>
                                @elseif($link->name == "twitter")
                                    <a href="{{$link->link}}" target="_blank" class="social-link" title="Twitter">
                                        <i class="bi bi-twitter-x"></i>
                                    </a>
                                @elseif($link->name == "linkedin")
                                    <a href="{{$link->link}}" target="_blank" class="social-link" title="LinkedIn">
                                        <i class="bi bi-linkedin"></i>
                                    </a>
                                @endif
                            @endforeach
                            @if($links->isEmpty())
                                <a href="#" class="social-link" title="Facebook"><i class="bi bi-facebook"></i></a>
                                <a href="#" class="social-link" title="Twitter"><i class="bi bi-twitter-x"></i></a>
                                <a href="#" class="social-link" title="Instagram"><i class="bi bi-instagram"></i></a>
                                <a href="#" class="social-link" title="LinkedIn"><i class="bi bi-linkedin"></i></a>
                            @endif
                        </div>
                    </div>
                </div>

                <div class="col-lg-2 col-md-3 col-6">
                    <div class="footer-widget">
                        <h6 class="footer-widget-title">{{ translate('Quick Links') }}</h6>
                        <ul class="footer-links">
                            <li><a href="{{ route('index') }}">{{ translate('Home') }}</a></li>
                            <li><a href="{{ route('about-us') }}">{{ translate('About Us') }}</a></li>
                            <li><a href="{{ route('contact-us') }}">{{ translate('Contact Us') }}</a></li>
                        </ul>
                    </div>
                </div>

                <div class="col-lg-2 col-md-3 col-6">
                    <div class="footer-widget">
                        <h6 class="footer-widget-title">{{ translate('Legal') }}</h6>
                        <ul class="footer-links">
                            <li><a href="{{ route('privacy') }}">{{ translate('Privacy Policy') }}</a></li>
                            <li><a href="{{ route('terms') }}">{{ translate('Terms & Conditions') }}</a></li>
                        </ul>
                    </div>
                </div>

                <div class="col-lg-4 col-md-6">
                    <div class="footer-widget">
                        <h6 class="footer-widget-title">{{ translate('Get In Touch') }}</h6>
                        <div class="footer-contact-list">
                            <div class="footer-contact-item">
                                <div class="footer-contact-icon">
                                    <i class="bi bi-envelope"></i>
                                </div>
                                <div>
                                    <span class="footer-contact-label">{{ translate('Email') }}</span>
                                    <a href="mailto:{{ $email ?: 'support@jagoapp.in' }}" class="footer-contact-value">{{ $email ?: 'support@jagoapp.in' }}</a>
                                </div>
                            </div>
                            <div class="footer-contact-item">
                                <div class="footer-contact-icon">
                                    <i class="bi bi-telephone"></i>
                                </div>
                                <div>
                                    <span class="footer-contact-label">{{ translate('Phone') }}</span>
                                    <a href="tel:{{ $contactNumber ?: '+91-9876543210' }}" class="footer-contact-value">{{ $contactNumber ?: '+91-9876543210' }}</a>
                                </div>
                            </div>
                            <div class="footer-contact-item">
                                <div class="footer-contact-icon">
                                    <i class="bi bi-geo-alt"></i>
                                </div>
                                <div>
                                    <span class="footer-contact-label">{{ translate('Address') }}</span>
                                    <span class="footer-contact-value">{{ $businessAddress ?: 'Hyderabad, Telangana, India' }}</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            @if($customerAppVersionControlForAndroid || $customerAppVersionControlForIos || $driverAppVersionControlForAndroid || $driverAppVersionControlForIos)
                <div class="footer-apps-row">
                    @if($customerAppVersionControlForAndroid || $customerAppVersionControlForIos)
                        <div class="footer-app-group">
                            <span class="footer-app-label">{{ translate('Customer App') }}</span>
                            <div class="d-flex gap-2 flex-wrap">
                                @if($customerAppVersionControlForAndroid)
                                    <a target="_blank" href="{{ $customerAppVersionControlForAndroid['app_url'] }}">
                                        <img src="{{ dynamicAsset(path: 'public/landing-page/assets/img/play-store.png') }}" class="footer-store-badge" alt="Play Store">
                                    </a>
                                @endif
                                @if($customerAppVersionControlForIos)
                                    <a target="_blank" href="{{ $customerAppVersionControlForIos['app_url'] }}">
                                        <img src="{{ dynamicAsset(path: 'public/landing-page/assets/img/app-store.png') }}" class="footer-store-badge" alt="App Store">
                                    </a>
                                @endif
                            </div>
                        </div>
                    @endif
                    @if($driverAppVersionControlForAndroid || $driverAppVersionControlForIos)
                        <div class="footer-app-group">
                            <span class="footer-app-label">{{ translate('Driver App') }}</span>
                            <div class="d-flex gap-2 flex-wrap">
                                @if($driverAppVersionControlForAndroid)
                                    <a target="_blank" href="{{ $driverAppVersionControlForAndroid['app_url'] }}">
                                        <img src="{{ dynamicAsset(path: 'public/landing-page/assets/img/play-store.png') }}" class="footer-store-badge" alt="Play Store">
                                    </a>
                                @endif
                                @if($driverAppVersionControlForIos)
                                    <a target="_blank" href="{{ $driverAppVersionControlForIos['app_url'] }}">
                                        <img src="{{ dynamicAsset(path: 'public/landing-page/assets/img/app-store.png') }}" class="footer-store-badge" alt="App Store">
                                    </a>
                                @endif
                            </div>
                        </div>
                    @endif
                </div>
            @endif
        </div>
    </div>
    <div class="footer-bottom text-center">
        <div class="container">
            {{ getSession('copyright_text') ?: '© ' . date('Y') . ' JAGO. A product of Mindwhile IT Solutions Pvt Ltd. All rights reserved.' }}
        </div>
    </div>
</footer>
