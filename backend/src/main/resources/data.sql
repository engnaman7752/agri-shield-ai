-- ============================================
-- 🌾 CROP INSURANCE SYSTEM - SEED DATA
-- ============================================
-- Run this AFTER schema.sql
-- Includes YOUR phone number: 8440071773
-- ============================================

-- ============================================
-- STATES
-- ============================================
INSERT INTO states (name, code) VALUES
    ('Madhya Pradesh', 'MP'),
    ('Maharashtra', 'MH'),
    ('Uttar Pradesh', 'UP'),
    ('Rajasthan', 'RJ'),
    ('Gujarat', 'GJ')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- DISTRICTS
-- ============================================
-- Madhya Pradesh
INSERT INTO districts (state_id, name) 
SELECT s.id, d.name FROM states s,
(VALUES ('Bhopal'), ('Indore'), ('Jabalpur'), ('Gwalior')) AS d(name)
WHERE s.code = 'MP'
ON CONFLICT DO NOTHING;

-- Rajasthan (YOUR LOCATION)
INSERT INTO districts (state_id, name) 
SELECT s.id, d.name FROM states s,
(VALUES ('Kota'), ('Jaipur'), ('Udaipur'), ('Jodhpur')) AS d(name)
WHERE s.code = 'RJ'
ON CONFLICT DO NOTHING;

-- Maharashtra
INSERT INTO districts (state_id, name) 
SELECT s.id, d.name FROM states s,
(VALUES ('Pune'), ('Nagpur'), ('Mumbai')) AS d(name)
WHERE s.code = 'MH'
ON CONFLICT DO NOTHING;

-- ============================================
-- VILLAGES (with GPS coordinates)
-- ============================================

-- Ranpur, Kota (YOUR LOCATION - 25.0831, 75.8621)
INSERT INTO villages (district_id, name, center_latitude, center_longitude)
SELECT d.id, v.name, v.lat, v.lng
FROM districts d
JOIN states s ON d.state_id = s.id,
(VALUES 
    ('Ranpur', 25.0831, 75.8621),
    ('Itawa', 25.0912, 75.8534),
    ('Mandana', 25.0756, 75.8712),
    ('Sultanpur', 25.0780, 75.8550)
) AS v(name, lat, lng)
WHERE s.code = 'RJ' AND d.name = 'Kota'
ON CONFLICT DO NOTHING;

-- Bhopal villages
INSERT INTO villages (district_id, name, center_latitude, center_longitude)
SELECT d.id, v.name, v.lat, v.lng
FROM districts d
JOIN states s ON d.state_id = s.id,
(VALUES 
    ('Khajuri Kalan', 23.2820, 77.4595),
    ('Ratibad', 23.1890, 77.3865),
    ('Berasia', 23.6350, 77.4320)
) AS v(name, lat, lng)
WHERE s.code = 'MP' AND d.name = 'Bhopal'
ON CONFLICT DO NOTHING;

-- ============================================
-- KHASRA REGISTRY (Your Demo Location)
-- ============================================

-- Ranpur Khasra entries (for YOUR demo)
INSERT INTO khasra_registry (village_id, khasra_number, area_acres, latitude, longitude)
SELECT v.id, k.khasra, k.area, k.lat, k.lng
FROM villages v
JOIN districts d ON v.district_id = d.id
JOIN states s ON d.state_id = s.id,
(VALUES 
    ('RN-101/1', 5.50, 25.0831, 75.8621),
    ('RN-101/2', 3.25, 25.0835, 75.8625),
    ('RN-102/1', 7.00, 25.0828, 75.8618),
    ('RN-102/2', 4.75, 25.0840, 75.8630),
    ('RN-103/1', 6.00, 25.0825, 75.8615),
    ('RN-201/1', 8.00, 25.0850, 75.8640),
    ('RN-201/2', 5.25, 25.0810, 75.8600),
    ('DEMO-001', 10.00, 25.0845, 75.8632)
) AS k(khasra, area, lat, lng)
WHERE v.name = 'Ranpur' AND s.code = 'RJ'
ON CONFLICT DO NOTHING;

-- Bhopal Khasra entries
INSERT INTO khasra_registry (village_id, khasra_number, area_acres, latitude, longitude)
SELECT v.id, k.khasra, k.area, k.lat, k.lng
FROM villages v
JOIN districts d ON v.district_id = d.id
JOIN states s ON d.state_id = s.id,
(VALUES 
    ('KH-101/1', 5.50, 23.2820, 77.4595),
    ('KH-101/2', 3.25, 23.2825, 77.4600),
    ('KH-102/1', 7.00, 23.2830, 77.4585),
    ('KH-102/2', 4.50, 23.2815, 77.4590)
) AS k(khasra, area, lat, lng)
WHERE v.name = 'Khajuri Kalan' AND s.code = 'MP'
ON CONFLICT DO NOTHING;

-- ============================================
-- CROP TYPES
-- ============================================
INSERT INTO crop_types (name, name_hindi, season, premium_rate, max_coverage) VALUES
    ('Wheat', 'गेहूं', 'Rabi', 2.00, 50000.00),
    ('Rice', 'चावल', 'Kharif', 2.50, 60000.00),
    ('Corn', 'मक्का', 'Kharif', 2.00, 45000.00),
    ('Soybean', 'सोयाबीन', 'Kharif', 2.50, 55000.00),
    ('Cotton', 'कपास', 'Kharif', 3.00, 70000.00),
    ('Potato', 'आलू', 'Rabi', 2.00, 40000.00),
    ('Tomato', 'टमाटर', 'All', 2.50, 45000.00),
    ('Mustard', 'सरसों', 'Rabi', 1.80, 35000.00),
    ('Sugarcane', 'गन्ना', 'All', 3.00, 80000.00),
    ('Groundnut', 'मूंगफली', 'Kharif', 2.20, 50000.00)
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- SENSORS (Available for assignment)
-- ============================================
INSERT INTO sensors (unique_code) VALUES
    ('SENS-001'),
    ('SENS-002'),
    ('SENS-003'),
    ('SENS-004'),
    ('SENS-005'),
    ('SENS-006'),
    ('SENS-007'),
    ('SENS-008'),
    ('SENS-009'),
    ('SENS-010'),
    ('SENS-011'),
    ('SENS-012'),
    ('SENS-013'),
    ('SENS-014'),
    ('SENS-015')
ON CONFLICT (unique_code) DO NOTHING;

-- ============================================
-- DEMO FARMER (YOUR PHONE NUMBER!)
-- ============================================
INSERT INTO farmers (phone, name, address, state, district, village, account_holder_name, bank_name, account_number, ifsc_code) VALUES
    ('8440071773', 'Demo Farmer (Your Phone)', 'Ranpur, Kota', 'Rajasthan', 'Kota', 'Ranpur', 'Manish Meena', 'State Bank of India', '30291827364', 'SBIN0001234')
ON CONFLICT (phone) DO NOTHING;

-- Other test farmers
INSERT INTO farmers (phone, name, address, state, district, village) VALUES
    ('9999900001', 'Ramesh Kumar', 'Village Khajuri Kalan', 'Madhya Pradesh', 'Bhopal', 'Khajuri Kalan'),
    ('9999900002', 'Suresh Patel', 'Village Ratibad', 'Madhya Pradesh', 'Bhopal', 'Ratibad'),
    ('9999900003', 'Mahesh Singh', 'Village Ranpur', 'Rajasthan', 'Kota', 'Ranpur'),
    ('9999900004', 'Dinesh Sharma', 'Village Itawa', 'Rajasthan', 'Kota', 'Itawa'),
    ('9999900005', 'Ganesh Verma', 'Village Mandana', 'Rajasthan', 'Kota', 'Mandana')
ON CONFLICT (phone) DO NOTHING;

-- ============================================
-- PATWARIS (Government officials)
-- ============================================
-- Password: password123 (BCrypt hash)
INSERT INTO patwaris (government_id, name, phone, password_hash, assigned_area) VALUES
    ('PAT-RJ-001', 'Shyam Lal (Kota)', '9876500001', 
     '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Kota, Rajasthan'),
    ('PAT-MP-001', 'Raghunath Rao (Bhopal)', '9876500002', 
     '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Bhopal, MP'),
    ('PAT-MP-002', 'Kishan Das (Indore)', '9876500003', 
     '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Indore, MP')
ON CONFLICT (government_id) DO NOTHING;

-- ============================================
-- DEMO CREDENTIALS SUMMARY
-- ============================================
SELECT '========================================' as info;
SELECT '  DEMO LOGIN CREDENTIALS' as info;
SELECT '========================================' as info;
SELECT 'FARMER LOGIN (Phone + OTP):' as info;
SELECT '  Your Phone: 8440071773 | OTP: 123456' as info;
SELECT '  Test Phone: 9999900001 | OTP: 123456' as info;
SELECT '' as info;
SELECT 'PATWARI LOGIN (GovtID + Password):' as info;
SELECT '  Kota:   PAT-RJ-001 | password123' as info;
SELECT '  Bhopal: PAT-MP-001 | password123' as info;
SELECT '========================================' as info;

-- ============================================
-- DEMO: PRE-APPROVED INSURANCE WITH SENSORS
-- ============================================
-- This creates ready-to-use insurance for demo

-- First, create lands for demo farmer
INSERT INTO lands (id, farmer_id, khasra_number, area_acres, crop_type, latitude, longitude, sensor_id)
SELECT 
    gen_random_uuid(),
    f.id,
    'RN-101/1',
    5.50,
    'Wheat',
    25.0831,
    75.8621,
    (SELECT id FROM sensors WHERE unique_code = 'SENS-001' LIMIT 1)
FROM farmers f WHERE f.phone = '8440071773'
ON CONFLICT (khasra_number) DO NOTHING;

INSERT INTO lands (id, farmer_id, khasra_number, area_acres, crop_type, latitude, longitude, sensor_id)
SELECT 
    gen_random_uuid(),
    f.id,
    'RN-102/1',
    7.00,
    'Rice',
    25.0828,
    75.8618,
    (SELECT id FROM sensors WHERE unique_code = 'SENS-002' LIMIT 1)
FROM farmers f WHERE f.phone = '8440071773'
ON CONFLICT (khasra_number) DO NOTHING;

INSERT INTO lands (id, farmer_id, khasra_number, area_acres, crop_type, latitude, longitude, sensor_id)
SELECT 
    gen_random_uuid(),
    f.id,
    'DEMO-001',
    10.00,
    'Soybean',
    25.0845,
    75.8632,
    (SELECT id FROM sensors WHERE unique_code = 'SENS-003' LIMIT 1)
FROM farmers f WHERE f.phone = '8440071773'
ON CONFLICT (khasra_number) DO NOTHING;

-- Create active insurance policies
INSERT INTO insurance_policies (id, farmer_id, land_id, policy_number, premium_amount, coverage_amount, crop_type, start_date, end_date, status, razorpay_order_id, razorpay_payment_id)
SELECT 
    gen_random_uuid(),
    f.id,
    l.id,
    'POL-DEMO-001',
    5500.00,
    275000.00,
    'Wheat',
    CURRENT_DATE - INTERVAL '30 days',
    CURRENT_DATE + INTERVAL '150 days',
    'ACTIVE',
    'order_demo001',
    'pay_demo001'
FROM farmers f
JOIN lands l ON l.farmer_id = f.id AND l.khasra_number = 'RN-101/1'
WHERE f.phone = '8440071773'
ON CONFLICT (policy_number) DO NOTHING;

INSERT INTO insurance_policies (id, farmer_id, land_id, policy_number, premium_amount, coverage_amount, crop_type, start_date, end_date, status, razorpay_order_id, razorpay_payment_id)
SELECT 
    gen_random_uuid(),
    f.id,
    l.id,
    'POL-DEMO-002',
    10500.00,
    420000.00,
    'Rice',
    CURRENT_DATE - INTERVAL '20 days',
    CURRENT_DATE + INTERVAL '160 days',
    'ACTIVE',
    'order_demo002',
    'pay_demo002'
FROM farmers f
JOIN lands l ON l.farmer_id = f.id AND l.khasra_number = 'RN-102/1'
WHERE f.phone = '8440071773'
ON CONFLICT (policy_number) DO NOTHING;

INSERT INTO insurance_policies (id, farmer_id, land_id, policy_number, premium_amount, coverage_amount, crop_type, start_date, end_date, status, razorpay_order_id, razorpay_payment_id)
SELECT 
    gen_random_uuid(),
    f.id,
    l.id,
    'POL-DEMO-003',
    13750.00,
    550000.00,
    'Soybean',
    CURRENT_DATE - INTERVAL '45 days',
    CURRENT_DATE + INTERVAL '135 days',
    'ACTIVE',
    'order_demo003',
    'pay_demo003'
FROM farmers f
JOIN lands l ON l.farmer_id = f.id AND l.khasra_number = 'DEMO-001'
WHERE f.phone = '8440071773'
ON CONFLICT (policy_number) DO NOTHING;

-- Add sensor readings for demo
INSERT INTO sensor_readings (sensor_id, soil_moisture, humidity, temperature, rainfall, recorded_at)
SELECT s.id, 45.5, 72.3, 28.5, 12.0, NOW() - INTERVAL '1 hour'
FROM sensors s WHERE s.unique_code = 'SENS-001'
ON CONFLICT DO NOTHING;

INSERT INTO sensor_readings (sensor_id, soil_moisture, humidity, temperature, rainfall, recorded_at)
SELECT s.id, 38.2, 68.7, 30.1, 8.5, NOW() - INTERVAL '1 hour'
FROM sensors s WHERE s.unique_code = 'SENS-002'
ON CONFLICT DO NOTHING;

INSERT INTO sensor_readings (sensor_id, soil_moisture, humidity, temperature, rainfall, recorded_at)
SELECT s.id, 52.8, 75.4, 26.8, 15.2, NOW() - INTERVAL '1 hour'
FROM sensors s WHERE s.unique_code = 'SENS-003'
ON CONFLICT DO NOTHING;

-- Add recent readings for live sensor data display
INSERT INTO sensor_readings (sensor_id, soil_moisture, humidity, temperature, rainfall, recorded_at)
SELECT s.id, 46.2, 71.8, 29.0, 11.5, NOW()
FROM sensors s WHERE s.unique_code = 'SENS-001';

INSERT INTO sensor_readings (sensor_id, soil_moisture, humidity, temperature, rainfall, recorded_at)
SELECT s.id, 39.5, 69.2, 29.8, 9.0, NOW()
FROM sensors s WHERE s.unique_code = 'SENS-002';

INSERT INTO sensor_readings (sensor_id, soil_moisture, humidity, temperature, rainfall, recorded_at)
SELECT s.id, 53.1, 74.9, 27.2, 14.8, NOW()
FROM sensors s WHERE s.unique_code = 'SENS-003';

SELECT 'DEMO DATA: 3 Active Insurance Policies Created!' as info;
SELECT 'You can now file claims on these policies!' as info;
