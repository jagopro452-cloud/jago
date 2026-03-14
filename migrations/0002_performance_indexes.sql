-- Add attempt_count to otp_logs for brute force protection
ALTER TABLE otp_logs ADD COLUMN IF NOT EXISTS attempt_count INT DEFAULT 0;

-- Performance indexes for high-volume query patterns
-- trip_requests: most frequently queried table across all endpoints
CREATE INDEX IF NOT EXISTS idx_trip_requests_driver_id ON trip_requests(driver_id);
CREATE INDEX IF NOT EXISTS idx_trip_requests_customer_id ON trip_requests(customer_id);
CREATE INDEX IF NOT EXISTS idx_trip_requests_current_status ON trip_requests(current_status);
CREATE INDEX IF NOT EXISTS idx_trip_requests_status_created ON trip_requests(current_status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_trip_requests_driver_status ON trip_requests(driver_id, current_status);
CREATE INDEX IF NOT EXISTS idx_trip_requests_customer_status ON trip_requests(customer_id, current_status);
CREATE INDEX IF NOT EXISTS idx_trip_requests_coupon_code ON trip_requests(coupon_code) WHERE coupon_code IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_trip_requests_created_at ON trip_requests(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_trip_requests_ref_id ON trip_requests(ref_id);

-- users: phone lookup is critical for auth
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_user_type ON users(user_type);
CREATE INDEX IF NOT EXISTS idx_users_user_type_active ON users(user_type, is_active);
CREATE INDEX IF NOT EXISTS idx_users_referral_code ON users(referral_code) WHERE referral_code IS NOT NULL;

-- driver_payments: used heavily in wallet/financial queries
CREATE INDEX IF NOT EXISTS idx_driver_payments_driver_id ON driver_payments(driver_id);
CREATE INDEX IF NOT EXISTS idx_driver_payments_driver_created ON driver_payments(driver_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_driver_payments_razorpay_order ON driver_payments(razorpay_order_id) WHERE razorpay_order_id IS NOT NULL;

-- commission_settlements: financial history queries
CREATE INDEX IF NOT EXISTS idx_commission_settlements_driver_id ON commission_settlements(driver_id);
CREATE INDEX IF NOT EXISTS idx_commission_settlements_driver_created ON commission_settlements(driver_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_commission_settlements_trip_id ON commission_settlements(trip_id) WHERE trip_id IS NOT NULL;

-- driver_locations: real-time nearby driver queries
CREATE INDEX IF NOT EXISTS idx_driver_locations_driver_id ON driver_locations(driver_id);
CREATE INDEX IF NOT EXISTS idx_driver_locations_lat_lng ON driver_locations(lat, lng) WHERE is_online = true;

-- notifications: per-user notification queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- admin_login_otp: admin OTP lookup
CREATE INDEX IF NOT EXISTS idx_admin_login_otp_admin_id ON admin_login_otp(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_login_otp_expires ON admin_login_otp(expires_at);

-- heatmap_events: time-range queries for grid computation
CREATE INDEX IF NOT EXISTS idx_heatmap_events_created_at ON heatmap_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_heatmap_events_type_created ON heatmap_events(event_type, created_at DESC);

-- heatmap_grid_cache: demand score filtering + ordering
CREATE INDEX IF NOT EXISTS idx_heatmap_grid_demand_level ON heatmap_grid_cache(demand_level);
CREATE INDEX IF NOT EXISTS idx_heatmap_grid_demand_score ON heatmap_grid_cache(demand_score DESC);
CREATE INDEX IF NOT EXISTS idx_heatmap_grid_updated_at ON heatmap_grid_cache(updated_at DESC);

-- coupon_setups: code lookup
CREATE INDEX IF NOT EXISTS idx_coupon_setups_code ON coupon_setups(code);
CREATE INDEX IF NOT EXISTS idx_coupon_setups_active ON coupon_setups(is_active) WHERE is_active = true;

-- parcel_requests: driver/customer/status lookups
CREATE INDEX IF NOT EXISTS idx_parcel_requests_driver_id ON parcel_requests(driver_id) WHERE driver_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_parcel_requests_customer_id ON parcel_requests(customer_id);
CREATE INDEX IF NOT EXISTS idx_parcel_requests_status ON parcel_requests(status);
