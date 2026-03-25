-- Test Shop & Users Setup Script
-- Run this after creating auth.users accounts via Supabase Auth Dashboard

-- ============================================================================
-- STEP 1: Create Auth Users via Supabase Dashboard
-- ============================================================================
-- Before running this script, create these users via Supabase Auth UI:
--
-- 1. Owner:   owner@test.com    / password: Test123!
-- 2. Manager: manager@test.com  / password: Test123!
-- 3. Staff:   staff@test.com    / password: Test123!
--
-- Note their auth.users.id values - you'll need them below.
-- ============================================================================

-- ============================================================================
-- STEP 2: Create Test Shop
-- ============================================================================

-- Insert test shop (replace <owner-auth-user-id> with actual ID from auth.users)
INSERT INTO shops (id, name, slug, owner_id, settings)
VALUES (
    '10000000-0000-0000-0000-000000000001',
    'Test Coffee Shop',
    'test-coffee-shop',
    '489bdaa0-4b96-438e-b096-6bcdb4aec656', -- Owner auth user ID
    '{"currency": "USD", "timezone": "America/New_York", "tax_rate": 0.08}'::jsonb
);

-- ============================================================================
-- STEP 3: Link Existing Users to Test Shop & Auth
-- ============================================================================

-- Update existing admin user to be owner (if from seed data)
UPDATE users
SET
    shop_id = '10000000-0000-0000-0000-000000000001',
    auth_user_id = '489bdaa0-4b96-438e-b096-6bcdb4aec656', -- Owner auth user ID
    email = 'owner@test.com',
    role = 'owner',
    display_name = 'Shop Owner'
WHERE username = 'admin' OR id = '00000000-0000-0000-0000-000000000001';

-- Update existing cashier to be staff
UPDATE users
SET
    shop_id = '10000000-0000-0000-0000-000000000001',
    auth_user_id = '2b3f7fce-91df-4624-a957-1d459e2ef624', -- Replace with actual ID
    email = 'staff@test.com',
    role = 'staff',
    display_name = 'Staff Member'
WHERE username = 'cashier1' OR id = '00000000-0000-0000-0000-000000000002';

-- Create manager user
INSERT INTO users (id, shop_id, auth_user_id, username, display_name, email, role, is_active, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000001',
    '190321b4-95c7-49ab-bf32-b30a46c90b77', -- Replace with actual ID
    'manager1',
    'Shop Manager',
    'manager@test.com',
    'manager',
    TRUE,
    NOW(),
    NOW()
);

-- ============================================================================
-- STEP 4: Update Existing Catalog Data to Belong to Test Shop
-- ============================================================================

-- Update all categories
UPDATE categories
SET shop_id = '10000000-0000-0000-0000-000000000001'
WHERE shop_id IS NULL;

-- Update all products
UPDATE products
SET shop_id = '10000000-0000-0000-0000-000000000001'
WHERE shop_id IS NULL;

-- Update all modifier groups
UPDATE modifier_groups
SET shop_id = '10000000-0000-0000-0000-000000000001'
WHERE shop_id IS NULL;

-- Update all transactions (if any)
UPDATE transactions
SET shop_id = '10000000-0000-0000-0000-000000000001'
WHERE shop_id IS NULL;

-- Update all shifts (if any)
UPDATE shifts
SET shop_id = '10000000-0000-0000-0000-000000000001'
WHERE shop_id IS NULL;

-- ============================================================================
-- STEP 5: Create Second Test Shop (Optional - for multi-tenancy testing)
-- ============================================================================

/*
-- Uncomment this section if you want a second shop for testing data isolation

-- Create auth user for second shop owner first via Supabase Auth UI
-- Email: owner2@testshop2.com / Password: TestShop123!

INSERT INTO shops (id, name, slug, owner_id, settings)
VALUES (
    '20000000-0000-0000-0000-000000000002',
    'Second Test Shop',
    'second-test-shop',
    '<second-owner-auth-user-id>', -- Replace with actual ID
    '{"currency": "USD", "timezone": "America/Chicago"}'::jsonb
);

-- Create owner user for second shop
INSERT INTO users (id, shop_id, auth_user_id, username, display_name, email, role, is_active, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000004',
    '20000000-0000-0000-0000-000000000002',
    '<second-owner-auth-user-id>',
    'owner2',
    'Second Shop Owner',
    'owner2@testshop2.com',
    'owner',
    TRUE,
    NOW(),
    NOW()
);

-- Create some products for second shop
INSERT INTO categories (id, shop_id, name, description, sort_order, color_hex)
VALUES (
    '22222222-2222-2222-2222-222222222222',
    '20000000-0000-0000-0000-000000000002',
    'Bakery',
    'Fresh baked goods',
    0,
    '#FFF3E0'
);

INSERT INTO products (id, shop_id, name, category_id, base_price_cents, barcode)
VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-bbbbbbbbbbbb', '20000000-0000-0000-0000-000000000002', 'Croissant', '22222222-2222-2222-2222-222222222222', 350, '5001'),
    ('bbbbbbbb-bbbb-bbbb-bbbb-cccccccccccc', '20000000-0000-0000-0000-000000000002', 'Bagel', '22222222-2222-2222-2222-222222222222', 250, '5002');
*/

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Verify shops
SELECT id, name, slug, owner_id FROM shops;

-- Verify users with shop assignments
SELECT id, shop_id, username, display_name, email, role FROM users;

-- Verify categories have shop_id
SELECT id, shop_id, name FROM categories LIMIT 5;

-- Verify products have shop_id
SELECT id, shop_id, name FROM products LIMIT 5;

-- ============================================================================
-- NOTES
-- ============================================================================
--
-- After running this script:
-- 1. You can log in to the Flutter app with:
--    - owner@test.com / Test123! (full access)
--    - manager@test.com / Test123! (POS + products)
--    - staff@test.com / Test123! (POS only)
--
-- 2. Test multi-tenancy by creating a second shop and logging in
--    Users should only see data from their assigned shop
--
-- 3. Test RLS policies - users cannot access data from other shops
--
-- ============================================================================
