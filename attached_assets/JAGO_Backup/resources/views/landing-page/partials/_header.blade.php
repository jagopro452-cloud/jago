@php
    use Modules\BlogManagement\Entities\BlogSetting;
    $logo = getSession('header_logo');
    $isBlogEnabled = BlogSetting::where(['key_name' => 'is_enabled', 'settings_type' => BLOG_PAGE])->first()?->value
@endphp
<header>
    <!-- Header Bottom -->
    <div class="navbar-bottom">
        <div class="container">
            <div class="navbar-bottom-wrapper">
                <a href="{{route('index')}}" class="logo" style="max-width:320px;height:auto;">
                    <img
                            src="{{ $logo ? dynamicStorage(path: "storage/app/public/business/".$logo) : dynamicAsset(path: 'public/jago-logo.png') }}"
                            alt="JAGO" style="width:100%;height:auto;max-height:80px;object-fit:contain;">
                </a>
                <ul class="menu me-lg-4">
                    <li>
                        <a href="{{route('index')}}" class="{{Request::is('/')? 'active' :''}}"><span>Home</span></a>
                    </li>
                    <li>
                        <a href="{{route('about-us')}}"
                           class="{{Request::is('about-us')? 'active' :''}}"><span>{{ translate('About Us') }}</span></a>
                    </li>
                    @if($isBlogEnabled)
                        <li>
                            <a href="{{route('blog.index')}}"
                               class="{{Request::is('blog')? 'active' :''}}"><span>{{ translate('Blog') }}</span></a>
                        </li>
                    @endif
                    <li>
                        <a href="{{route('privacy')}}"
                           class="{{Request::is('privacy') ? 'active' :''}}"><span>{{ translate('Privacy Policy') }}</span></a>
                    </li>
                    <li>
                        <a href="{{route('terms')}}"
                           class="{{Request::is('terms')? 'active' :''}}"><span>{{ translate('Terms & Condition') }}</span></a>
                    </li>

                    <li class="d-sm-none">
                        <a href="{{route('contact-us')}}"
                           class="cmn--btn px-4 w-unset text-white d-inline-flex {{Request::is('contact-us')? 'active' :''}}"><span>Contact
                                Us</span></a>
                    </li>
                </ul>
                <div class="nav-toggle d-lg-none ms-auto me-2 me-sm-4">
                    <span></span>
                    <span></span>
                    <span></span>
                </div>
                <a href="{{route('contact-us')}}"
                   class="cmn--btn d-none d-sm-block {{Request::is('contact-us')? 'active' :''}}">{{ translate('Contact Us') }}</a>
            </div>
        </div>
    </div>
    <!-- Header Bottom -->
</header>
