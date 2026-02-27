<!DOCTYPE html>
<html lang="en" dir="{{ session()->get('direction') ?? 'ltr' }}">

<head>
    @php($logo = getSession('header_logo'))
    @php($favicon = getSession('favicon'))
    @php($preloader = getSession('preloader'))
    <title>{{ translate('admin_login') }}</title>
    <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
    <meta http-equiv="content-type" content="text/html; charset=utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <link rel="shortcut icon" href="{{ $favicon ? dynamicStorage('storage/app/public/business/' . $favicon) : '' }}"/>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="{{ dynamicAsset('public/assets/admin-module/css/bootstrap.min.css') }}"/>
    <link rel="stylesheet" href="{{ dynamicAsset('public/assets/admin-module/css/bootstrap-icons.min.css') }}"/>
    <link rel="stylesheet" href="{{ dynamicAsset('public/assets/admin-module/css/toastr.css') }}"/>
    <link rel="stylesheet" href="{{ dynamicAsset('public/assets/admin-module/css/style.css') }}"/>
    <link rel="stylesheet" href="{{ dynamicAsset('public/assets/admin-module/css/custom.css') }}"/>
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            min-height: 100vh;
            background: #F0F4F8;
            -webkit-font-smoothing: antialiased;
            overflow-x: hidden;
        }
        .login-container {
            display: flex;
            min-height: 100vh;
        }
        .login-brand-side {
            flex: 0 0 45%;
            max-width: 45%;
            background: linear-gradient(160deg, #0F1B3D 0%, #1E3A8A 35%, #2563EB 70%, #3B82F6 100%);
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            padding: 3rem;
            position: relative;
            overflow: hidden;
        }
        .login-brand-side::before {
            content: '';
            position: absolute;
            top: -30%;
            right: -20%;
            width: 500px;
            height: 500px;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.03);
        }
        .login-brand-side::after {
            content: '';
            position: absolute;
            bottom: -20%;
            left: -15%;
            width: 400px;
            height: 400px;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.02);
        }
        .brand-content {
            position: relative;
            z-index: 2;
            text-align: center;
            max-width: 400px;
        }
        .brand-logo {
            max-width: 220px;
            height: auto;
            margin-bottom: 2.5rem;
            filter: brightness(0) invert(1);
            opacity: 0.95;
        }
        .brand-tagline {
            color: rgba(255, 255, 255, 0.95);
            font-size: 1.75rem;
            font-weight: 300;
            line-height: 1.4;
            letter-spacing: -0.02em;
        }
        .brand-tagline strong {
            font-weight: 700;
            color: #fff;
        }
        .brand-features {
            margin-top: 3rem;
            display: flex;
            flex-direction: column;
            gap: 1rem;
        }
        .brand-feature {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            color: rgba(255, 255, 255, 0.75);
            font-size: 0.875rem;
            font-weight: 400;
        }
        .brand-feature-icon {
            width: 36px;
            height: 36px;
            border-radius: 10px;
            background: rgba(255, 255, 255, 0.1);
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
            font-size: 1rem;
        }
        .login-form-side {
            flex: 1;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            padding: 2rem;
            background: #fff;
            position: relative;
        }
        .version-badge {
            position: absolute;
            top: 1.5rem;
            right: 1.5rem;
            background: rgba(37, 99, 235, 0.06);
            color: #2563EB;
            padding: 0.3rem 0.8rem;
            border-radius: 20px;
            font-size: 0.7rem;
            font-weight: 600;
            letter-spacing: 0.03em;
        }
        .login-form-wrapper {
            width: 100%;
            max-width: 400px;
        }
        .login-greeting {
            margin-bottom: 2rem;
        }
        .login-greeting h1 {
            font-size: 1.75rem;
            font-weight: 800;
            color: #0F172A;
            margin-bottom: 0.5rem;
            letter-spacing: -0.03em;
        }
        .login-greeting p {
            color: #64748B;
            font-size: 0.9375rem;
            font-weight: 400;
        }
        .form-group {
            margin-bottom: 1.25rem;
        }
        .form-group label {
            display: block;
            font-size: 0.8125rem;
            font-weight: 600;
            color: #334155;
            margin-bottom: 0.5rem;
            letter-spacing: 0.01em;
        }
        .input-wrapper {
            position: relative;
        }
        .input-wrapper .input-icon {
            position: absolute;
            left: 1rem;
            top: 50%;
            transform: translateY(-50%);
            color: #94A3B8;
            font-size: 1rem;
            transition: color 0.2s ease;
            pointer-events: none;
        }
        .form-input {
            width: 100%;
            padding: 0.8rem 1rem 0.8rem 2.75rem;
            border: 1.5px solid #E2E8F0;
            border-radius: 12px;
            font-size: 0.9375rem;
            font-family: inherit;
            color: #1E293B;
            background: #F8FAFC;
            transition: all 0.25s ease;
            outline: none;
        }
        .form-input:focus {
            border-color: #2563EB;
            background: #fff;
            box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.08);
        }
        .form-input:focus + .input-icon,
        .form-input:focus ~ .input-icon {
            color: #2563EB;
        }
        .input-wrapper .toggle-password {
            position: absolute;
            right: 1rem;
            top: 50%;
            transform: translateY(-50%);
            background: none;
            border: none;
            color: #94A3B8;
            cursor: pointer;
            padding: 0;
            font-size: 1.1rem;
            transition: color 0.2s ease;
        }
        .input-wrapper .toggle-password:hover {
            color: #2563EB;
        }
        .remember-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 1.75rem;
        }
        .remember-check {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            cursor: pointer;
        }
        .remember-check input[type="checkbox"] {
            width: 16px;
            height: 16px;
            accent-color: #2563EB;
            cursor: pointer;
            border-radius: 4px;
        }
        .remember-check label {
            font-size: 0.8125rem;
            color: #64748B;
            font-weight: 500;
            cursor: pointer;
            margin: 0;
        }
        .btn-login {
            width: 100%;
            padding: 0.85rem 1.5rem;
            background: linear-gradient(135deg, #2563EB 0%, #1D4ED8 100%);
            color: #fff;
            border: none;
            border-radius: 12px;
            font-size: 0.9375rem;
            font-weight: 600;
            font-family: inherit;
            cursor: pointer;
            transition: all 0.3s ease;
            letter-spacing: 0.02em;
            position: relative;
            overflow: hidden;
        }
        .btn-login:hover {
            background: linear-gradient(135deg, #1D4ED8 0%, #1E40AF 100%);
            box-shadow: 0 8px 24px rgba(37, 99, 235, 0.3);
            transform: translateY(-1px);
        }
        .btn-login:active {
            transform: translateY(0) scale(0.99);
            box-shadow: 0 4px 12px rgba(37, 99, 235, 0.2);
        }
        .login-footer-demo {
            margin-top: 2rem;
            padding: 1rem 1.25rem;
            background: #F0F4FF;
            border-radius: 12px;
            border: 1px solid rgba(37, 99, 235, 0.1);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .login-footer-demo .creds {
            font-size: 0.8125rem;
            color: #475569;
            line-height: 1.6;
        }
        .login-footer-demo .creds span {
            font-weight: 600;
            color: #1E293B;
        }
        .copy-btn {
            width: 38px;
            height: 38px;
            border-radius: 10px;
            background: #2563EB;
            color: #fff;
            border: none;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.2s ease;
            flex-shrink: 0;
        }
        .copy-btn:hover {
            background: #1D4ED8;
            transform: scale(1.05);
        }
        .captcha-row {
            margin-bottom: 1.25rem;
        }
        .captcha-row .row {
            align-items: center;
        }

        .preloader {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: #fff;
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 9999;
        }

        @media (max-width: 991px) {
            .login-brand-side {
                display: none;
            }
            .login-form-side {
                padding: 1.5rem;
            }
            .login-form-wrapper {
                max-width: 380px;
            }
        }
        @media (min-width: 992px) and (max-width: 1200px) {
            .login-brand-side {
                flex: 0 0 40%;
                max-width: 40%;
                padding: 2rem;
            }
            .brand-tagline {
                font-size: 1.5rem;
            }
        }
    </style>
</head>

<body>
<div class="offcanvas-overlay"></div>
<div class="preloader" id="preloader">
    @if ($preloader)
        <img class="preloader-img" loading="eager" width="160"
             src="{{ dynamicStorage('storage/app/public/business/' . $preloader) }}" alt="">
    @else
        <div class="spinner-grow text-primary" role="status">
            <span class="visually-hidden">Loading...</span>
        </div>
    @endif
</div>
<div class="resource-loader d-none" id="resource-loader">
    @if ($preloader)
        <img width="160" loading="eager" src="{{ dynamicStorage('storage/app/public/business/' . $preloader) }}" alt="">
    @else
        <div class="spinner-grow text-primary" role="status">
            <span class="visually-hidden">Loading...</span>
        </div>
    @endif
</div>

<div class="login-container">
    <div class="login-brand-side">
        <div class="brand-content">
            <img class="brand-logo" src="{{ onErrorImage(
                $logo,
                dynamicStorage('storage/app/public/business') . '/' . $logo,
                dynamicAsset('public/jago-logo.png'),
                'business/',
            ) }}" alt="Logo">

            <h2 class="brand-tagline">
                {{ translate('Smart') }} <strong>{{ translate('Logistics') }}</strong> &amp;
                {{ translate('Seamless') }} <strong>{{ translate('Mobility') }}</strong>
            </h2>

            <div class="brand-features">
                <div class="brand-feature">
                    <div class="brand-feature-icon"><i class="bi bi-truck"></i></div>
                    <span>{{ translate('Real-time parcel & delivery tracking') }}</span>
                </div>
                <div class="brand-feature">
                    <div class="brand-feature-icon"><i class="bi bi-geo-alt"></i></div>
                    <span>{{ translate('Multi-zone ride management') }}</span>
                </div>
                <div class="brand-feature">
                    <div class="brand-feature-icon"><i class="bi bi-shield-check"></i></div>
                    <span>{{ translate('Secure payment & pilot verification') }}</span>
                </div>
            </div>
        </div>
    </div>

    <div class="login-form-side">
        <div class="version-badge">v{{ env('SOFTWARE_VERSION', '3.0') }}</div>

        <div class="login-form-wrapper">
            <div class="login-greeting">
                <h1>{{ translate('Welcome back') }}</h1>
                <p>{{ translate('Sign in to your admin dashboard') }}</p>
            </div>

            <form action="{{ route('admin.auth.login') }}" enctype="multipart/form-data" method="POST" id="login-form">
                @csrf

                <div class="form-group">
                    <label for="email">{{ translate('Email Address') }}</label>
                    <div class="input-wrapper">
                        <input type="email" name="email" id="email" class="form-input"
                               placeholder="{{ translate('Enter your email') }}"
                               value="{{ request()->cookie('remember_email') }}" required>
                        <i class="bi bi-envelope input-icon"></i>
                    </div>
                </div>

                <div class="form-group">
                    <label for="password">{{ translate('Password') }}</label>
                    <div class="input-wrapper">
                        <input type="password" name="password" id="password" class="form-input"
                               placeholder="{{ translate('Enter your password') }}"
                               value="{{ request()->cookie('remember_password') }}" required>
                        <i class="bi bi-lock input-icon"></i>
                        <button type="button" class="toggle-password" id="password-eye" onclick="togglePasswordVisibility()">
                            <i class="bi bi-eye-slash-fill" id="eye-icon"></i>
                        </button>
                    </div>
                </div>

                <div class="remember-row">
                    <div class="remember-check">
                        <input type="checkbox" name="remember" id="remember" {{ request()->cookie('remember_checked') ? 'checked' : '' }}>
                        <label for="remember">{{ translate('Remember me') }}</label>
                    </div>
                </div>

                @if(config('app.env') !== 'local')
                <div class="captcha-row">
                    @php($recaptcha = businessConfig('recaptcha')?->value)
                    @if(isset($recaptcha) && $recaptcha['status'] == 1)
                        <input type="hidden" name="g-recaptcha-response" id="g-recaptcha-response">
                        <input type="hidden" name="set_default_captcha" id="set_default_captcha_value" value="0">
                        <div class="row d-none" id="reload-captcha">
                            <div class="col-6 pr-0">
                                <input type="text" class="form-input" name="default_captcha_value" value=""
                                       placeholder="{{ translate('Enter captcha') }}" autocomplete="off">
                            </div>
                            <div class="col-6 input-icons bg-white rounded cursor-pointer"
                                 data-toggle="tooltip" data-placement="right"
                                 title="{{ translate('Click to refresh') }}">
                                <a class="refresh-recaptcha">
                                    <img src="{{ URL('/admin/auth/code/captcha/1') }}"
                                         class="input-field h-75 rounded-10 border-bottom-0 width-90-percent"
                                         id="default_recaptcha_id" alt="{{ translate('recaptcha') }}">
                                    <i class="tio-refresh icon"></i>
                                </a>
                            </div>
                        </div>
                    @else
                        <div class="row p-2">
                            <div class="col-6 pr-0">
                                <input type="text" class="form-input" name="default_captcha_value" value=""
                                       placeholder="{{ translate('Enter captcha') }}" autocomplete="off">
                            </div>
                            <div class="col-6 input-icons bg-white rounded cursor-pointer"
                                 data-toggle="tooltip" data-placement="right"
                                 title="{{ translate('Click to refresh') }}">
                                <a class="refresh-recaptcha">
                                    <img src="{{ URL('/admin/auth/code/captcha/1') }}"
                                         class="input-field h-75 rounded-10 border-bottom-0 width-90-percent"
                                         id="default_recaptcha_id" alt="{{ translate('recaptcha') }}">
                                    <i class="tio-refresh icon"></i>
                                </a>
                            </div>
                        </div>
                    @endif
                </div>
                @endif

                <button class="btn-login" id="signInBtn" type="submit">
                    {{ translate('Sign In') }}
                    <i class="bi bi-arrow-right ms-1"></i>
                </button>
            </form>

            @if (config('app.mode') == 'demo')
            <div class="login-footer-demo">
                <div class="creds">
                    <div>{{ translate('Email') }}: <span>admin@admin.com</span></div>
                    <div>{{ translate('Password') }}: <span>12345678</span></div>
                </div>
                <button type="button" class="copy-btn" onclick="copyCredentials()" title="{{ translate('Copy credentials') }}">
                    <i class="bi bi-clipboard"></i>
                </button>
            </div>
            @endif
        </div>
    </div>
</div>

<script src="{{ dynamicAsset('public/assets/admin-module/js/jquery-3.6.0.min.js') }}"></script>
<script src="{{ dynamicAsset('public/assets/admin-module/js/bootstrap.bundle.min.js') }}"></script>
<script src="{{ dynamicAsset('public/assets/admin-module/js/main.js') }}"></script>
<script src="{{ dynamicAsset('public/assets/admin-module/js/toastr.js') }}"></script>
<script>
    "use strict";
    function togglePasswordVisibility() {
        const passwordInput = document.getElementById('password');
        const eyeIcon = document.getElementById('eye-icon');
        if (passwordInput.type === 'password') {
            passwordInput.type = 'text';
            eyeIcon.classList.remove('bi-eye-slash-fill');
            eyeIcon.classList.add('bi-eye-fill');
        } else {
            passwordInput.type = 'password';
            eyeIcon.classList.remove('bi-eye-fill');
            eyeIcon.classList.add('bi-eye-slash-fill');
        }
    }
</script>

{!! Toastr::message() !!}

@if (config('app.mode') == 'demo')
<script>
    "use strict";
    function copyCredentials() {
        document.getElementById('email').value = 'admin@admin.com';
        document.getElementById('password').value = '12345678';
        toastr.success('Copied successfully!', 'Success!', {
            CloseButton: true,
            ProgressBar: true
        });
    }
</script>
@endif

@if ($errors->any())
<script>
    "use strict";
    @foreach ($errors->all() as $error)
    toastr.error('{{ $error }}', Error, {
        CloseButton: true,
        ProgressBar: true
    });
    @endforeach
</script>
@endif

@if(isset($recaptcha) && $recaptcha['status'] == 1)
<script src="https://www.google.com/recaptcha/api.js?render={{$recaptcha['site_key']}}"></script>
<script>
    $(document).ready(function () {
        $('#signInBtn').click(function (e) {
            if ($('#set_default_captcha_value').val() == 1) {
                $('#login-form').submit();
                return true;
            }
            e.preventDefault();
            if (typeof grecaptcha === 'undefined') {
                toastr.error('Invalid recaptcha key provided. Please check the recaptcha configuration.');
                $('#reload-captcha').removeClass('d-none');
                $('#set_default_captcha_value').val('1');
                return;
            }
            grecaptcha.ready(function () {
                grecaptcha.execute('{{$recaptcha['site_key']}}', {action: 'submit'}).then(function (token) {
                    $('#g-recaptcha-response').value = token;
                    $('#login-form').submit();
                });
            });
            window.onerror = function (message) {
                var errorMessage = 'An unexpected error occurred. Please check the recaptcha configuration';
                if (message.includes('Invalid site key')) {
                    errorMessage = 'Invalid site key provided. Please check the recaptcha configuration.';
                } else if (message.includes('not loaded in api.js')) {
                    errorMessage = 'reCAPTCHA API could not be loaded. Please check the recaptcha API configuration.';
                }
                $('#reload-captcha').removeClass('d-none');
                $('#set_default_captcha_value').val('1');
                toastr.error(errorMessage);
                return true;
            };
        });
    });
</script>
@endif

<script type="text/javascript">
    $('.refresh-recaptcha').on('click', function () {
        let url = "{{ route('admin.auth.default-captcha',':tmp') }}";
        document.getElementById('default_recaptcha_id').src = url.replace(':tmp', Math.random());
    });
</script>

</body>
</html>
