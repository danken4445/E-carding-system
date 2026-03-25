-- TakoPOS Database Schema
-- Migration: Initial Setup

-- ============================================================================
-- CATALOG TABLES
-- ============================================================================

-- Product Categories (e.g., Beverages, Food, Merchandise)
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    color_hex VARCHAR(7),
    icon_name VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Products available for sale
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    barcode VARCHAR(50),
    sku VARCHAR(50),
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    base_price_cents INTEGER NOT NULL,
    cost_price_cents INTEGER,
    image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    track_inventory BOOLEAN DEFAULT FALSE,
    stock_quantity INTEGER,
    low_stock_threshold INTEGER DEFAULT 5,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    sync_version INTEGER DEFAULT 0
);

-- Product variants (e.g., Small/Medium/Large, Red/Blue)
CREATE TABLE variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    sku VARCHAR(50),
    barcode VARCHAR(50),
    price_adjustment_cents INTEGER DEFAULT 0,
    stock_quantity INTEGER,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE
);

-- Groups of modifiers (e.g., "Extras", "Sweetness Level")
CREATE TABLE modifier_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    min_selections INTEGER DEFAULT 0,
    max_selections INTEGER DEFAULT 1,
    sort_order INTEGER DEFAULT 0
);

-- Individual modifiers (e.g., "Extra Shot", "No Sugar")
CREATE TABLE modifiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES modifier_groups(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    price_adjustment_cents INTEGER DEFAULT 0,
    is_default BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0
);

-- Junction table: which modifier groups apply to which products
CREATE TABLE product_modifier_groups (
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    modifier_group_id UUID NOT NULL REFERENCES modifier_groups(id) ON DELETE CASCADE,
    sort_order INTEGER DEFAULT 0,
    PRIMARY KEY (product_id, modifier_group_id)
);

-- ============================================================================
-- USER & AUTH TABLES
-- ============================================================================

-- Staff members who can use the POS
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    pin_hash TEXT,
    role VARCHAR(20) NOT NULL CHECK (role IN ('cashier', 'supervisor', 'manager', 'admin')),
    permissions JSONB DEFAULT '[]',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- SHIFT MANAGEMENT TABLES
-- ============================================================================

-- Cash register shifts
CREATE TABLE shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    register_id VARCHAR(50),
    opening_cash_cents INTEGER NOT NULL,
    closing_cash_cents INTEGER,
    expected_cash_cents INTEGER,
    variance_cents INTEGER,
    opened_at TIMESTAMPTZ DEFAULT NOW(),
    closed_at TIMESTAMPTZ,
    is_blind_close BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) NOT NULL CHECK (status IN ('open', 'closing', 'closed')),
    notes TEXT
);

-- ============================================================================
-- TRANSACTION TABLES
-- ============================================================================

-- Completed or in-progress transactions/orders
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_id UUID REFERENCES shifts(id) ON DELETE SET NULL,
    subtotal_cents INTEGER NOT NULL,
    discount_cents INTEGER DEFAULT 0,
    tax_cents INTEGER DEFAULT 0,
    total_cents INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('draft', 'completed', 'voided', 'refunded')),
    customer_id UUID,
    customer_name VARCHAR(100),
    customer_email VARCHAR(255),
    customer_phone VARCHAR(20),
    cashier_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    cashier_name VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    sync_version INTEGER DEFAULT 0
);

-- Individual line items within a transaction
CREATE TABLE transaction_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    product_id UUID NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    variant_id UUID,
    variant_name VARCHAR(100),
    quantity INTEGER NOT NULL,
    unit_price_cents INTEGER NOT NULL,
    line_total_cents INTEGER NOT NULL,
    discount_cents INTEGER DEFAULT 0,
    discount_reason TEXT,
    notes TEXT,
    modifiers_json JSONB
);

-- Payments applied to transactions
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    method VARCHAR(20) NOT NULL CHECK (method IN ('cash', 'card', 'gift_card', 'store_credit')),
    amount_cents INTEGER NOT NULL,
    tendered_cents INTEGER,
    change_cents INTEGER,
    card_last4 VARCHAR(4),
    card_brand VARCHAR(20),
    authorization_code VARCHAR(50),
    external_payment_id VARCHAR(100),
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'approved', 'declined', 'voided')),
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Product search optimization
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_barcode ON products(barcode);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_name ON products USING gin(to_tsvector('english', name));

-- Variant lookups
CREATE INDEX idx_variants_product ON variants(product_id);
CREATE INDEX idx_variants_barcode ON variants(barcode);

-- Modifier lookups
CREATE INDEX idx_modifiers_group ON modifiers(group_id);

-- Transaction queries
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_created ON transactions(created_at DESC);
CREATE INDEX idx_transactions_shift ON transactions(shift_id);
CREATE INDEX idx_transactions_cashier ON transactions(cashier_id);

-- Transaction lines
CREATE INDEX idx_transaction_lines_transaction ON transaction_lines(transaction_id);

-- Payments
CREATE INDEX idx_payments_transaction ON payments(transaction_id);

-- Shifts
CREATE INDEX idx_shifts_user ON shifts(user_id);
CREATE INDEX idx_shifts_status ON shifts(status);

-- ============================================================================
-- TRIGGERS FOR updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_categories_updated_at
    BEFORE UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE modifier_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE modifiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_modifier_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Create policies (allowing authenticated access for now - customize based on your needs)
-- Read access for authenticated users
CREATE POLICY "Allow read access for authenticated users" ON categories
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow read access for authenticated users" ON products
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow read access for authenticated users" ON variants
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow read access for authenticated users" ON modifier_groups
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow read access for authenticated users" ON modifiers
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow read access for authenticated users" ON product_modifier_groups
    FOR SELECT TO authenticated USING (true);

-- Full access for service role (used by the app)
CREATE POLICY "Service role full access" ON categories
    FOR ALL TO service_role USING (true);

CREATE POLICY "Service role full access" ON products
    FOR ALL TO service_role USING (true);

CREATE POLICY "Service role full access" ON variants
    FOR ALL TO service_role USING (true);

CREATE POLICY "Service role full access" ON modifier_groups
    FOR ALL TO service_role USING (true);

CREATE POLICY "Service role full access" ON modifiers
    FOR ALL TO service_role USING (true);

CREATE POLICY "Service role full access" ON product_modifier_groups
    FOR ALL TO service_role USING (true);

CREATE POLICY "Service role full access" ON users
    FOR ALL TO service_role USING (true);

CREATE POLICY "Service role full access" ON shifts
    FOR ALL TO service_role USING (true);

CREATE POLICY "Service role full access" ON transactions
    FOR ALL TO service_role USING (true);

CREATE POLICY "Service role full access" ON transaction_lines
    FOR ALL TO service_role USING (true);

CREATE POLICY "Service role full access" ON payments
    FOR ALL TO service_role USING (true);

-- ============================================================================
-- SEED DATA (Sample Categories and Products)
-- ============================================================================

-- Insert sample categories
INSERT INTO categories (id, name, description, sort_order, color_hex) VALUES
    ('11111111-1111-1111-1111-111111111111', 'Beverages', 'Hot and cold drinks', 0, '#E3F2FD'),
    ('22222222-2222-2222-2222-222222222222', 'Food', 'Sandwiches, salads, and meals', 1, '#FFF8E1'),
    ('33333333-3333-3333-3333-333333333333', 'Snacks', 'Pastries, cookies, and light bites', 2, '#FCE4EC'),
    ('44444444-4444-4444-4444-444444444444', 'Merchandise', 'Mugs, shirts, and other items', 3, '#E8F5E9');

-- Insert sample modifier groups
INSERT INTO modifier_groups (id, name, min_selections, max_selections, sort_order) VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Extras', 0, 3, 0),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Sweetness', 1, 1, 1);

-- Insert sample modifiers
INSERT INTO modifiers (id, group_id, name, price_adjustment_cents, is_default, sort_order) VALUES
    ('aaaaaaaa-0001-0001-0001-aaaaaaaaaaaa', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Extra Shot', 50, FALSE, 0),
    ('aaaaaaaa-0002-0002-0002-aaaaaaaaaaaa', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Whipped Cream', 30, FALSE, 1),
    ('bbbbbbbb-0001-0001-0001-bbbbbbbbbbbb', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'No Sugar', 0, FALSE, 0),
    ('bbbbbbbb-0002-0002-0002-bbbbbbbbbbbb', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Half Sugar', 0, TRUE, 1),
    ('bbbbbbbb-0003-0003-0003-bbbbbbbbbbbb', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Full Sugar', 0, FALSE, 2);

-- Insert sample products
INSERT INTO products (id, name, category_id, base_price_cents, barcode) VALUES
    ('aaaaaaaa-1111-1111-1111-111111111111', 'Espresso', '11111111-1111-1111-1111-111111111111', 250, '1001'),
    ('aaaaaaaa-2222-2222-2222-222222222222', 'Cappuccino', '11111111-1111-1111-1111-111111111111', 350, '1002'),
    ('aaaaaaaa-3333-3333-3333-333333333333', 'Latte', '11111111-1111-1111-1111-111111111111', 400, '1003'),
    ('aaaaaaaa-4444-4444-4444-444444444444', 'Iced Tea', '11111111-1111-1111-1111-111111111111', 200, '1004'),
    ('bbbbbbbb-1111-1111-1111-111111111111', 'Chicken Sandwich', '22222222-2222-2222-2222-222222222222', 850, '2001'),
    ('bbbbbbbb-2222-2222-2222-222222222222', 'Veggie Wrap', '22222222-2222-2222-2222-222222222222', 700, '2002'),
    ('bbbbbbbb-3333-3333-3333-333333333333', 'Caesar Salad', '22222222-2222-2222-2222-222222222222', 900, '2003'),
    ('cccccccc-1111-1111-1111-111111111111', 'Chocolate Croissant', '33333333-3333-3333-3333-333333333333', 350, '3001'),
    ('cccccccc-2222-2222-2222-222222222222', 'Blueberry Muffin', '33333333-3333-3333-3333-333333333333', 275, '3002'),
    ('dddddddd-1111-1111-1111-111111111111', 'Coffee Mug', '44444444-4444-4444-4444-444444444444', 1200, '4001'),
    ('dddddddd-2222-2222-2222-222222222222', 'T-Shirt', '44444444-4444-4444-4444-444444444444', 2500, '4002');

-- Insert sample variants for beverages (sizes)
INSERT INTO variants (product_id, name, price_adjustment_cents, sort_order) VALUES
    ('aaaaaaaa-1111-1111-1111-111111111111', 'Small', 0, 0),
    ('aaaaaaaa-1111-1111-1111-111111111111', 'Medium', 50, 1),
    ('aaaaaaaa-1111-1111-1111-111111111111', 'Large', 100, 2),
    ('aaaaaaaa-2222-2222-2222-222222222222', 'Small', 0, 0),
    ('aaaaaaaa-2222-2222-2222-222222222222', 'Medium', 50, 1),
    ('aaaaaaaa-2222-2222-2222-222222222222', 'Large', 100, 2),
    ('aaaaaaaa-3333-3333-3333-333333333333', 'Small', 0, 0),
    ('aaaaaaaa-3333-3333-3333-333333333333', 'Medium', 50, 1),
    ('aaaaaaaa-3333-3333-3333-333333333333', 'Large', 100, 2);

-- Insert sample variants for T-Shirt (sizes)
INSERT INTO variants (product_id, name, price_adjustment_cents, sort_order) VALUES
    ('dddddddd-2222-2222-2222-222222222222', 'S', 0, 0),
    ('dddddddd-2222-2222-2222-222222222222', 'M', 0, 1),
    ('dddddddd-2222-2222-2222-222222222222', 'L', 0, 2),
    ('dddddddd-2222-2222-2222-222222222222', 'XL', 200, 3);

-- Link modifier groups to beverage products
INSERT INTO product_modifier_groups (product_id, modifier_group_id, sort_order) VALUES
    ('aaaaaaaa-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 0),
    ('aaaaaaaa-1111-1111-1111-111111111111', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 1),
    ('aaaaaaaa-2222-2222-2222-222222222222', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 0),
    ('aaaaaaaa-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 1),
    ('aaaaaaaa-3333-3333-3333-333333333333', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 0),
    ('aaaaaaaa-3333-3333-3333-333333333333', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 1);

-- Insert a default admin user (PIN: 1234 - in production, use proper hashing)
INSERT INTO users (id, username, display_name, pin_hash, role, is_active) VALUES
    ('00000000-0000-0000-0000-000000000001', 'admin', 'Administrator', '1234', 'admin', TRUE),
    ('00000000-0000-0000-0000-000000000002', 'cashier1', 'John Doe', '0000', 'cashier', TRUE);
