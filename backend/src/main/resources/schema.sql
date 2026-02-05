-- ============================================
-- 🌾 CROP INSURANCE SYSTEM - DATABASE SCHEMA
-- ============================================
-- Run this in PostgreSQL to create the database
-- ============================================

-- Create database (run as superuser)
-- CREATE DATABASE crop_insurance_db;

-- Switch to database
-- \c crop_insurance_db

-- ============================================
-- MASTER DATA TABLES
-- ============================================

-- States
CREATE TABLE IF NOT EXISTS states (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    code VARCHAR(5) UNIQUE NOT NULL
);

-- Districts
CREATE TABLE IF NOT EXISTS districts (
    id SERIAL PRIMARY KEY,
    state_id INTEGER NOT NULL REFERENCES states(id),
    name VARCHAR(50) NOT NULL,
    UNIQUE(state_id, name)
);

-- Villages (with GPS center)
CREATE TABLE IF NOT EXISTS villages (
    id SERIAL PRIMARY KEY,
    district_id INTEGER NOT NULL REFERENCES districts(id),
    name VARCHAR(50) NOT NULL,
    center_latitude DECIMAL(10, 8) NOT NULL,
    center_longitude DECIMAL(11, 8) NOT NULL,
    UNIQUE(district_id, name)
);

-- Khasra Registry (pre-filled land records)
CREATE TABLE IF NOT EXISTS khasra_registry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    village_id INTEGER NOT NULL REFERENCES villages(id),
    khasra_number VARCHAR(20) NOT NULL,
    area_acres DECIMAL(10, 2) NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    owner_name VARCHAR(100) DEFAULT 'Available',
    is_registered BOOLEAN DEFAULT FALSE,
    UNIQUE(village_id, khasra_number)
);

-- Crop Types
CREATE TABLE IF NOT EXISTS crop_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    name_hindi VARCHAR(50),
    season VARCHAR(20),
    premium_rate DECIMAL(5, 2),  -- % of coverage
    max_coverage DECIMAL(12, 2)  -- Maximum coverage amount
);

-- ============================================
-- USER TABLES
-- ============================================

-- Farmers
CREATE TABLE IF NOT EXISTS farmers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(15) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    state VARCHAR(50) NOT NULL,
    district VARCHAR(50) NOT NULL,
    village VARCHAR(50) NOT NULL,
    profile_image VARCHAR(255),
    fcm_token VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Patwaris (Government officials)
CREATE TABLE IF NOT EXISTS patwaris (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    government_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    assigned_area VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- OTP Records
CREATE TABLE IF NOT EXISTS otp_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(15) NOT NULL,
    otp VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- SENSOR TABLES
-- ============================================

-- Sensors
CREATE TABLE IF NOT EXISTS sensors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unique_code VARCHAR(20) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_reading_at TIMESTAMP,
    installed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sensor Readings
CREATE TABLE IF NOT EXISTS sensor_readings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sensor_id UUID NOT NULL REFERENCES sensors(id),
    soil_moisture DECIMAL(5, 2),
    humidity DECIMAL(5, 2),
    temperature DECIMAL(5, 2),
    rainfall DECIMAL(5, 2),
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- LAND & INSURANCE TABLES
-- ============================================

-- Registered Lands
CREATE TABLE IF NOT EXISTS lands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farmer_id UUID NOT NULL REFERENCES farmers(id),
    khasra_number VARCHAR(50) UNIQUE NOT NULL,
    area_acres DECIMAL(10, 2) NOT NULL,
    crop_type VARCHAR(50),
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    sensor_id UUID REFERENCES sensors(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insurance Policies
CREATE TABLE IF NOT EXISTS insurance_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farmer_id UUID NOT NULL REFERENCES farmers(id),
    land_id UUID NOT NULL REFERENCES lands(id),
    policy_number VARCHAR(20) UNIQUE NOT NULL,
    premium_amount DECIMAL(10, 2) NOT NULL,
    coverage_amount DECIMAL(12, 2) NOT NULL,
    crop_type VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    razorpay_order_id VARCHAR(100),
    razorpay_payment_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Verifications (by Patwari)
CREATE TABLE IF NOT EXISTS verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    insurance_id UUID UNIQUE NOT NULL REFERENCES insurance_policies(id),
    patwari_id UUID REFERENCES patwaris(id),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    remarks TEXT,
    assigned_sensor_id UUID,
    verified_at TIMESTAMP
);

-- ============================================
-- CLAIMS TABLES
-- ============================================

-- Claims
CREATE TABLE IF NOT EXISTS claims (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    insurance_id UUID NOT NULL REFERENCES insurance_policies(id),
    farmer_id UUID NOT NULL REFERENCES farmers(id),
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    sensor_id UUID REFERENCES sensors(id),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    damage_percentage DECIMAL(5, 2),
    claim_amount DECIMAL(12, 2),
    filed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP
);

-- Claim Images
CREATE TABLE IF NOT EXISTS claim_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id UUID NOT NULL REFERENCES claims(id),
    image_path VARCHAR(255) NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    captured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- AI Assessments
CREATE TABLE IF NOT EXISTS ai_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id UUID UNIQUE NOT NULL REFERENCES claims(id),
    damage_percentage DECIMAL(5, 2) NOT NULL,
    model_version VARCHAR(20) NOT NULL,
    prediction_details JSONB,
    assessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- NOTIFICATIONS
-- ============================================

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farmer_id UUID NOT NULL REFERENCES farmers(id),
    title VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    type VARCHAR(20) DEFAULT 'GENERAL',
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_farmers_phone ON farmers(phone);
CREATE INDEX IF NOT EXISTS idx_lands_farmer ON lands(farmer_id);
CREATE INDEX IF NOT EXISTS idx_insurance_farmer ON insurance_policies(farmer_id);
CREATE INDEX IF NOT EXISTS idx_insurance_status ON insurance_policies(status);
CREATE INDEX IF NOT EXISTS idx_claims_farmer ON claims(farmer_id);
CREATE INDEX IF NOT EXISTS idx_claims_status ON claims(status);
CREATE INDEX IF NOT EXISTS idx_notifications_farmer ON notifications(farmer_id);
CREATE INDEX IF NOT EXISTS idx_sensor_readings_sensor ON sensor_readings(sensor_id);
CREATE INDEX IF NOT EXISTS idx_khasra_village ON khasra_registry(village_id);

-- Success message
SELECT 'Database schema created successfully!' as status;
