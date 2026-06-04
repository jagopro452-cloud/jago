-- ============================================================
-- Migration 0010: Zone-wise Franchise System
-- ============================================================

CREATE TABLE IF NOT EXISTS franchisees (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                  VARCHAR(255) NOT NULL,
  owner_name            VARCHAR(255) NOT NULL,
  email                 VARCHAR(191) NOT NULL UNIQUE,
  password              VARCHAR(255) NOT NULL,
  phone                 VARCHAR(20),
  zone_id               UUID REFERENCES zones(id) ON DELETE SET NULL,
  commission_type       VARCHAR(20) NOT NULL DEFAULT 'percentage',
  commission_percent    NUMERIC(5,2) NOT NULL DEFAULT 10.00,
  commission_flat       NUMERIC(10,2) NOT NULL DEFAULT 0.00,
  is_active             BOOLEAN NOT NULL DEFAULT true,
  auth_token            TEXT,
  auth_token_expires_at TIMESTAMP,
  last_login_at         TIMESTAMP,
  created_at            TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_franchisees_zone ON franchisees(zone_id);
CREATE INDEX IF NOT EXISTS idx_franchisees_active ON franchisees(is_active);
