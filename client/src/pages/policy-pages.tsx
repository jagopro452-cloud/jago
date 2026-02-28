import { useEffect } from "react";

function PolicyLayout({ title, children }: { title: string; children: React.ReactNode }) {
  useEffect(() => {
    document.title = `${title} — JAGO`;
    return () => { document.title = "JAGO"; };
  }, [title]);

  return (
    <div style={{ minHeight: "100vh", background: "#f8fafc", fontFamily: "'Inter', sans-serif" }}>
      {/* Nav */}
      <nav style={{ background: "#fff", borderBottom: "1px solid #e2e8f0", padding: "0 24px", height: 64, display: "flex", alignItems: "center", gap: 16, position: "sticky", top: 0, zIndex: 100, boxShadow: "0 1px 4px rgba(0,0,0,0.06)" }}>
        <a href="/" style={{ display: "flex", alignItems: "center", gap: 10, textDecoration: "none" }}>
          <img src="/jago-logo.png" alt="JAGO" style={{ height: 36, objectFit: "contain" }} />
        </a>
        <div style={{ flex: 1 }} />
        <a href="/" style={{ fontSize: 13, color: "#64748b", textDecoration: "none", fontWeight: 500 }}>← Back to Home</a>
      </nav>

      {/* Hero */}
      <div style={{ background: "linear-gradient(135deg, #1a73e8 0%, #7c3aed 100%)", color: "white", padding: "52px 24px 40px", textAlign: "center" }}>
        <div style={{ maxWidth: 720, margin: "0 auto" }}>
          <h1 style={{ fontSize: 32, fontWeight: 800, margin: 0, marginBottom: 10 }}>{title}</h1>
          <p style={{ fontSize: 15, opacity: 0.85, margin: 0 }}>Last updated: February 2026 · JAGO Mobility Pvt. Ltd.</p>
        </div>
      </div>

      {/* Content */}
      <div style={{ maxWidth: 820, margin: "0 auto", padding: "40px 24px 80px" }}>
        <div style={{ background: "white", borderRadius: 20, padding: "40px 44px", boxShadow: "0 4px 20px rgba(0,0,0,0.06)", lineHeight: 1.8, color: "#374151" }}>
          {children}
        </div>
      </div>

      {/* Footer */}
      <div style={{ background: "#1e293b", color: "rgba(255,255,255,0.5)", textAlign: "center", padding: "20px", fontSize: 13 }}>
        © {new Date().getFullYear()} JAGO Mobility Pvt. Ltd. ·
        <a href="/privacy" style={{ color: "rgba(255,255,255,0.6)", marginLeft: 12, textDecoration: "none" }}>Privacy Policy</a> ·
        <a href="/terms" style={{ color: "rgba(255,255,255,0.6)", marginLeft: 12, textDecoration: "none" }}>Terms</a> ·
        <a href="/about-us" style={{ color: "rgba(255,255,255,0.6)", marginLeft: 12, textDecoration: "none" }}>About</a>
      </div>
    </div>
  );
}

const S = ({ children }: { children: React.ReactNode }) => (
  <h3 style={{ fontSize: 18, fontWeight: 700, color: "#1e293b", marginTop: 32, marginBottom: 10, paddingBottom: 6, borderBottom: "2px solid #f1f5f9" }}>{children}</h3>
);
const P = ({ children }: { children: React.ReactNode }) => (
  <p style={{ margin: "0 0 14px", fontSize: 14.5, color: "#4b5563" }}>{children}</p>
);
const UL = ({ items }: { items: string[] }) => (
  <ul style={{ paddingLeft: 20, margin: "0 0 14px" }}>
    {items.map((it, i) => <li key={i} style={{ fontSize: 14.5, color: "#4b5563", marginBottom: 6 }}>{it}</li>)}
  </ul>
);

export function PrivacyPage() {
  return (
    <PolicyLayout title="Privacy Policy">
      <P>JAGO Mobility Pvt. Ltd. ("JAGO", "we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use the JAGO platform.</P>

      <S>1. Information We Collect</S>
      <P>We collect the following types of information:</P>
      <UL items={[
        "Personal identification: name, email address, phone number, profile photo",
        "Location data: GPS coordinates during trips for routing and safety",
        "Vehicle information: registration number, type, insurance details (drivers/pilots)",
        "Payment information: UPI IDs, bank account details for withdrawals",
        "Trip history: pickup/drop locations, fare, duration, ratings",
        "Device information: device ID, operating system, app version",
        "Communication data: chat messages, call logs within the platform",
      ]} />

      <S>2. How We Use Your Information</S>
      <UL items={[
        "To match customers with available pilots/drivers",
        "To process payments and manage wallet transactions",
        "To send trip updates, OTP verifications, and notifications",
        "To calculate fares, commissions, and driver earnings",
        "To improve platform safety and resolve disputes",
        "To comply with legal obligations and regulatory requirements",
        "To send promotional offers and service updates (with your consent)",
      ]} />

      <S>3. Information Sharing</S>
      <P>We do not sell your personal data. We may share information with:</P>
      <UL items={[
        "Pilots/Drivers: Customer name and pickup location for trip fulfillment",
        "Customers: Driver name, vehicle details, and real-time location during a trip",
        "Payment processors: For secure transaction handling",
        "Law enforcement: When required by applicable law",
        "Service providers: Cloud hosting, SMS, and analytics partners under strict confidentiality agreements",
      ]} />

      <S>4. Data Security</S>
      <P>We implement industry-standard security measures including SSL/TLS encryption, secure token-based authentication, and regular security audits. However, no method of transmission over the internet is 100% secure.</P>

      <S>5. Data Retention</S>
      <P>We retain your data as long as your account is active or as needed to provide services, comply with legal obligations, resolve disputes, and enforce our agreements. Trip data is retained for a minimum of 3 years.</P>

      <S>6. Your Rights</S>
      <UL items={[
        "Access: Request a copy of your personal data",
        "Correction: Update inaccurate or incomplete information",
        "Deletion: Request deletion of your account and associated data",
        "Portability: Receive your data in a machine-readable format",
        "Opt-out: Unsubscribe from marketing communications at any time",
      ]} />

      <S>7. Cookies</S>
      <P>Our web platform uses essential cookies for authentication and session management. We do not use tracking cookies for advertising purposes.</P>

      <S>8. Children's Privacy</S>
      <P>JAGO services are not directed to individuals under the age of 18. We do not knowingly collect personal information from children.</P>

      <S>9. Changes to This Policy</S>
      <P>We may update this Privacy Policy periodically. We will notify you of significant changes via email or in-app notification. Continued use of the platform after changes constitutes acceptance.</P>

      <S>10. Contact Us</S>
      <P>For privacy-related queries, contact us at: <strong>privacy@jago.in</strong> or write to JAGO Mobility Pvt. Ltd., Hyderabad, Telangana, India.</P>
    </PolicyLayout>
  );
}

export function TermsPage() {
  return (
    <PolicyLayout title="Terms & Conditions">
      <P>Welcome to JAGO. By accessing or using our platform, you agree to be bound by these Terms and Conditions. Please read them carefully before using the service.</P>

      <S>1. Acceptance of Terms</S>
      <P>By creating an account or using the JAGO platform (web, mobile app, or API), you agree to these Terms and our Privacy Policy. If you do not agree, please discontinue use immediately.</P>

      <S>2. Services Offered</S>
      <P>JAGO provides a technology platform connecting customers with independent pilots/drivers for:</P>
      <UL items={[
        "Ride-sharing services (bikes, autos, cars, SUVs)",
        "Parcel delivery and logistics",
        "Cargo transportation",
        "Intercity travel",
        "Car sharing and rental",
      ]} />

      <S>3. User Accounts</S>
      <UL items={[
        "You must be at least 18 years old to create an account",
        "You are responsible for maintaining the confidentiality of your login credentials",
        "You must provide accurate and up-to-date information during registration",
        "One person may not maintain multiple accounts",
        "JAGO reserves the right to suspend or terminate accounts for violations",
      ]} />

      <S>4. Pilot (Driver) Terms</S>
      <UL items={[
        "Must hold valid driving license and vehicle registration",
        "Must complete KYC verification before accepting trips",
        "Commission is deducted per trip as per the agreed revenue model",
        "Wallet balance below -₹100 may result in account lock",
        "Must maintain a minimum rating of 3.5 stars",
        "Must not cancel trips repeatedly without valid reason",
      ]} />

      <S>5. Fares and Payments</S>
      <P>Fares are calculated based on distance, vehicle type, time, and applicable surge pricing. JAGO collects platform fees from completed trips. All payments must be settled within the app. Cash on delivery is subject to availability.</P>

      <S>6. Cancellation Policy</S>
      <UL items={[
        "Customers may cancel before the pilot arrives without charge",
        "Cancellation fees may apply after the pilot reaches the pickup location",
        "Repeated cancellations may lead to temporary account restrictions",
        "Pilots cancelling after acceptance will receive a negative performance mark",
      ]} />

      <S>7. Wallet and Withdrawals</S>
      <UL items={[
        "Minimum withdrawal amount: ₹100",
        "Withdrawal processing time: 1-3 business days",
        "JAGO reserves the right to withhold payments pending dispute resolution",
        "Wallet bonuses are non-withdrawable unless specified",
      ]} />

      <S>8. Prohibited Conduct</S>
      <UL items={[
        "Fraud, misrepresentation, or impersonation",
        "Harassment or abuse of other users",
        "Manipulating the rating system",
        "Using the platform for illegal activities",
        "Reverse engineering or attempting to hack the platform",
      ]} />

      <S>9. Limitation of Liability</S>
      <P>JAGO is a technology platform and is not liable for the actions of independent pilots or customers. Our maximum liability is limited to the fare amount of the disputed trip.</P>

      <S>10. Governing Law</S>
      <P>These Terms are governed by the laws of India. Any disputes shall be subject to the exclusive jurisdiction of courts in Hyderabad, Telangana.</P>

      <S>11. Contact</S>
      <P>For legal queries: <strong>legal@jago.in</strong> · JAGO Mobility Pvt. Ltd., Hyderabad, Telangana, India.</P>
    </PolicyLayout>
  );
}

export function AboutPage() {
  return (
    <PolicyLayout title="About JAGO">
      <div style={{ textAlign: "center", marginBottom: 32 }}>
        <img src="/jago-logo.png" alt="JAGO" style={{ height: 64, objectFit: "contain", marginBottom: 16 }} />
        <p style={{ fontSize: 17, color: "#1e293b", fontWeight: 500, maxWidth: 560, margin: "0 auto" }}>
          Your Smart Logistics &amp; Mobility Platform — Powering seamless rides, deliveries, and fleet operations across India.
        </p>
      </div>

      <S>Our Story</S>
      <P>JAGO was founded with a simple mission: make urban mobility and logistics smarter, safer, and more accessible. From bustling city streets to intercity routes, JAGO connects people and packages with reliable pilots at the tap of a button.</P>

      <S>What We Do</S>
      <UL items={[
        "Ride-sharing: bikes, autos, cars, and SUVs on demand",
        "Parcel delivery with OTP verification and live tracking",
        "Cargo transportation for businesses",
        "Intercity car sharing and scheduled trips",
        "Real-time fleet management for operators",
      ]} />

      <S>Our Technology</S>
      <P>Built on cutting-edge technology, JAGO's platform includes real-time GPS tracking, AI-powered surge pricing, secure OTP-based delivery confirmation, multi-tier driver earnings management, and a comprehensive admin console for operators.</P>

      <S>Our Pilots (Drivers)</S>
      <P>We call our drivers "Pilots" — because they navigate the city with skill and precision. Every Pilot undergoes thorough KYC verification, background checks, and training before they can accept their first trip. We support our Pilots with transparent earnings, daily payouts, and dedicated support.</P>

      <S>Our Values</S>
      <UL items={[
        "Safety First: Every trip is monitored with live tracking and SOS features",
        "Transparency: Clear fare breakdowns, no hidden charges",
        "Reliability: 24/7 platform availability with real-time support",
        "Community: Supporting local drivers and building sustainable livelihoods",
        "Innovation: Constantly improving with technology and user feedback",
      ]} />

      <S>Reach Us</S>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14, marginTop: 8 }}>
        {[
          { icon: "📧", label: "Email", val: "support@jago.in" },
          { icon: "📞", label: "Phone", val: "+91 12345 67890" },
          { icon: "📍", label: "Address", val: "Hyderabad, Telangana, India" },
          { icon: "🌐", label: "Website", val: "jagopro.org" },
        ].map(({ icon, label, val }) => (
          <div key={label} style={{ background: "#f8fafc", borderRadius: 12, padding: "14px 16px", border: "1px solid #f1f5f9" }}>
            <div style={{ fontSize: 20, marginBottom: 4 }}>{icon}</div>
            <div style={{ fontSize: 11, color: "#94a3b8", fontWeight: 600, textTransform: "uppercase", letterSpacing: 0.5 }}>{label}</div>
            <div style={{ fontSize: 13, fontWeight: 600, color: "#1e293b", marginTop: 2 }}>{val}</div>
          </div>
        ))}
      </div>
    </PolicyLayout>
  );
}

export function ContactPage() {
  return (
    <PolicyLayout title="Contact Us">
      <P>Have a question, feedback, or need help? We're here for you. Reach out through any of the channels below.</P>

      <S>Customer Support</S>
      <UL items={[
        "Email: support@jago.in",
        "Phone: +91 12345 67890 (Mon–Sat, 9am–8pm IST)",
        "In-app chat: Available 24/7 through the JAGO app",
      ]} />

      <S>Pilot / Driver Support</S>
      <UL items={[
        "Email: pilots@jago.in",
        "Dedicated helpline: +91 12345 99999 (24/7)",
        "Visit the Pilot Support section in your Driver App",
      ]} />

      <S>Business & Partnerships</S>
      <UL items={[
        "Email: business@jago.in",
        "For B2B cargo and fleet solutions: cargo@jago.in",
      ]} />

      <S>Legal & Privacy</S>
      <UL items={[
        "Privacy queries: privacy@jago.in",
        "Legal notices: legal@jago.in",
        "Registered Office: JAGO Mobility Pvt. Ltd., Hyderabad, Telangana, India",
      ]} />

      <S>Social Media</S>
      <div style={{ display: "flex", gap: 12, flexWrap: "wrap", marginTop: 8 }}>
        {[
          { label: "Facebook", href: "#", icon: "📘" },
          { label: "Instagram", href: "#", icon: "📸" },
          { label: "Twitter/X", href: "#", icon: "🐦" },
          { label: "LinkedIn", href: "#", icon: "💼" },
        ].map(s => (
          <a key={s.label} href={s.href} style={{ display: "flex", alignItems: "center", gap: 8, background: "#f8fafc", borderRadius: 10, padding: "10px 16px", textDecoration: "none", color: "#1e293b", fontWeight: 600, fontSize: 13, border: "1px solid #f1f5f9" }}>
            <span>{s.icon}</span> {s.label}
          </a>
        ))}
      </div>
    </PolicyLayout>
  );
}
