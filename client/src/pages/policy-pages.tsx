import { useEffect } from "react";

const COMPANY = "MindWhile IT Solutions Pvt Ltd";
const BRAND   = "JAGO";
const EMAIL   = "info@jagopro.org";
const WEBSITE = "jagopro.org";
const ADDRESS = "Hyderabad, Telangana, India";
const YEAR    = new Date().getFullYear();

function PolicyLayout({ title, badge, children }: { title: string; badge?: string; children: React.ReactNode }) {
  useEffect(() => {
    document.title = `${title} — ${BRAND}`;
    return () => { document.title = BRAND; };
  }, [title]);

  return (
    <div style={{ minHeight: "100vh", background: "#f8fafc", fontFamily: "'Manrope', 'Segoe UI', sans-serif" }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800&display=swap');
        .policy-nav-links { display: flex; gap: 20px; font-size: 13px; color: #64748b; }
        .policy-values-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin: 8px 0 20px; }
        .policy-contact-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-top: 8px; }
        @media (max-width: 900px) {
          .policy-nav-links { display: none; }
        }
        @media (max-width: 700px) {
          .policy-values-grid, .policy-contact-grid { grid-template-columns: 1fr; }
        }
      `}</style>

      {/* Sticky Nav */}
      <nav style={{
        background: "#fff", borderBottom: "1px solid #e2e8f0",
        padding: "0 32px", height: 64,
        display: "flex", alignItems: "center",
        position: "sticky", top: 0, zIndex: 200,
        boxShadow: "0 1px 8px rgba(0,0,0,0.07)",
      }}>
        <a href="/" style={{ display: "flex", alignItems: "center", gap: 10, textDecoration: "none" }}>
          <img src="/jago-logo.png" alt={BRAND} style={{ height: 38, objectFit: "contain" }} />
        </a>
        <div style={{ flex: 1 }} />
        <div className="policy-nav-links">
          <a href="/about-us" style={{ textDecoration: "none", color: "#64748b", fontWeight: 500 }}>About</a>
          <a href="/privacy" style={{ textDecoration: "none", color: "#64748b", fontWeight: 500 }}>Privacy</a>
          <a href="/terms" style={{ textDecoration: "none", color: "#64748b", fontWeight: 500 }}>Terms</a>
          <a href="/refund-policy" style={{ textDecoration: "none", color: "#64748b", fontWeight: 500 }}>Refund</a>
          <a href="/cookie-policy" style={{ textDecoration: "none", color: "#64748b", fontWeight: 500 }}>Cookie</a>
          <a href="/contact-us" style={{ textDecoration: "none", color: "#64748b", fontWeight: 500 }}>Contact</a>
        </div>
        <div style={{ width: 1, height: 20, background: "#e2e8f0", margin: "0 20px" }} />
        <a href="/" style={{ fontSize: 13, color: "#2563eb", textDecoration: "none", fontWeight: 600 }}>← Home</a>
      </nav>

      {/* Hero */}
      <div style={{
        background: "linear-gradient(135deg, #0b3c88 0%, #1559c1 55%, #0c7ca6 100%)",
        color: "white", padding: "56px 24px 44px", textAlign: "center",
      }}>
        <div style={{ maxWidth: 760, margin: "0 auto" }}>
          {badge && (
            <span style={{
              display: "inline-block", fontSize: 11, fontWeight: 700, textTransform: "uppercase",
              letterSpacing: 1.5, background: "rgba(255,255,255,0.15)", borderRadius: 20,
              padding: "4px 14px", marginBottom: 14, border: "1px solid rgba(255,255,255,0.2)",
            }}>{badge}</span>
          )}
          <h1 style={{ fontSize: 34, fontWeight: 800, margin: 0, marginBottom: 12, lineHeight: 1.2 }}>{title}</h1>
          <p style={{ fontSize: 14, opacity: 0.8, margin: 0 }}>
            Effective: 1 January 2025 · Last updated: 6 March 2026
          </p>
          <p style={{ fontSize: 13, opacity: 0.65, margin: "6px 0 0" }}>
            {COMPANY} · {ADDRESS}
          </p>
        </div>
      </div>

      {/* Content */}
      <div style={{ maxWidth: 860, margin: "0 auto", padding: "44px 24px 80px" }}>
        <div style={{
          background: "white", borderRadius: 20, padding: "44px 48px",
          boxShadow: "0 4px 24px rgba(0,0,0,0.06)",
          lineHeight: 1.85, color: "#374151",
          fontSize: 14.5,
        }}>
          {children}
        </div>
      </div>

      {/* Footer */}
      <div style={{ background: "#0f172a", color: "rgba(255,255,255,0.45)", textAlign: "center", padding: "22px 24px", fontSize: 13 }}>
        © {YEAR} {COMPANY} · {BRAND} is a registered product of {COMPANY} ·&nbsp;
        <a href="/privacy" style={{ color: "rgba(255,255,255,0.55)", textDecoration: "none" }}>Privacy</a>&nbsp;·&nbsp;
        <a href="/terms" style={{ color: "rgba(255,255,255,0.55)", textDecoration: "none" }}>Terms</a>&nbsp;·&nbsp;
        <a href="/refund-policy" style={{ color: "rgba(255,255,255,0.55)", textDecoration: "none" }}>Refund</a>&nbsp;·&nbsp;
        <a href="/cookie-policy" style={{ color: "rgba(255,255,255,0.55)", textDecoration: "none" }}>Cookie</a>&nbsp;·&nbsp;
        <a href={`mailto:${EMAIL}`} style={{ color: "rgba(255,255,255,0.55)", textDecoration: "none" }}>{EMAIL}</a>
      </div>
    </div>
  );
}

const S = ({ children }: { children: React.ReactNode }) => (
  <h3 style={{
    fontSize: 17, fontWeight: 700, color: "#1e293b",
    marginTop: 36, marginBottom: 10,
    paddingBottom: 8, borderBottom: "2px solid #f1f5f9",
    display: "flex", alignItems: "center", gap: 8,
  }}>{children}</h3>
);
const P = ({ children }: { children: React.ReactNode }) => (
  <p style={{ margin: "0 0 14px", color: "#4b5563" }}>{children}</p>
);
const UL = ({ items }: { items: string[] }) => (
  <ul style={{ paddingLeft: 20, margin: "0 0 16px" }}>
    {items.map((it, i) => (
      <li key={i} style={{ color: "#4b5563", marginBottom: 7, paddingLeft: 4 }}>{it}</li>
    ))}
  </ul>
);
const InfoBox = ({ children }: { children: React.ReactNode }) => (
  <div style={{
    background: "#eff6ff", border: "1px solid #bfdbfe",
    borderLeft: "4px solid #2563eb", borderRadius: 10,
    padding: "14px 18px", marginBottom: 20, color: "#1e40af", fontSize: 13.5,
  }}>{children}</div>
);

/* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   PRIVACY POLICY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */
export function PrivacyPage() {
  return (
    <PolicyLayout title="Privacy Policy" badge="Data & Privacy">
      <InfoBox>
        This Privacy Policy explains what data {COMPANY} processes to operate {BRAND}, why we process it, and the controls available to you under applicable law.
      </InfoBox>

      <S>1. Who We Are</S>
      <P>{COMPANY} is the developer and operator of the {BRAND} platform — a technology solution for ride-sharing, parcel delivery, and logistics management. {BRAND} connects users ("Customers") with independent service providers ("Pilots") through our digital platform.</P>
      <P><strong>Registered Address:</strong> {ADDRESS}<br /><strong>Contact:</strong> <a href={`mailto:${EMAIL}`}>{EMAIL}</a><br /><strong>Website:</strong> {WEBSITE}</P>

      <S>2. Information We Collect</S>
      <P>We collect only what is necessary to provide the {BRAND} service:</P>
      <UL items={[
        "Identity Information: Full name, date of birth, gender (optional), profile photo",
        "Contact Information: Mobile number, email address",
        "Location Data: GPS coordinates shared during active trips for routing, ETA calculation, and safety",
        "Pilot-Specific Information: Driving licence number, vehicle registration, vehicle make/model, insurance documents",
        "Financial Information: Wallet balance, UPI ID or bank account details for earnings withdrawal (Pilots only)",
        "Device Information: Device model, operating system version, unique device identifiers, push notification tokens",
        "Usage Data: App interactions, feature usage, crash reports, and performance logs",
        "Trip Records: Pickup/drop locations, distance, duration, fare, payment method, and rating",
        "Communications: In-app chat messages and call metadata (not call content)",
      ]} />

      <S>3. How We Use Your Information</S>
      <UL items={[
        "To match Customers with available Pilots based on proximity and vehicle type",
        "To calculate fares, apply coupons, and process payments",
        "To send OTP verifications, trip updates, and service notifications",
        "To display real-time location of the Pilot to the Customer during an active trip",
        "To settle earnings, process withdrawal requests, and manage wallets",
        "To verify Pilot identity and eligibility through KYC processes",
        "To handle disputes, cancellations, and refund requests",
        "To improve platform performance, detect fraud, and ensure safety",
        "To send promotional messages or offers — only with your explicit consent",
        "To comply with applicable laws and regulatory requirements",
      ]} />

      <S>4. Information Sharing</S>
      <P>We do not sell, rent, or trade your personal data. Sharing is strictly limited to:</P>
      <UL items={[
        "Between Customers and Pilots — only the information necessary for trip fulfillment (name, contact, vehicle details, live location during the trip)",
        "Payment and banking partners — for processing withdrawals and transactions, under strict confidentiality obligations",
        "Cloud and technology service providers — for hosting, SMS delivery, and analytics, bound by data processing agreements",
        "Law enforcement or government authorities — only when required by a valid legal order or to prevent fraud and protect user safety",
        "Acquirer or successor entity — in the event of a merger, acquisition, or restructuring, subject to equivalent privacy protections",
      ]} />
      <P>Pilots' personal documents (licence, vehicle details) are never shared publicly and are accessed only for verification purposes by authorised personnel.</P>

      <S>5. Data Retention</S>
      <P>We retain your data for as long as your account is active. After account deletion:</P>
      <UL items={[
        "Trip records and transaction logs are retained for 5 years for legal and audit compliance",
        "Identity and KYC documents are deleted within 90 days of account closure, subject to legal hold requirements",
        "Communication logs are retained for 12 months for dispute resolution purposes",
        "Push notification tokens and device identifiers are deleted immediately upon deregistration",
      ]} />

      <S>6. Data Security</S>
      <P>We implement industry-standard technical and organisational measures to protect your data:</P>
      <UL items={[
        "TLS/SSL encryption for all data in transit",
        "AES-256 encryption for sensitive data at rest",
        "Role-based access controls — staff access only what is necessary for their role",
        "Regular security audits and vulnerability assessments",
        "Secure, token-based authentication (no passwords stored in plain text)",
        "Automated fraud detection and anomaly monitoring",
      ]} />

      <S>7. Your Rights</S>
      <P>You have the following rights regarding your personal data:</P>
      <UL items={[
        "Access: Request a copy of the personal data we hold about you",
        "Correction: Request correction of inaccurate or incomplete information",
        "Deletion: Request deletion of your account and associated personal data",
        "Portability: Receive your trip history and account data in a structured format",
        "Restriction: Request that we limit processing of your data in certain circumstances",
        "Withdraw Consent: Unsubscribe from marketing communications at any time via the app or by emailing us",
      ]} />
      <P>To exercise these rights, contact us at <a href={`mailto:${EMAIL}`}>{EMAIL}</a>. We will respond within 30 days.</P>

      <S>8. Cookies and Tracking</S>
      <P>Our web portal uses session cookies strictly necessary for authentication and security. We do not use third-party advertising or behavioural tracking cookies. Our mobile apps use crash reporting and performance monitoring SDKs that collect anonymised, aggregated usage data only.</P>

      <S>9. Children's Privacy</S>
      <P>The {BRAND} platform is intended for users aged 18 and above. We do not knowingly collect personal information from anyone under 18. If we become aware of such data, it will be deleted promptly.</P>

      <S>10. Changes to This Policy</S>
      <P>We may update this Privacy Policy to reflect changes in our practices or applicable law. Significant changes will be communicated via in-app notification or email at least 14 days before they take effect. Continued use of {BRAND} after the effective date constitutes acceptance of the updated policy.</P>

      <S>11. Regulatory Compliance</S>
      <P>Our privacy operations are designed to align with applicable Indian data protection and intermediary obligations. Where the law imposes stricter obligations than this policy, legal requirements will prevail.</P>

      <S>12. Contact</S>
      <P>For privacy-related questions, requests, or complaints:<br /><strong>Email:</strong> <a href={`mailto:${EMAIL}`}>{EMAIL}</a><br /><strong>{COMPANY}</strong> · {ADDRESS}</P>
    </PolicyLayout>
  );
}

/* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   TERMS & CONDITIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */
export function TermsPage() {
  return (
    <PolicyLayout title="Terms & Conditions" badge="Legal Agreement">
      <InfoBox>
        Please read these Terms carefully before using the {BRAND} platform. By creating an account or using our services, you agree to be bound by these Terms. If you do not agree, please do not use {BRAND}.
      </InfoBox>

      <S>1. About the Platform</S>
      <P>{BRAND} is a technology platform developed and operated by {COMPANY}. {BRAND} provides a marketplace connecting Customers (people who need transportation or delivery services) with Pilots (independent service providers who fulfil those requests). {COMPANY} does not itself provide transportation or delivery services — it operates the technology platform that enables these connections.</P>

      <S>2. Definitions</S>
      <UL items={[
        `"${BRAND}" or "Platform" — the ${BRAND} website, mobile applications, and APIs operated by ${COMPANY}`,
        `"${COMPANY}" / "we" / "us" — MindWhile IT Solutions Pvt Ltd, the developer and operator of ${BRAND}`,
        '"Customer" — an individual who books rides, deliveries, or related services through the Platform',
        '"Pilot" — an independent service provider registered to accept and fulfil service requests on the Platform',
        '"Trip" — a completed, ongoing, or booked service request (ride, parcel, cargo, etc.)',
        '"Wallet" — the in-app digital account for storing credits, earnings, and processing payments',
      ]} />

      <S>3. Eligibility</S>
      <UL items={[
        "You must be at least 18 years of age to register and use the Platform",
        "You must provide accurate, complete, and current information during registration",
        "You must maintain a single account — multiple accounts for the same individual are prohibited",
        "You must not have been previously suspended or banned from the Platform",
        "Pilots must hold valid documents as required under applicable law (driving licence, vehicle registration, insurance)",
      ]} />

      <S>4. Customer Terms</S>
      <UL items={[
        "Customers may book rides, parcel deliveries, cargo services, and intercity trips through the Platform",
        "The fare displayed before booking is an estimate; the final fare may vary based on actual distance and time",
        "Customers are responsible for ensuring accurate pickup and drop-off information",
        "Customers must treat Pilots with respect; abusive behaviour will result in account suspension",
        "Customers may rate their Pilot after each trip; ratings affect Pilot performance scores",
        "Customer wallets may be loaded via UPI, debit/credit card, or other available payment methods",
        "Unused wallet balance is non-refundable except where required by law",
      ]} />

      <S>5. Pilot Terms</S>
      <UL items={[
        "Pilots must complete the full KYC and document verification process before accepting trips",
        "Pilots are independent service providers and are not employees or agents of " + COMPANY,
        "Pilots are responsible for maintaining their vehicle in a roadworthy and insured condition",
        "Pilots must comply with all applicable traffic laws, safety regulations, and Platform guidelines at all times",
        "Platform commission is deducted from each completed trip as per the agreed revenue model displayed in the app",
        "Pilot wallets may go into negative balance due to commission deductions; accounts with balance below −₹100 may be temporarily restricted until the balance is settled",
        "Pilots must maintain a minimum average rating of 3.5 stars to remain active on the Platform",
        "Repeated trip cancellations, no-shows, or safety violations may result in demotion, penalty, or permanent deactivation",
        "Pilots must not solicit customers for off-platform bookings or accept payments outside the Platform for trips initiated on the Platform",
      ]} />

      <S>6. Bookings and Cancellations</S>
      <UL items={[
        "Bookings are confirmed once a Pilot accepts the request",
        "Customers may cancel a booking before the Pilot begins travelling to the pickup point, subject to the cancellation policy in effect at the time",
        "Cancellation fees may apply if the Customer cancels after the Pilot has reached or is near the pickup point",
        "Pilots who cancel after accepting a trip without valid reason will receive a negative performance mark",
        "Repeated cancellations by either party may result in temporary restrictions on booking access",
        COMPANY + " reserves the right to modify the cancellation policy and applicable fees with reasonable notice",
      ]} />

      <S>7. Payments and Wallet</S>
      <UL items={[
        "All fares are calculated automatically based on distance, vehicle type, time, and applicable surge pricing",
        "Accepted payment methods include cash, in-app wallet, UPI, and any other method displayed in the app",
        "Pilot earnings are credited to the Pilot wallet after deduction of applicable platform commission and GST",
        "Minimum withdrawal amount: ₹100; processing time: 1–3 business days to the registered bank account or UPI",
        COMPANY + " may withhold earnings pending investigation of a dispute, fraud allegation, or policy violation",
        "Wallet balances do not earn interest and are not covered by any deposit insurance scheme",
        "Promotional wallet credits and bonuses may carry additional conditions and expiry dates",
      ]} />

      <S>8. Ratings and Reviews</S>
      <P>Both Customers and Pilots may rate each other after a trip. Ratings are used to maintain service quality and safety on the Platform. Attempts to manipulate ratings (self-rating, coercing ratings, or coordinated fake reviews) are prohibited and may result in account suspension.</P>

      <S>9. Prohibited Conduct</S>
      <P>The following are strictly prohibited on the {BRAND} Platform:</P>
      <UL items={[
        "Providing false, misleading, or fraudulent information during registration or use",
        "Harassment, threats, or physical or verbal abuse towards any Platform user",
        "Using the Platform for any unlawful purpose",
        "Attempting to circumvent fare calculations, platform fees, or safety mechanisms",
        "Using automated bots, scripts, or fake GPS to manipulate the Platform",
        "Reverse engineering, decompiling, or attempting to extract the Platform's source code",
        "Sharing your account credentials with any other person",
        "Transporting prohibited or illegal items through the Platform",
      ]} />

      <S>10. Platform Availability</S>
      <P>{COMPANY} aims to provide uninterrupted access to {BRAND} but does not guarantee 100% uptime. The Platform may be unavailable during maintenance, updates, or due to circumstances beyond our control (including natural disasters, internet outages, or force majeure events). {COMPANY} shall not be liable for any losses arising from Platform unavailability.</P>

      <S>11. Limitation of Liability</S>
      <P>{COMPANY} operates a technology platform and is not a transportation or logistics provider. To the maximum extent permitted by applicable law:</P>
      <UL items={[
        COMPANY + " is not liable for the actions, conduct, or omissions of Pilots or Customers",
        "Our maximum aggregate liability to any user shall not exceed the value of the disputed transaction",
        COMPANY + " is not liable for indirect, consequential, or incidental losses",
        "Users engage with the Platform at their own risk, and are advised to exercise standard personal safety precautions",
      ]} />

      <S>12. Indemnity</S>
      <P>You agree to defend and indemnify {COMPANY}, its directors, officers, employees, and affiliates from claims, liabilities, penalties, and costs arising out of your misuse of the Platform, breach of these Terms, or violation of applicable law.</P>

      <S>13. No Warranty</S>
      <P>The Platform is provided on an "as is" and "as available" basis. Except where required by law, {COMPANY} disclaims implied warranties including merchantability, fitness for a particular purpose, and non-infringement.</P>

      <S>14. Intellectual Property</S>
      <P>The {BRAND} name, logo, design, software, and all associated intellectual property are the exclusive property of {COMPANY}. You may not reproduce, distribute, or create derivative works without express written permission from {COMPANY}.</P>

      <S>15. Modifications to Terms</S>
      <P>We may update these Terms from time to time. Material changes will be communicated via in-app notice or email at least 14 days before they take effect. Continued use of the Platform after the effective date constitutes acceptance of the revised Terms.</P>

      <S>16. Governing Law and Disputes</S>
      <P>These Terms are governed by the laws of India. Any disputes arising under these Terms shall be subject to the exclusive jurisdiction of competent courts in Hyderabad, Telangana, India. Before initiating proceedings, users must first raise a written dispute notice to <a href={`mailto:${EMAIL}`}>{EMAIL}</a> and allow a 15-day resolution window.</P>

      <S>17. Contact</S>
      <P><strong>{COMPANY}</strong><br />{ADDRESS}<br />Email: <a href={`mailto:${EMAIL}`}>{EMAIL}</a> · Website: <a href={`https://${WEBSITE}`}>{WEBSITE}</a></P>
    </PolicyLayout>
  );
}

/* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ABOUT US
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */
export function AboutPage() {
  return (
    <PolicyLayout title="About JAGO" badge="Our Story">
      <div style={{ textAlign: "center", marginBottom: 36 }}>
        <img src="/jago-logo.png" alt={BRAND} style={{ height: 72, objectFit: "contain", marginBottom: 16 }} />
        <p style={{ fontSize: 18, color: "#1e293b", fontWeight: 600, maxWidth: 600, margin: "0 auto", lineHeight: 1.5 }}>
          JAGO is a smart mobility super platform built for safer daily movement, reliable logistics, and scalable local commerce.
        </p>
      </div>

      <S>About {COMPANY}</S>
      <P>{COMPANY} is a technology company based in Hyderabad, Telangana, India. We build digital infrastructure for transportation and logistics. {BRAND} is our flagship smart mobility platform designed for Indian consumers, pilots, and enterprises.</P>
      <P>Our focus is simple: improve reliability, reduce wait times, increase pilot earnings visibility, and deliver safer journeys through OTP-first and data-driven operations.</P>

      <S>What is {BRAND}?</S>
      <P>{BRAND} is an end-to-end mobility and logistics platform that connects Customers with verified Pilots for:</P>
      <UL items={[
        "Ride-sharing: Bikes, autos, cars, SUVs — on demand, across the city",
        "Parcel delivery: Door-to-door parcel service with OTP verification and live tracking",
        "Cargo transportation: Small to medium cargo movement for businesses and individuals",
        "Intercity trips: Scheduled and on-demand intercity rides",
        "Car sharing: Shared rides for intercity or intracity routes",
      ]} />

      <S>Our Pilots</S>
      <P>We call our service providers "Pilots" because they navigate with skill, responsibility, and care. Every Pilot on the {BRAND} platform undergoes a thorough verification process including identity verification, document checks, and vehicle inspection before they can begin accepting trips.</P>
      <P>We support our Pilots with transparent earnings, daily payouts, performance-based rewards, and dedicated support. We treat Pilots as valued partners, not just service providers.</P>

      <S>Our Platform</S>
      <P>The {BRAND} platform is built on modern, scalable technology:</P>
      <UL items={[
        "Real-time GPS tracking with sub-second location updates",
        "OTP-secured pickup and delivery confirmation",
        "AI-assisted surge pricing based on real-time demand",
        "Multi-layer commission and earnings management",
        "In-app wallet with UPI integration and daily settlement",
        "SOS and emergency alert system for Pilot and Customer safety",
        "Comprehensive admin console for operators and fleet managers",
      ]} />

      <S>Our Values</S>
      <div className="policy-values-grid">
        {[
          { icon: "🛡️", title: "Safety First", desc: "Every trip is monitored. SOS alerts, live tracking, and emergency support are always available." },
          { icon: "🔍", title: "Transparency", desc: "Clear fare breakdowns, honest earnings statements, no hidden charges — ever." },
          { icon: "🤝", title: "Fair to All", desc: "We balance the interests of Customers, Pilots, and operators through clear, consistent policies." },
          { icon: "💡", title: "Continuous Innovation", desc: "We ship improvements regularly based on real user feedback and platform data." },
          { icon: "🌍", title: "Local Impact", desc: "By empowering Pilots, we support local livelihoods and strengthen community mobility networks." },
          { icon: "📊", title: "Data-Driven", desc: "Every decision is backed by data — from route optimisation to earnings fairness." },
        ].map(v => (
          <div key={v.title} style={{ background: "#f8fafc", borderRadius: 12, padding: "16px 18px", border: "1px solid #f1f5f9" }}>
            <div style={{ fontSize: 22, marginBottom: 6 }}>{v.icon}</div>
            <div style={{ fontSize: 13.5, fontWeight: 700, color: "#1e293b", marginBottom: 4 }}>{v.title}</div>
            <div style={{ fontSize: 12.5, color: "#64748b", lineHeight: 1.5 }}>{v.desc}</div>
          </div>
        ))}
      </div>

      <S>Get in Touch</S>
      <div className="policy-contact-grid">
        {[
          { icon: "📧", label: "Email", val: EMAIL, href: `mailto:${EMAIL}` },
          { icon: "🌐", label: "Website", val: WEBSITE, href: `https://${WEBSITE}` },
          { icon: "📍", label: "Office", val: ADDRESS },
          { icon: "🏢", label: "Company", val: COMPANY },
        ].map(({ icon, label, val, href }) => (
          <div key={label} style={{ background: "#f8fafc", borderRadius: 12, padding: "14px 16px", border: "1px solid #f1f5f9" }}>
            <div style={{ fontSize: 20, marginBottom: 4 }}>{icon}</div>
            <div style={{ fontSize: 10, color: "#94a3b8", fontWeight: 700, textTransform: "uppercase", letterSpacing: 0.5 }}>{label}</div>
            {href ? (
              <a href={href} style={{ fontSize: 13, fontWeight: 600, color: "#2563eb", marginTop: 3, display: "block", textDecoration: "none" }}>{val}</a>
            ) : (
              <div style={{ fontSize: 13, fontWeight: 600, color: "#1e293b", marginTop: 3 }}>{val}</div>
            )}
          </div>
        ))}
      </div>
    </PolicyLayout>
  );
}

/* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   CONTACT US
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */
export function ContactPage() {
  return (
    <PolicyLayout title="Contact Us" badge="Get in Touch">
      <P>We are here to help — whether you are a Customer, a Pilot, a business partner, or anyone curious about {BRAND}. Reach out through the appropriate channel below and our team will respond promptly.</P>

      <S>General Inquiries</S>
      <UL items={[
        `Email: ${EMAIL}`,
        `Website: ${WEBSITE}`,
        "Response time: Within 24 business hours (Mon–Sat)",
      ]} />

      <S>Customer Support</S>
      <P>For issues with bookings, payments, refunds, or account access:</P>
      <UL items={[
        `Email: ${EMAIL} (subject: Customer Support)`,
        "In-app chat: Available 7 days a week through the JAGO customer app",
        "Response time: Within 4 hours during business hours",
      ]} />

      <S>Pilot (Driver) Support</S>
      <P>For Pilot account issues, earnings queries, document verification, or platform policy questions:</P>
      <UL items={[
        `Email: ${EMAIL} (subject: Pilot Support)`,
        "In-app support: Available in the JAGO Pilot app under Help & Support",
        "Pilot-specific queries receive priority handling",
      ]} />

      <S>Business & Partnerships</S>
      <P>For B2B cargo partnerships, fleet operator onboarding, enterprise logistics, or API integration:</P>
      <UL items={[
        `Email: ${EMAIL} (subject: Business Inquiry)`,
        "We welcome partnerships that align with our mission of smart, accessible mobility",
      ]} />

      <S>Legal & Compliance</S>
      <P>For legal notices, DPDP Act data requests, regulatory queries, or intellectual property matters:</P>
      <UL items={[
        `Email: ${EMAIL} (subject: Legal)`,
        `Registered Address: ${COMPANY}, ${ADDRESS}`,
        "Please allow up to 7 business days for legal correspondence",
      ]} />

      <S>Privacy & Data Requests</S>
      <P>To exercise your data rights (access, correction, deletion, portability):</P>
      <UL items={[
        `Email: ${EMAIL} (subject: Privacy Request)`,
        "Include your registered mobile number and the nature of your request",
        "We will respond within 30 days as required by applicable law",
      ]} />

      <S>Connect With Us</S>
      <div style={{ display: "flex", gap: 12, flexWrap: "wrap", marginTop: 8 }}>
        {[
          { label: "Facebook", icon: "📘", href: `https://${WEBSITE}` },
          { label: "Instagram", icon: "📸", href: `https://${WEBSITE}` },
          { label: "Twitter / X", icon: "🐦", href: `https://${WEBSITE}` },
          { label: "LinkedIn", icon: "💼", href: `https://${WEBSITE}` },
        ].map(s => (
          <a key={s.label} href={s.href} style={{
            display: "flex", alignItems: "center", gap: 8,
            background: "#f8fafc", borderRadius: 10,
            padding: "10px 18px", textDecoration: "none",
            color: "#1e293b", fontWeight: 600, fontSize: 13,
            border: "1px solid #f1f5f9",
            transition: "background 0.15s",
          }} target="_blank" rel="noreferrer">
            <span>{s.icon}</span>{s.label}
          </a>
        ))}
      </div>

      <div style={{ marginTop: 28, padding: "16px 20px", background: "#f0fdf4", borderRadius: 12, border: "1px solid #bbf7d0" }}>
        <div style={{ fontSize: 13, fontWeight: 700, color: "#166534", marginBottom: 4 }}>Registered Company</div>
        <div style={{ fontSize: 13, color: "#15803d" }}>{COMPANY} · {ADDRESS}</div>
        <div style={{ fontSize: 13, color: "#15803d" }}>Email: <a href={`mailto:${EMAIL}`} style={{ color: "#16a34a" }}>{EMAIL}</a></div>
      </div>
    </PolicyLayout>
  );
}

/* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   REFUND POLICY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */
export function RefundPolicyPage() {
  return (
    <PolicyLayout title="Refund Policy" badge="Payments & Refunds">
      <InfoBox>
        This policy explains when refunds may be issued for rides and deliveries booked through {BRAND}, and how settlement timelines work.
      </InfoBox>

      <S>1. Scope</S>
      <P>This Refund Policy applies to transactions completed through the {BRAND} app and website, including rides, parcel deliveries, and eligible wallet payments.</P>

      <S>2. Refund Eligibility</S>
      <UL items={[
        "Duplicate charge for the same booking",
        "Failed trip where payment was collected but service was not rendered",
        "Verified fare mismatch caused by platform or technical error",
        "Booking canceled by the system after charge capture",
        "Any other case where refund is required by applicable law",
      ]} />

      <S>3. Non-Refundable Cases</S>
      <UL items={[
        "Completed trips or deliveries where service was successfully provided",
        "Customer cancellation after applicable free-cancel window",
        "Promotional credits, bonus credits, or expired offers unless law requires otherwise",
        "Wallet top-ups already consumed for completed services",
      ]} />

      <S>4. Cancellation Charges</S>
      <P>Cancellation fees may apply based on trip stage, pilot arrival status, and active cancellation policy shown at booking time. Any fee logic shown in the app at checkout is deemed part of this policy.</P>

      <S>5. Refund Processing Timeline</S>
      <UL items={[
        "Wallet refunds: typically instant to 24 hours",
        "UPI/bank/card source refunds: typically 3 to 7 business days",
        "Complex disputes requiring investigation: up to 15 business days",
      ]} />

      <S>6. Dispute Procedure</S>
      <P>Users should raise disputes through in-app support or by emailing <a href={`mailto:${EMAIL}`}>{EMAIL}</a> with booking ID, registered mobile number, and issue summary. We may request additional information for fraud prevention and verification.</P>

      <S>7. Fraud and Abuse Controls</S>
      <P>{COMPANY} may reject or reverse refund requests that are fraudulent, repetitive, or abusive. Accounts may be restricted where refund misuse, payment manipulation, or policy evasion is detected.</P>

      <S>8. Regulatory Priority</S>
      <P>Where applicable law requires a specific refund outcome or timeline, legal obligations will prevail over this policy.</P>

      <S>9. Contact</S>
      <P><strong>Email:</strong> <a href={`mailto:${EMAIL}`}>{EMAIL}</a><br /><strong>{COMPANY}</strong> · {ADDRESS}</P>
    </PolicyLayout>
  );
}

/* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   COOKIE POLICY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */
export function CookiePolicyPage() {
  return (
    <PolicyLayout title="Cookie Policy" badge="Web Tracking Disclosure">
      <InfoBox>
        This Cookie Policy describes how {BRAND} uses cookies and similar technologies on web surfaces, and the controls available to users.
      </InfoBox>

      <S>1. What Are Cookies?</S>
      <P>Cookies are small text files stored in your browser to help websites function correctly, preserve session state, and improve user experience.</P>

      <S>2. Cookies We Use</S>
      <UL items={[
        "Strictly Necessary Cookies: login session security, fraud protection, and route continuity",
        "Preference Cookies: language, interface, and consent state",
        "Performance Cookies: aggregated diagnostics for uptime and page performance",
      ]} />

      <S>3. Cookies We Do Not Use</S>
      <UL items={[
        "No third-party ad-targeting cookie networks for behavioural advertising",
        "No unauthorized sale of cookie-derived identifiers",
        "No cross-site profiling beyond permitted operational analytics",
      ]} />

      <S>4. Session and Security Controls</S>
      <P>Security cookies may be marked with strict attributes (for example, HttpOnly, Secure, SameSite where applicable) to reduce session hijacking and cross-site request risks.</P>

      <S>5. Your Choices</S>
      <UL items={[
        "Most browsers allow cookie blocking, deletion, and per-site control",
        "Blocking required cookies may break authentication and core site functionality",
        "You may clear local storage and cookies from browser settings at any time",
      ]} />

      <S>6. Retention</S>
      <P>Cookie duration depends on purpose: session cookies expire when the browser closes, while persistent preference cookies may remain until expiry or manual deletion.</P>

      <S>7. Updates to This Policy</S>
      <P>We may revise this Cookie Policy to reflect technology or legal updates. Material changes will be published on this page with an updated date.</P>

      <S>8. Contact</S>
      <P>For cookie and tracking questions, contact <a href={`mailto:${EMAIL}`}>{EMAIL}</a>.</P>
    </PolicyLayout>
  );
}
