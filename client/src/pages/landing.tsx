import { useEffect, useState } from "react";
import { Link } from "wouter";

const LINKS = [
  { href: "/", label: "Home" },
  { href: "/about-us", label: "About Us" },
  { href: "/privacy", label: "Privacy Policy" },
  { href: "/terms", label: "Terms & Condition" },
];

function useJagoCSS() {
  useEffect(() => {
    const cssFiles = [
      "/landing-page/assets/css/bootstrap-icons.min.css",
      "/landing-page/assets/css/bootstrap.min.css",
      "/landing-page/assets/css/animate.css",
      "/landing-page/assets/css/line-awesome.min.css",
      "/landing-page/assets/css/odometer.css",
      "/landing-page/assets/css/owl.min.css",
      "/landing-page/assets/css/main.css",
      "/landing-page/assets/css/jago-custom.css",
    ];
    const tags: HTMLLinkElement[] = [];
    cssFiles.forEach((href) => {
      const link = document.createElement("link");
      link.rel = "stylesheet";
      link.href = href;
      link.dataset.jagoLanding = "1";
      document.head.appendChild(link);
      tags.push(link);
    });
    const fonts = document.createElement("link");
    fonts.rel = "stylesheet";
    fonts.href = "https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=Poppins:wght@400;500;600;700;800&display=swap";
    fonts.dataset.jagoLanding = "1";
    document.head.appendChild(fonts);
    tags.push(fonts);

    return () => {
      document.querySelectorAll('[data-jago-landing="1"]').forEach(el => el.remove());
    };
  }, []);
}

function useJagoJS() {
  useEffect(() => {
    const scripts = [
      "/landing-page/assets/js/jquery-3.6.0.min.js",
      "/landing-page/assets/js/bootstrap.min.js",
      "/landing-page/assets/js/viewport.jquery.js",
      "/landing-page/assets/js/wow.min.js",
      "/landing-page/assets/js/owl.min.js",
      "/landing-page/assets/js/main.js",
    ];
    const added: HTMLScriptElement[] = [];
    let idx = 0;
    function loadNext() {
      if (idx >= scripts.length) return;
      const src = scripts[idx++];
      if (document.querySelector(`script[src="${src}"]`)) {
        loadNext();
        return;
      }
      const s = document.createElement("script");
      s.src = src;
      s.async = false;
      s.dataset.jagoScript = "1";
      s.onload = loadNext;
      document.body.appendChild(s);
      added.push(s);
    }
    loadNext();
    return () => {
      added.forEach(el => el.remove());
    };
  }, []);
}

export default function LandingPage() {
  useJagoCSS();
  useJagoJS();
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <>
      <style>{`
        html, body { margin:0; padding:0; }
        #root { min-height:100vh; }
      `}</style>

      {/* Preloader */}
      <div className="preloader" id="preloader" style={{ display: "none" }}></div>

      {/* Header */}
      <header>
        <div className="navbar-bottom">
          <div className="container">
            <div className="navbar-bottom-wrapper">
              <a href="/" className="logo" style={{ maxWidth: "320px", height: "auto" }}>
                <img src="/jago-logo.png" alt="JAGO" style={{ width: "100%", height: "auto", maxHeight: "80px", objectFit: "contain" }} />
              </a>
              <ul className={`menu me-lg-4${menuOpen ? " show" : ""}`} style={{ display: menuOpen ? "flex" : undefined, flexDirection: menuOpen ? "column" : undefined }}>
                {LINKS.map(l => (
                  <li key={l.href}>
                    <a href={l.href} className={window.location.pathname === l.href ? "active" : ""}>
                      <span>{l.label}</span>
                    </a>
                  </li>
                ))}
              </ul>
              <div className="nav-toggle d-lg-none ms-auto me-2 me-sm-4" onClick={() => setMenuOpen(o => !o)}>
                <span></span><span></span><span></span>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Banner Section */}
      <section className="banner-section">
        <div className="container">
          <div className="banner-wrapper justify-content-between" style={{ paddingTop: "80px", paddingBottom: "60px" }}>
            <div className="banner-content text-center text-sm-start">
              <h1 className="title">
                Your Smart <span className="text--base">Logistics &amp; Mobility</span> Platform
              </h1>
              <p className="txt">
                Powering seamless parcel delivery, smart fleet management, and real-time tracking — JAGO is the all-in-one logistics and ride-sharing solution built for modern businesses.
              </p>
              <div className="app--btns d-flex flex-wrap flex-column flex-sm-row gap-3 mt-4">
                <div className="dropdown py-0">
                  <a href="#" className="cmn--btn h-50 d-flex gap-2 lh-1" data-bs-toggle="dropdown">
                    Download User App <i className="bi bi-chevron-down"></i>
                  </a>
                  <div className="dropdown-menu dropdown-button-menu">
                    <ul className="list-unstyled mb-0">
                      <li className="border-bottom">
                        <a href="#" target="_blank" className="d-flex align-items-center gap-2 p-3">
                          <img width="20" src="/landing-page/assets/img/play-fav.png" alt="" />
                          <span>Play Store</span>
                        </a>
                      </li>
                      <li>
                        <a href="#" target="_blank" className="d-flex align-items-center gap-2 p-3">
                          <img width="20" src="/landing-page/assets/img/apple.png" alt="" />
                          <span>App Store</span>
                        </a>
                      </li>
                    </ul>
                  </div>
                </div>
                <div className="dropdown py-0">
                  <a href="#" className="cmn--btn btn-white text-nowrap h-50 d-flex gap-2 lh-1" data-bs-toggle="dropdown">
                    Earn From JAGO <i className="bi bi-chevron-down"></i>
                  </a>
                  <div className="dropdown-menu dropdown-button-menu">
                    <ul className="list-unstyled mb-0">
                      <li className="border-bottom">
                        <a href="#" target="_blank" className="d-flex align-items-center gap-2 p-3">
                          <img width="20" src="/landing-page/assets/img/play-fav.png" alt="" />
                          <span>Play Store</span>
                        </a>
                      </li>
                      <li>
                        <a href="#" target="_blank" className="d-flex align-items-center gap-2 p-3">
                          <img width="20" src="/landing-page/assets/img/apple.png" alt="" />
                          <span>App Store</span>
                        </a>
                      </li>
                    </ul>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Why JAGO Section */}
      <section className="why-jago-section">
        <div className="container">
          <div className="mb-4 mb-sm-5 text-center">
            <h2 className="section-title mb-2 mb-sm-3">Why <span style={{ color: "var(--jago-primary, #2563EB)" }}>JAGO</span></h2>
            <p className="fs-18 mb-0">Everything you need to power your logistics and mobility operations</p>
          </div>
          <div className="row g-4">
            {[
              { icon: "bi-geo-alt", title: "Real-Time Tracking", desc: "Track every delivery and vehicle in real time with precise GPS location updates and live status notifications." },
              { icon: "bi-truck", title: "Smart Fleet Management", desc: "Optimize routes, monitor driver performance, and manage your entire fleet from a single powerful dashboard." },
              { icon: "bi-box-seam", title: "Parcel Delivery", desc: "Fast and reliable parcel delivery with custom fare setup, weight-based pricing, and instant booking." },
              { icon: "bi-car-front", title: "Ride Sharing", desc: "Comfortable and affordable rides at your fingertips. Book instantly and travel to any destination with ease." },
              { icon: "bi-shield-check", title: "Secure Payments", desc: "Multiple secure payment options including digital wallets, cards, and cash on delivery for every transaction." },
              { icon: "bi-headset", title: "24/7 Support", desc: "Round-the-clock customer support to ensure smooth operations and quick resolution of any issues." },
            ].map((item) => (
              <div key={item.title} className="col-lg-4 col-md-6">
                <div className="why-jago-card">
                  <div className="icon-circle">
                    <i className={`bi ${item.icon}`}></i>
                  </div>
                  <h5>{item.title}</h5>
                  <p>{item.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* How It Works Section */}
      <section className="how-it-works-section mt-4 mt-sm-60" id="jago-flow">
        <div className="container">
          <div className="text-center mb-4 mb-sm-5">
            <span className="jago-section-badge">How It Works</span>
            <h2 className="jago-section-heading mt-3">Your Parcel, <span className="text-gradient">Delivered Safely</span></h2>
            <p className="jago-section-sub mx-auto">From booking to doorstep delivery — see how JAGO makes logistics simple, fast, and secure.</p>
          </div>

          <div className="jago-flow-scene">
            <div className="jago-flow-connector">
              <svg className="jago-flow-svg" viewBox="0 0 1100 120" preserveAspectRatio="none">
                <path className="jago-flow-path" d="M80,60 C200,60 200,60 300,60 C400,60 400,60 550,60 C700,60 700,60 800,60 C900,60 900,60 1020,60" fill="none" stroke="#DBEAFE" strokeWidth="3" strokeDasharray="8,6" />
                <path className="jago-flow-path-active" d="M80,60 C200,60 200,60 300,60 C400,60 400,60 550,60 C700,60 700,60 800,60 C900,60 900,60 1020,60" fill="none" stroke="url(#jagoGrad)" strokeWidth="3" />
                <defs>
                  <linearGradient id="jagoGrad" x1="0%" y1="0%" x2="100%" y2="0%">
                    <stop offset="0%" style={{ stopColor: "#2563EB" }} />
                    <stop offset="50%" style={{ stopColor: "#3B82F6" }} />
                    <stop offset="100%" style={{ stopColor: "#10B981" }} />
                  </linearGradient>
                </defs>
              </svg>
            </div>
            <div className="jago-flow-nodes">
              <div className="jago-flow-node" data-step="1">
                <div className="jago-node-visual">
                  <div className="jago-node-phone">
                    <div className="jago-phone-screen">
                      <div className="jago-phone-header"><span>JAGO</span></div>
                      <div className="jago-phone-map"><i className="bi bi-geo-alt-fill"></i></div>
                      <div className="jago-phone-btn">Book Now</div>
                    </div>
                  </div>
                  <div className="jago-node-badge">1</div>
                </div>
                <h5>Book on App</h5>
                <p>Enter pickup &amp; drop location, select vehicle, confirm booking</p>
              </div>
              <div className="jago-flow-node" data-step="2">
                <div className="jago-node-visual">
                  <div className="jago-node-rider">
                    <div className="jago-rider-bike"><i className="bi bi-bicycle"></i></div>
                    <div className="jago-rider-parcel"><i className="bi bi-box-seam-fill"></i></div>
                  </div>
                  <div className="jago-node-badge">2</div>
                </div>
                <h5>Pilot Picks Up</h5>
                <p>Nearest Pilot arrives, collects parcel with OTP verification</p>
              </div>
              <div className="jago-flow-node" data-step="3">
                <div className="jago-node-visual">
                  <div className="jago-node-tracking">
                    <div className="jago-tracking-map">
                      <div className="jago-tracking-route"></div>
                      <div className="jago-tracking-dot jago-dot-start"><i className="bi bi-circle-fill"></i></div>
                      <div className="jago-tracking-dot jago-dot-moving"><i className="bi bi-truck"></i></div>
                      <div className="jago-tracking-dot jago-dot-end"><i className="bi bi-geo-alt-fill"></i></div>
                    </div>
                  </div>
                  <div className="jago-node-badge">3</div>
                </div>
                <h5>Live Tracking</h5>
                <p>Real-time GPS tracking on map with status notifications</p>
              </div>
              <div className="jago-flow-node" data-step="4">
                <div className="jago-node-visual">
                  <div className="jago-node-delivered">
                    <div className="jago-delivered-check"><i className="bi bi-patch-check-fill"></i></div>
                    <div className="jago-delivered-otp">
                      <span>OTP</span>
                      <div className="jago-otp-dots"><span></span><span></span><span></span><span></span></div>
                    </div>
                  </div>
                  <div className="jago-node-badge jago-badge-success">4</div>
                </div>
                <h5>Delivered &amp; Verified</h5>
                <p>Receiver OTP verified, payment processed automatically</p>
              </div>
            </div>
          </div>

          <div className="flow-features-bar mt-4 mt-sm-5">
            {[
              { icon: "bi-lightning-charge-fill", label: "30 Min Avg Delivery" },
              { icon: "bi-shield-lock-fill", label: "OTP Secured" },
              { icon: "bi-pin-map-fill", label: "Live GPS Tracking" },
              { icon: "bi-cash-coin", label: "Transparent Pricing" },
            ].map(f => (
              <div key={f.label} className="flow-feature-item">
                <div className="flow-feature-icon"><i className={`bi ${f.icon}`}></i></div>
                <span>{f.label}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Our Solutions Section */}
      <section className="jago-solutions-section mt-4 mt-sm-60">
        <div className="container">
          <div className="text-center mb-5">
            <span className="jago-section-badge">What We Offer</span>
            <h2 className="jago-section-heading mt-3">Our <span className="text-gradient">Solutions</span></h2>
            <p className="jago-section-sub mx-auto">End-to-end logistics and mobility solutions built for speed, reliability, and scale.</p>
          </div>
          <div className="row g-4">
            {[
              { icon: "bi-box-seam", title: "Parcel Delivery", desc: "Send parcels anywhere with real-time tracking, weight-based pricing, and OTP-verified handoffs. Fast, reliable, and transparent.", features: ["Real-time Tracking", "OTP Verified", "Weight-based Pricing"] },
              { icon: "bi-car-front", title: "Ride Sharing", desc: "Book rides instantly with smart route matching, fare estimation, and safe travel. Affordable commuting made simple.", features: ["Instant Booking", "Fare Estimation", "Driver Tracking"] },
              { icon: "bi-calendar-check", title: "Scheduled Trips", desc: "Plan ahead with pre-scheduled rides and deliveries. Set your time, date, and destination — we handle the rest.", features: ["Advance Booking", "Flexible Timing", "Auto Reminders"] },
              { icon: "bi-building", title: "Business Logistics", desc: "Scalable fleet management for businesses. Route optimization, driver management, and analytics all in one dashboard.", features: ["Fleet Dashboard", "Route Optimization", "Analytics"] },
              { icon: "bi-wallet2", title: "Digital Payments", desc: "Seamless and secure payment options including digital wallets, cards, and cash on delivery for every transaction.", features: ["Multiple Methods", "Wallet System", "Secure & Fast"] },
              { icon: "bi-geo-alt", title: "Live Navigation", desc: "Real-time GPS navigation for drivers with optimized routes, turn-by-turn directions, and traffic-aware ETA calculations.", features: ["GPS Tracking", "Smart Routes", "Live ETA"] },
            ].map(item => (
              <div key={item.title} className="col-lg-4 col-md-6">
                <div className="jago-solution-card">
                  <div className="jago-solution-icon-wrap">
                    <i className={`bi ${item.icon}`}></i>
                  </div>
                  <div className="jago-solution-body">
                    <h4 className="jago-solution-title">{item.title}</h4>
                    <p className="jago-solution-desc">{item.desc}</p>
                    <div className="jago-solution-features">
                      {item.features.map(f => (
                        <span key={f}><i className="bi bi-check-circle-fill"></i> {f}</span>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Newsletter Section */}
      <section className="newsletter-section p-0 mt-4 mt-sm-60">
        <div className="container">
          <div className="newsletter--wrapper bg__img" data-img="/landing-page/assets/img/newsletter-new-bg.png">
            <div className="position-relative p-4 p-sm-5">
              <div className="row g-4 align-items-center">
                <div className="col-lg-8">
                  <h4 className="text-white text-uppercase mb-2">GET ALL UPDATES &amp; EXCITING NEWS</h4>
                  <p className="text-white opacity-75 lh-base">Subscribe to our newsletters to receive all the latest activity we provide for you</p>
                </div>
                <div className="col-lg-4">
                  <div className="newsletter-right">
                    <form className="newsletter-form" onSubmit={e => { e.preventDefault(); }}>
                      <input type="email" className="form-control" placeholder="Type email..." autoComplete="off" required />
                      <button type="submit" className="btn cmn--btn">Subscribe</button>
                    </form>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="jago-footer mt-4 mt-sm-60">
        <div className="footer-top">
          <div className="container">
            <div className="row g-4 g-lg-5">
              <div className="col-lg-4 col-md-6">
                <div className="footer-brand">
                  <a href="/" className="footer-logo d-inline-block mb-3">
                    <img src="/jago-logo.png" alt="JAGO Logo" className="footer-logo-img" />
                  </a>
                  <p className="footer-desc">Your trusted logistics and mobility platform. Delivering parcels, connecting rides, and powering seamless transportation — anytime, anywhere.</p>
                  <div className="footer-social">
                    {[["bi-facebook", "#"], ["bi-instagram", "#"], ["bi-twitter-x", "#"], ["bi-linkedin", "#"]].map(([icon, href]) => (
                      <a key={icon} href={href} className="social-link"><i className={`bi ${icon}`}></i></a>
                    ))}
                  </div>
                </div>
              </div>
              <div className="col-lg-2 col-md-6">
                <h6 className="footer-widget-title">Quick Links</h6>
                <ul className="footer-links">
                  {[["Home", "/"], ["About Us", "/about-us"], ["Privacy Policy", "/privacy"], ["Terms & Condition", "/terms"], ["Contact Us", "/contact-us"]].map(([label, href]) => (
                    <li key={label}><a href={href}>{label}</a></li>
                  ))}
                </ul>
              </div>
              <div className="col-lg-3 col-md-6">
                <h6 className="footer-widget-title">Our Services</h6>
                <ul className="footer-links">
                  {["Ride Sharing", "Parcel Delivery", "Scheduled Trips", "Business Logistics", "Driver App", "Customer App"].map(s => (
                    <li key={s}><a href="#">{s}</a></li>
                  ))}
                </ul>
              </div>
              <div className="col-lg-3 col-md-6">
                <h6 className="footer-widget-title">Contact Us</h6>
                <div className="footer-contact-list">
                  <div className="footer-contact-item">
                    <div className="footer-contact-icon"><i className="bi bi-envelope-fill"></i></div>
                    <div>
                      <span className="footer-contact-label">Email</span>
                      <a href="mailto:support@jago.in" className="footer-contact-value">support@jago.in</a>
                    </div>
                  </div>
                  <div className="footer-contact-item">
                    <div className="footer-contact-icon"><i className="bi bi-telephone-fill"></i></div>
                    <div>
                      <span className="footer-contact-label">Phone</span>
                      <a href="tel:+911234567890" className="footer-contact-value">+91 12345 67890</a>
                    </div>
                  </div>
                  <div className="footer-contact-item">
                    <div className="footer-contact-icon"><i className="bi bi-geo-alt-fill"></i></div>
                    <div>
                      <span className="footer-contact-label">Address</span>
                      <span className="footer-contact-value">Hyderabad, Telangana, India</span>
                    </div>
                  </div>
                </div>
                <div className="footer-apps-row">
                  <div className="footer-app-group">
                    <span className="footer-app-label">Download App:</span>
                    <a href="#"><img src="/landing-page/assets/img/play-store.png" className="footer-store-badge" alt="Play Store" /></a>
                    <a href="#"><img src="/landing-page/assets/img/app-store.png" className="footer-store-badge" alt="App Store" /></a>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className="footer-bottom">
          <div className="container">
            <div className="d-flex flex-wrap align-items-center justify-content-between gap-2">
              <p className="mb-0">&copy; {new Date().getFullYear()} JAGO. All rights reserved.</p>
              <div className="d-flex gap-3">
                <a href="/privacy" className="text-white-50 text-decoration-none" style={{ fontSize: "13px" }}>Privacy Policy</a>
                <a href="/terms" className="text-white-50 text-decoration-none" style={{ fontSize: "13px" }}>Terms &amp; Conditions</a>
              </div>
            </div>
          </div>
        </div>
      </footer>
    </>
  );
}
