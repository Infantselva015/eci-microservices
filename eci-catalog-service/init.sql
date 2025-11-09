-- Create database if not exists
CREATE DATABASE IF NOT EXISTS catalog_db;
USE catalog_db;

-- Drop existing tables
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;

-- Create categories table
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create products table WITH is_active and deleted columns
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    sku VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    category_id INT,
    stock INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    deleted BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
    INDEX idx_sku (sku),
    INDEX idx_category (category_id),
    INDEX idx_active (is_active, deleted)
);

-- Insert sample categories
INSERT INTO categories (name, description) VALUES
('Electronics', 'Electronic devices and accessories'),
('Clothing', 'Apparel and fashion items'),
('Books', 'Books and publications'),
('Home & Garden', 'Home improvement and garden supplies'),
('Sports', 'Sports equipment and accessories');

-- Insert sample products
INSERT INTO products (sku, name, description, price, category_id, stock, is_active, deleted) VALUES
('SKU-12345', 'Wireless Mouse', 'Ergonomic wireless mouse with USB receiver', 29.99, 1, 150, true, false),
('SKU-12346', 'Mechanical Keyboard', 'RGB backlit mechanical gaming keyboard', 89.99, 1, 75, true, false),
('SKU-12347', 'USB-C Hub', '7-in-1 USB-C hub with HDMI and card readers', 49.99, 1, 120, true, false),
('SKU-12348', 'Cotton T-Shirt', 'Premium cotton crew neck t-shirt', 19.99, 2, 200, true, false),
('SKU-12349', 'Denim Jeans', 'Classic fit denim jeans', 59.99, 2, 100, true, false),
('SKU-12350', 'Programming Book', 'Advanced JavaScript programming guide', 44.99, 3, 50, true, false),
('SKU-12351', 'Garden Tools Set', 'Complete 10-piece garden tools set', 79.99, 4, 30, true, false),
('SKU-12352', 'Yoga Mat', 'Non-slip exercise yoga mat', 24.99, 5, 85, true, false),
('SKU-12353', 'Basketball', 'Official size basketball', 34.99, 5, 60, true, false),
('SKU-12354', 'LED Desk Lamp', 'Adjustable LED desk lamp with USB charging', 39.99, 1, 95, true, false);
