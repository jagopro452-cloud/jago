import { Link } from "wouter";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Car, Package, MapPin, Star, Shield, Clock, ChevronRight, Menu, X, Smartphone } from "lucide-react";
import { useState } from "react";

const stats = [
  { label: "Active Users", value: "2M+", color: "text-blue-600" },
  { label: "Cities Covered", value: "50+", color: "text-green-600" },
  { label: "Rides Completed", value: "10M+", color: "text-amber-600" },
  { label: "Driver Partners", value: "100K+", color: "text-purple-600" },
];

const services = [
  { icon: Car, title: "Bike Rides", desc: "Quick and affordable bike taxis for daily commute", color: "bg-blue-50 text-blue-600" },
  { icon: Car, title: "Auto Rides", desc: "Comfortable auto rickshaw rides across the city", color: "bg-green-50 text-green-600" },
  { icon: Car, title: "Car Rides", desc: "Premium car rides for comfortable travel", color: "bg-amber-50 text-amber-600" },
  { icon: Package, title: "Parcel Delivery", desc: "Same-day parcel delivery with real-time tracking", color: "bg-purple-50 text-purple-600" },
];

const features = [
  { icon: MapPin, title: "Real-Time Tracking", desc: "Track your ride live on the map with accurate ETA" },
  { icon: Shield, title: "Safe & Secure", desc: "Verified drivers, SOS button, and 24/7 support" },
  { icon: Clock, title: "Instant Booking", desc: "Book a ride in under 30 seconds, driver arrives fast" },
  { icon: Star, title: "Top Rated Drivers", desc: "Only 4.5+ rated drivers serve on our platform" },
];

export default function LandingPage() {
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <div className="min-h-screen bg-white dark:bg-gray-950 font-sans">
      {/* Navbar */}
      <nav className="sticky top-0 z-50 border-b bg-white/95 dark:bg-gray-950/95 backdrop-blur-sm dark:border-gray-800">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16 gap-4">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-blue-600 flex items-center justify-center">
                <Car className="w-5 h-5 text-white" />
              </div>
              <span className="text-xl font-bold text-gray-900 dark:text-white">JAGO</span>
            </div>
            <div className="hidden md:flex items-center gap-8">
              {["Services", "How It Works", "About", "Blog"].map(item => (
                <a key={item} href="#" className="text-sm text-gray-600 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 transition-colors">{item}</a>
              ))}
            </div>
            <div className="hidden md:flex items-center gap-3">
              <Link href="/admin/login">
                <Button variant="outline" size="sm" data-testid="btn-admin-login">Admin Panel</Button>
              </Link>
              <Button size="sm" className="bg-blue-600 hover:bg-blue-700 text-white" data-testid="btn-download-app">Download App</Button>
            </div>
            <button className="md:hidden p-2" onClick={() => setMenuOpen(!menuOpen)} data-testid="btn-mobile-menu">
              {menuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>
          </div>
          {menuOpen && (
            <div className="md:hidden py-4 border-t dark:border-gray-800 flex flex-col gap-4">
              {["Services", "How It Works", "About", "Blog"].map(item => (
                <a key={item} href="#" className="text-sm text-gray-600 dark:text-gray-300 px-2">{item}</a>
              ))}
              <Link href="/admin/login"><Button variant="outline" size="sm" className="w-fit">Admin Panel</Button></Link>
            </div>
          )}
        </div>
      </nav>

      {/* Hero */}
      <section className="relative overflow-hidden bg-gradient-to-br from-blue-600 via-blue-700 to-blue-900 text-white">
        <div className="absolute inset-0 opacity-10">
          <div className="absolute top-10 right-10 w-72 h-72 rounded-full bg-white" />
          <div className="absolute bottom-0 left-20 w-48 h-48 rounded-full bg-white" />
        </div>
        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 lg:py-28">
          <div className="max-w-3xl">
            <Badge className="mb-4 bg-white/20 text-white border-white/30 hover:bg-white/25" data-testid="badge-tagline">
              India's Smart Mobility Platform
            </Badge>
            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold leading-tight mb-6" data-testid="hero-title">
              Rides & Deliveries<br />at Your Fingertips
            </h1>
            <p className="text-lg sm:text-xl text-blue-100 mb-8 max-w-xl" data-testid="hero-subtitle">
              Book auto, bike, and car rides instantly. Send parcels across the city with real-time tracking. Download JAGO now!
            </p>
            <div className="flex flex-wrap gap-4 mb-12">
              <Button size="lg" className="bg-white text-blue-700 hover:bg-blue-50" data-testid="btn-play-store">
                <Smartphone className="w-5 h-5 mr-2" /> Play Store
              </Button>
              <Button size="lg" variant="outline" className="border-white text-white bg-white/10 hover:bg-white/20" data-testid="btn-app-store">
                <Smartphone className="w-5 h-5 mr-2" /> App Store
              </Button>
            </div>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-6">
              {stats.map(s => (
                <div key={s.label} className="text-center" data-testid={`stat-${s.label.toLowerCase().replace(/\s+/g, '-')}`}>
                  <div className="text-2xl sm:text-3xl font-bold text-white">{s.value}</div>
                  <div className="text-sm text-blue-200 mt-1">{s.label}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* Services */}
      <section className="py-20 bg-gray-50 dark:bg-gray-900">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-3">Our Services</h2>
            <p className="text-gray-500 dark:text-gray-400 max-w-xl mx-auto">Everything you need for commuting and delivery, all in one app</p>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {services.map(s => (
              <div key={s.title} className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm border dark:border-gray-700 hover:shadow-md transition-shadow" data-testid={`service-card-${s.title.toLowerCase().replace(/\s+/g, '-')}`}>
                <div className={`w-12 h-12 rounded-xl ${s.color} flex items-center justify-center mb-4`}>
                  <s.icon className="w-6 h-6" />
                </div>
                <h3 className="font-semibold text-gray-900 dark:text-white mb-2">{s.title}</h3>
                <p className="text-sm text-gray-500 dark:text-gray-400">{s.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* How it works */}
      <section className="py-20 bg-white dark:bg-gray-950">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-3">How It Works</h2>
            <p className="text-gray-500 dark:text-gray-400">Book a ride in 3 simple steps</p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {[
              { step: "01", title: "Enter Destination", desc: "Type your pickup and drop location in the app" },
              { step: "02", title: "Choose Vehicle", desc: "Select from bike, auto, or car options" },
              { step: "03", title: "Ride & Pay", desc: "Your driver arrives, ride safely, and pay digitally" },
            ].map(item => (
              <div key={item.step} className="text-center" data-testid={`step-${item.step}`}>
                <div className="w-16 h-16 rounded-full bg-blue-600 text-white text-xl font-bold flex items-center justify-center mx-auto mb-4">{item.step}</div>
                <h3 className="font-semibold text-gray-900 dark:text-white text-lg mb-2">{item.title}</h3>
                <p className="text-sm text-gray-500 dark:text-gray-400">{item.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="py-20 bg-gray-50 dark:bg-gray-900">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-3">Why Choose JAGO?</h2>
            <p className="text-gray-500 dark:text-gray-400">Built for safety, speed, and reliability</p>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {features.map(f => (
              <div key={f.title} className="flex flex-col items-start gap-3 p-6 bg-white dark:bg-gray-800 rounded-xl border dark:border-gray-700" data-testid={`feature-${f.title.toLowerCase().replace(/\s+/g, '-')}`}>
                <div className="w-10 h-10 rounded-lg bg-blue-50 dark:bg-blue-900/30 flex items-center justify-center">
                  <f.icon className="w-5 h-5 text-blue-600" />
                </div>
                <h3 className="font-semibold text-gray-900 dark:text-white">{f.title}</h3>
                <p className="text-sm text-gray-500 dark:text-gray-400">{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-20 bg-blue-600">
        <div className="max-w-3xl mx-auto px-4 text-center">
          <h2 className="text-3xl font-bold text-white mb-4">Ready to Ride with JAGO?</h2>
          <p className="text-blue-100 mb-8">Join millions of happy riders. Download the app now and get your first ride free!</p>
          <div className="flex flex-wrap gap-4 justify-center">
            <Button size="lg" className="bg-white text-blue-700 hover:bg-blue-50" data-testid="cta-play-store">Get it on Play Store</Button>
            <Button size="lg" variant="outline" className="border-white text-white bg-white/10 hover:bg-white/20" data-testid="cta-app-store">Download on App Store</Button>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-gray-400 py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8 mb-8">
            <div className="col-span-2 md:col-span-1">
              <div className="flex items-center gap-2 mb-4">
                <div className="w-8 h-8 rounded-lg bg-blue-600 flex items-center justify-center">
                  <Car className="w-4 h-4 text-white" />
                </div>
                <span className="text-white font-bold">JAGO</span>
              </div>
              <p className="text-sm">India's smart mobility platform for rides and deliveries.</p>
            </div>
            {[
              { title: "Company", links: ["About Us", "Careers", "Press", "Blog"] },
              { title: "Services", links: ["Bike Rides", "Auto Rides", "Car Rides", "Parcel Delivery"] },
              { title: "Support", links: ["Help Center", "Safety", "Terms", "Privacy"] },
            ].map(col => (
              <div key={col.title}>
                <h4 className="text-white font-semibold mb-4">{col.title}</h4>
                <ul className="space-y-2">
                  {col.links.map(link => <li key={link}><a href="#" className="text-sm hover:text-white transition-colors">{link}</a></li>)}
                </ul>
              </div>
            ))}
          </div>
          <div className="border-t border-gray-800 pt-8 text-center text-sm">
            <p>&copy; 2025 JAGO. All rights reserved. | Hyderabad, India</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
