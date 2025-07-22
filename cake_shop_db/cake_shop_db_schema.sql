-- Cake Shop Database Schema for PostgreSQL
-- Covers: Cakes, Users (Auth), Orders, Order History, Delivery Scheduling

-- ========== USERS TABLE ==========
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(128) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(16),
    country VARCHAR(64) DEFAULT 'USA',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ========== CAKE CATALOG ==========
CREATE TABLE cakes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    base_price NUMERIC(10,2) NOT NULL,
    image_url VARCHAR(512),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ========== CAKE SIZES ==========
CREATE TABLE cake_sizes (
    id SERIAL PRIMARY KEY,
    cake_id INTEGER REFERENCES cakes(id) ON DELETE CASCADE,
    size_label VARCHAR(40) NOT NULL,  -- e.g., "6 inch", "Small"
    size_inches NUMERIC(4, 1),
    size_description VARCHAR(100),
    price_adjustment NUMERIC(10,2) NOT NULL DEFAULT 0.00
);

-- ========== CAKE FLAVORS ==========
CREATE TABLE cake_flavors (
    id SERIAL PRIMARY KEY,
    name VARCHAR(40) NOT NULL UNIQUE,
    description VARCHAR(100)
);

-- ========== CAKE TOPPINGS ==========
CREATE TABLE cake_toppings (
    id SERIAL PRIMARY KEY,
    name VARCHAR(40) NOT NULL UNIQUE,
    is_vegan BOOLEAN DEFAULT FALSE
);

-- ========== CAKE BASE - FLAVOR/TOPPING M:N ==========
CREATE TABLE cake_available_flavors (
    cake_id INTEGER REFERENCES cakes(id) ON DELETE CASCADE,
    flavor_id INTEGER REFERENCES cake_flavors(id),
    PRIMARY KEY (cake_id, flavor_id)
);

CREATE TABLE cake_available_toppings (
    cake_id INTEGER REFERENCES cakes(id) ON DELETE CASCADE,
    topping_id INTEGER REFERENCES cake_toppings(id),
    PRIMARY KEY (cake_id, topping_id)
);

-- ========== ORDERS ==========
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    order_status VARCHAR(32) NOT NULL DEFAULT 'pending', -- {pending, paid, confirmed, prepping, completed, cancelled, delivered}
    total_price NUMERIC(10, 2) NOT NULL,
    payment_status VARCHAR(32) NOT NULL DEFAULT 'pending', -- {pending, paid, failed, refunded}
    payment_provider VARCHAR(32), -- e.g., "stripe"
    payment_reference VARCHAR(128), -- e.g., Stripe payment ID
    delivery_address_line1 VARCHAR(255) NOT NULL,
    delivery_address_line2 VARCHAR(255),
    delivery_city VARCHAR(50) NOT NULL,
    delivery_state VARCHAR(50),
    delivery_postal_code VARCHAR(16) NOT NULL,
    delivery_country VARCHAR(64) DEFAULT 'USA',
    delivery_time_slot_id INTEGER,  -- Link to delivery_schedule
    placed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- ========== ORDERED CAKE CUSTOMIZATIONS ==========
CREATE TABLE order_cakes (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    cake_id INTEGER REFERENCES cakes(id),
    size_id INTEGER REFERENCES cake_sizes(id),
    flavor_id INTEGER REFERENCES cake_flavors(id),
    custom_message VARCHAR(200),
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price NUMERIC(10,2) NOT NULL,  -- price after all adjustments
    total_price NUMERIC(10,2) NOT NULL,
    special_instructions TEXT
);

CREATE TABLE order_cake_toppings (
    order_cake_id INTEGER REFERENCES order_cakes(id) ON DELETE CASCADE,
    topping_id INTEGER REFERENCES cake_toppings(id),
    PRIMARY KEY (order_cake_id, topping_id)
);

-- ========== DELIVERY SCHEDULING ==========
CREATE TABLE delivery_schedule (
    id SERIAL PRIMARY KEY,
    scheduled_at TIMESTAMPTZ NOT NULL, -- desired delivery time requested
    status VARCHAR(32) NOT NULL DEFAULT 'scheduled', -- {scheduled, en_route, delivered, delayed, cancelled}
    assigned_to VARCHAR(64), -- delivery person/partner (optional)
    notes VARCHAR(255)
);

-- Link delivery schedule to orders (each order can have one slot; a slot can serve multiple orders if needed)
ALTER TABLE orders
    ADD CONSTRAINT orders_delivery_time_slot_fk
    FOREIGN KEY (delivery_time_slot_id) REFERENCES delivery_schedule(id);

-- ========== ORDER STATUS HISTORY / AUDIT ==========
CREATE TABLE order_status_history (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    status VARCHAR(32) NOT NULL,
    changed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    changed_by INTEGER REFERENCES users(id), -- staff/admin/user who made change
    notes VARCHAR(255)
);

-- ========== ORDER PAYMENT HISTORY ==========
CREATE TABLE order_payment_history (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    payment_status VARCHAR(32) NOT NULL,
    payment_provider VARCHAR(32),
    payment_reference VARCHAR(128),
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    notes VARCHAR(255)
);

-- ========== INDEXES & OPTIMIZATION ==========
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_order_cakes_order_id ON order_cakes(order_id);
CREATE INDEX idx_order_status_history_order_id ON order_status_history(order_id);
CREATE INDEX idx_delivery_schedule_scheduled_at ON delivery_schedule(scheduled_at);

-- ========== SAMPLE ENUMS/DATA (Optional) ==========
-- Insert common flavors/toppings; in real deploy, do this via migration/seed script.

-- ========== END OF SCHEMA ==========
