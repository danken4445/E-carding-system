-- TakoPOS Database Migration
-- Migration: Add Multi-Tenancy Support
-- Description: Adds shops table and shop_id to all tables for multi-tenant data isolation

-- ============================================================================
-- CREATE SHOPS TABLE
-- ============================================================================

CREATE TABLE shops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    settings JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_shops_owner ON shops(owner_id);
CREATE INDEX idx_shops_slug ON shops(slug);

-- ============================================================================
-- ADD SHOP_ID TO EXISTING TABLES
-- ============================================================================

-- Catalog tables
ALTER TABLE categories ADD COLUMN shop_id UUID REFERENCES shops(id) ON DELETE CASCADE;
ALTER TABLE products ADD COLUMN shop_id UUID REFERENCES shops(id) ON DELETE CASCADE;
ALTER TABLE modifier_groups ADD COLUMN shop_id UUID REFERENCES shops(id) ON DELETE CASCADE;

-- Transaction tables
ALTER TABLE transactions ADD COLUMN shop_id UUID REFERENCES shops(id) ON DELETE CASCADE;
ALTER TABLE shifts ADD COLUMN shop_id UUID REFERENCES shops(id) ON DELETE CASCADE;

-- Users table - link to both shop and auth.users
ALTER TABLE users ADD COLUMN shop_id UUID REFERENCES shops(id) ON DELETE CASCADE;
ALTER TABLE users ADD COLUMN email VARCHAR(255);
ALTER TABLE users ADD COLUMN auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Create indexes for shop_id foreign keys
CREATE INDEX idx_categories_shop ON categories(shop_id);
CREATE INDEX idx_products_shop ON products(shop_id);
CREATE INDEX idx_modifier_groups_shop ON modifier_groups(shop_id);
CREATE INDEX idx_transactions_shop ON transactions(shop_id);
CREATE INDEX idx_shifts_shop ON shifts(shop_id);
CREATE INDEX idx_users_shop ON users(shop_id);
CREATE INDEX idx_users_auth_user ON users(auth_user_id);

-- ============================================================================
-- UPDATE USER ROLES
-- ============================================================================

-- Drop old role constraint
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;

-- Update existing user roles to match new constraint
UPDATE users SET role = 'owner' WHERE role = 'admin';
UPDATE users SET role = 'staff' WHERE role = 'cashier';
UPDATE users SET role = 'staff' WHERE role = 'employee';
UPDATE users SET role = 'manager' WHERE role = 'supervisor';

-- Add new role constraint with updated roles
ALTER TABLE users ADD CONSTRAINT users_role_check
    CHECK (role IN ('staff', 'manager', 'owner'));

-- ============================================================================
-- HELPER FUNCTIONS FOR RLS
-- ============================================================================

-- Function to get current user's shop_id
CREATE OR REPLACE FUNCTION public.get_user_shop_id()
RETURNS UUID AS $$
    SELECT shop_id FROM public.users WHERE auth_user_id = auth.uid() LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Function to get current user's role
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS VARCHAR AS $$
    SELECT role FROM public.users WHERE auth_user_id = auth.uid() LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ============================================================================
-- UPDATE RLS POLICIES - DROP OLD POLICIES
-- ============================================================================

-- Categories
DROP POLICY IF EXISTS "Allow read access for authenticated users" ON categories;
DROP POLICY IF EXISTS "Service role full access" ON categories;

-- Products
DROP POLICY IF EXISTS "Allow read access for authenticated users" ON products;
DROP POLICY IF EXISTS "Service role full access" ON products;

-- Variants
DROP POLICY IF EXISTS "Allow read access for authenticated users" ON variants;
DROP POLICY IF EXISTS "Service role full access" ON variants;

-- Modifier Groups
DROP POLICY IF EXISTS "Allow read access for authenticated users" ON modifier_groups;
DROP POLICY IF EXISTS "Service role full access" ON modifier_groups;

-- Modifiers
DROP POLICY IF EXISTS "Allow read access for authenticated users" ON modifiers;
DROP POLICY IF EXISTS "Service role full access" ON modifiers;

-- Product Modifier Groups
DROP POLICY IF EXISTS "Allow read access for authenticated users" ON product_modifier_groups;
DROP POLICY IF EXISTS "Service role full access" ON product_modifier_groups;

-- Users
DROP POLICY IF EXISTS "Service role full access" ON users;

-- Shifts
DROP POLICY IF EXISTS "Service role full access" ON shifts;

-- Transactions
DROP POLICY IF EXISTS "Service role full access" ON transactions;

-- Transaction Lines
DROP POLICY IF EXISTS "Service role full access" ON transaction_lines;

-- Payments
DROP POLICY IF EXISTS "Service role full access" ON payments;

-- ============================================================================
-- CREATE SHOP-AWARE RLS POLICIES
-- ============================================================================

-- ==========================
-- SHOPS TABLE POLICIES
-- ==========================

CREATE POLICY "Users can read own shop" ON shops
    FOR SELECT TO authenticated
    USING (id = (SELECT public.get_user_shop_id()));

CREATE POLICY "Owners can update own shop" ON shops
    FOR UPDATE TO authenticated
    USING (
        id = (SELECT public.get_user_shop_id())
        AND (SELECT public.get_user_role()) = 'owner'
    )
    WITH CHECK (
        id = (SELECT public.get_user_shop_id())
        AND (SELECT public.get_user_role()) = 'owner'
    );

-- Service role has full access for migrations
CREATE POLICY "Service role full access on shops" ON shops
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ==========================
-- CATEGORIES POLICIES
-- ==========================

-- All authenticated users can read categories from their shop
CREATE POLICY "Users can read own shop categories" ON categories
    FOR SELECT TO authenticated
    USING (shop_id = (SELECT public.get_user_shop_id()));

-- Managers and Owners can insert categories
CREATE POLICY "Managers can insert categories" ON categories
    FOR INSERT TO authenticated
    WITH CHECK (
        shop_id = (SELECT public.get_user_shop_id())
        AND (SELECT public.get_user_role()) IN ('manager', 'owner')
    );

-- Managers and Owners can update categories
CREATE POLICY "Managers can update categories" ON categories
    FOR UPDATE TO authenticated
    USING (
        shop_id = (SELECT public.get_user_shop_id())
        AND (SELECT public.get_user_role()) IN ('manager', 'owner')
    )
    WITH CHECK (
        shop_id = (SELECT public.get_user_shop_id())
        AND (SELECT public.get_user_role()) IN ('manager', 'owner')
    );

-- Managers and Owners can delete categories
CREATE POLICY "Managers can delete categories" ON categories
    FOR DELETE TO authenticated
    USING (
        shop_id = (SELECT public.get_user_shop_id())
        AND (SELECT public.get_user_role()) IN ('manager', 'owner')
    );

-- Service role full access
CREATE POLICY "Service role full access on categories" ON categories
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ==========================
-- PRODUCTS POLICIES
-- ==========================

CREATE POLICY "Users can read own shop products" ON products
    FOR SELECT TO authenticated
    USING (shop_id = (SELECT public.get_user_shop_id()));

CREATE POLICY "Managers can manage products" ON products
    FOR ALL TO authenticated
    USING (
        shop_id = (SELECT public.get_user_shop_id())
        AND (SELECT public.get_user_role()) IN ('manager', 'owner')
    )
    WITH CHECK (
        shop_id = (SELECT public.get_user_shop_id())
        AND (SELECT public.get_user_role()) IN ('manager', 'owner')
    );

CREATE POLICY "Service role full access on products" ON products
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ==========================
-- VARIANTS POLICIES
-- ==========================

-- Variants inherit product's shop_id through product_id FK
CREATE POLICY "Users can read variants of own shop products" ON variants
    FOR SELECT TO authenticated
    USING (product_id IN (
        SELECT id FROM products WHERE shop_id = (SELECT public.get_user_shop_id())
    ));

CREATE POLICY "Managers can manage variants" ON variants
    FOR ALL TO authenticated
    USING (product_id IN (
        SELECT id FROM products
        WHERE shop_id = (SELECT public.get_user_shop_id())
        AND (SELECT public.get_user_role()) IN ('manager', 'owner')
    ))
    WITH CHECK (product_id IN (
        SELECT id FROM products
        WHERE shop_id = (SELECT public.get_user_shop_id())
        AND (SELECT public.get_user_role()) IN ('manager', 'owner')
    ));

CREATE POLICY "Service role full access on variants" ON variants
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ==========================
-- MODIFIER GROUPS POLICIES
-- ==========================

CREATE POLICY "Users can read own shop modifier groups" ON modifier_groups
    FOR SELECT TO authenticated
    USING (shop_id = (SELECT public.get_user_shop_id()));

CREATE POLICY "Managers can manage modifier groups" ON modifier_groups
    FOR ALL TO authenticated
    USING (
        shop_id = (SELECT public.get_user_shop_id())
        AND (SELECT public.get_user_role()) IN ('manager', 'owner')
    )
    WITH CHECK (
        shop_id = (SELECT public.get_user_shop_id())
        AND (SELECT public.get_user_role()) IN ('manager', 'owner')
    );

CREATE POLICY "Service role full access on modifier_groups" ON modifier_groups
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ==========================
-- MODIFIERS POLICIES
-- ==========================

CREATE POLICY "Users can read modifiers of own shop groups" ON modifiers
    FOR SELECT TO authenticated
    USING (group_id IN (
        SELECT id FROM modifier_groups WHERE shop_id = (SELECT public.get_user_shop_id())
    ));

CREATE POLICY "Managers can manage modifiers" ON modifiers
    FOR ALL TO authenticated
    USING (group_id IN (
        SELECT id FROM modifier_groups
        WHERE shop_id = (SELECT public.get_user_shop_id())
        AND (SELECT public.get_user_role()) IN ('manager', 'owner')
    ))
    WITH CHECK (group_id IN (
        SELECT id FROM modifier_groups
        WHERE shop_id = (SELECT public.get_user_shop_id())
        AND (SELECT public.get_user_role()) IN ('manager', 'owner')
    ));

CREATE POLICY "Service role full access on modifiers" ON modifiers
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ==========================
-- PRODUCT MODIFIER GROUPS POLICIES
-- ==========================

CREATE POLICY "Users can read product modifier groups" ON product_modifier_groups
    FOR SELECT TO authenticated
    USING (product_id IN (
        SELECT id FROM products WHERE shop_id = (SELECT public.get_user_shop_id())
    ));

CREATE POLICY "Managers can manage product modifier groups" ON product_modifier_groups
    FOR ALL TO authenticated
    USING (product_id IN (
        SELECT id FROM products
        WHERE shop_id = (SELECT public.get_user_shop_id())
        AND (SELECT public.get_user_role()) IN ('manager', 'owner')
    ))
    WITH CHECK (product_id IN (
        SELECT id FROM products
        WHERE shop_id = (SELECT public.get_user_shop_id())
        AND (SELECT public.get_user_role()) IN ('manager', 'owner')
    ));

CREATE POLICY "Service role full access on product_modifier_groups" ON product_modifier_groups
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ==========================
-- USERS TABLE POLICIES
-- ==========================

-- Users can read other users in their shop
CREATE POLICY "Users can read own shop users" ON users
    FOR SELECT TO authenticated
    USING (shop_id = (SELECT public.get_user_shop_id()));

-- Owners can manage users in their shop
CREATE POLICY "Owners can manage users" ON users
    FOR ALL TO authenticated
    USING (
        shop_id = (SELECT public.get_user_shop_id())
        AND (SELECT public.get_user_role()) = 'owner'
    )
    WITH CHECK (
        shop_id = (SELECT public.get_user_shop_id())
        AND (SELECT public.get_user_role()) = 'owner'
    );

CREATE POLICY "Service role full access on users" ON users
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ==========================
-- SHIFTS POLICIES
-- ==========================

CREATE POLICY "Users can read own shop shifts" ON shifts
    FOR SELECT TO authenticated
    USING (shop_id = (SELECT public.get_user_shop_id()));

CREATE POLICY "Users can manage own shop shifts" ON shifts
    FOR ALL TO authenticated
    USING (shop_id = (SELECT public.get_user_shop_id()))
    WITH CHECK (shop_id = (SELECT public.get_user_shop_id()));

CREATE POLICY "Service role full access on shifts" ON shifts
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ==========================
-- TRANSACTIONS POLICIES
-- ==========================

CREATE POLICY "Users can read own shop transactions" ON transactions
    FOR SELECT TO authenticated
    USING (shop_id = (SELECT public.get_user_shop_id()));

CREATE POLICY "Users can manage own shop transactions" ON transactions
    FOR ALL TO authenticated
    USING (shop_id = (SELECT public.get_user_shop_id()))
    WITH CHECK (shop_id = (SELECT public.get_user_shop_id()));

CREATE POLICY "Service role full access on transactions" ON transactions
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ==========================
-- TRANSACTION LINES POLICIES
-- ==========================

CREATE POLICY "Users can read transaction lines" ON transaction_lines
    FOR SELECT TO authenticated
    USING (transaction_id IN (
        SELECT id FROM transactions WHERE shop_id = (SELECT public.get_user_shop_id())
    ));

CREATE POLICY "Users can manage transaction lines" ON transaction_lines
    FOR ALL TO authenticated
    USING (transaction_id IN (
        SELECT id FROM transactions WHERE shop_id = (SELECT public.get_user_shop_id())
    ))
    WITH CHECK (transaction_id IN (
        SELECT id FROM transactions WHERE shop_id = (SELECT public.get_user_shop_id())
    ));

CREATE POLICY "Service role full access on transaction_lines" ON transaction_lines
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ==========================
-- PAYMENTS POLICIES
-- ==========================

CREATE POLICY "Users can read payments" ON payments
    FOR SELECT TO authenticated
    USING (transaction_id IN (
        SELECT id FROM transactions WHERE shop_id = (SELECT public.get_user_shop_id())
    ));

CREATE POLICY "Users can manage payments" ON payments
    FOR ALL TO authenticated
    USING (transaction_id IN (
        SELECT id FROM transactions WHERE shop_id = (SELECT public.get_user_shop_id())
    ))
    WITH CHECK (transaction_id IN (
        SELECT id FROM transactions WHERE shop_id = (SELECT public.get_user_shop_id())
    ));

CREATE POLICY "Service role full access on payments" ON payments
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================================

CREATE TRIGGER update_shops_updated_at
    BEFORE UPDATE ON shops
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- NOTES
-- ============================================================================

-- After running this migration:
-- 1. Existing data will have NULL shop_id values
-- 2. You need to manually create shop(s) and assign shop_id to existing data
-- 3. Create auth.users accounts via Supabase Auth UI
-- 4. Link users table records to auth.users by setting auth_user_id
-- 5. Set shop_id on all existing categories, products, modifier_groups
-- 6. See test_shop.sql for sample data migration script
