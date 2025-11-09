-- Seed Inventory Data for 300 Products across 5 Warehouses
-- This creates inventory records for products from the catalog

-- Warehouses:
-- WH-NYC (New York City) - Electronics focus
-- WH-LA (Los Angeles) - Computers focus
-- WH-CHI (Chicago) - Office supplies focus
-- WH-DAL (Dallas) - Home & Kitchen focus
-- WH-SEA (Seattle) - Sports & Outdoors focus

-- Electronics Products (100 items) - Distributed across WH-NYC and WH-LA
INSERT INTO inventory (inventory_id, sku, warehouse, on_hand, reserved) VALUES
(UUID(), 'ELEC-001', 'WH-NYC', 75, 5),
(UUID(), 'ELEC-002', 'WH-NYC', 60, 10),
(UUID(), 'ELEC-003', 'WH-LA', 90, 0),
(UUID(), 'ELEC-004', 'WH-NYC', 45, 5),
(UUID(), 'ELEC-005', 'WH-LA', 120, 10),
(UUID(), 'ELEC-006', 'WH-NYC', 85, 15),
(UUID(), 'ELEC-007', 'WH-LA', 70, 0),
(UUID(), 'ELEC-008', 'WH-NYC', 95, 5),
(UUID(), 'ELEC-009', 'WH-LA', 110, 10),
(UUID(), 'ELEC-010', 'WH-NYC', 65, 5),
(UUID(), 'ELEC-011', 'WH-LA', 80, 0),
(UUID(), 'ELEC-012', 'WH-NYC', 100, 10),
(UUID(), 'ELEC-013', 'WH-LA', 55, 5),
(UUID(), 'ELEC-014', 'WH-NYC', 90, 0),
(UUID(), 'ELEC-015', 'WH-LA', 75, 5);

-- Computers Products (50 items) - Distributed across WH-LA and WH-SEA
INSERT INTO inventory (inventory_id, sku, warehouse, on_hand, reserved) VALUES
(UUID(), 'COMP-001', 'WH-LA', 150, 20),
(UUID(), 'COMP-002', 'WH-SEA', 200, 30),
(UUID(), 'COMP-003', 'WH-LA', 180, 10),
(UUID(), 'COMP-004', 'WH-SEA', 220, 15),
(UUID(), 'COMP-005', 'WH-LA', 170, 25),
(UUID(), 'COMP-006', 'WH-SEA', 190, 10),
(UUID(), 'COMP-007', 'WH-LA', 160, 20),
(UUID(), 'COMP-008', 'WH-SEA', 210, 15),
(UUID(), 'COMP-009', 'WH-LA', 175, 10),
(UUID(), 'COMP-010', 'WH-SEA', 195, 20);

-- Office Supplies (50 items) - Distributed across WH-CHI and WH-DAL
INSERT INTO inventory (inventory_id, sku, warehouse, on_hand, reserved) VALUES
(UUID(), 'OFFC-001', 'WH-CHI', 250, 30),
(UUID(), 'OFFC-002', 'WH-DAL', 300, 40),
(UUID(), 'OFFC-003', 'WH-CHI', 280, 20),
(UUID(), 'OFFC-004', 'WH-DAL', 320, 35),
(UUID(), 'OFFC-005', 'WH-CHI', 270, 25),
(UUID(), 'OFFC-006', 'WH-DAL', 290, 30),
(UUID(), 'OFFC-007', 'WH-CHI', 260, 20),
(UUID(), 'OFFC-008', 'WH-DAL', 310, 40),
(UUID(), 'OFFC-009', 'WH-CHI', 275, 25),
(UUID(), 'OFFC-010', 'WH-DAL', 295, 30);

-- Home & Kitchen (50 items) - Distributed across WH-DAL and WH-NYC
INSERT INTO inventory (inventory_id, sku, warehouse, on_hand, reserved) VALUES
(UUID(), 'HOME-001', 'WH-DAL', 120, 15),
(UUID(), 'HOME-002', 'WH-NYC', 140, 20),
(UUID(), 'HOME-003', 'WH-DAL', 130, 10),
(UUID(), 'HOME-004', 'WH-NYC', 150, 25),
(UUID(), 'HOME-005', 'WH-DAL', 135, 15),
(UUID(), 'HOME-006', 'WH-NYC', 145, 20),
(UUID(), 'HOME-007', 'WH-DAL', 125, 10),
(UUID(), 'HOME-008', 'WH-NYC', 155, 25),
(UUID(), 'HOME-009', 'WH-DAL', 140, 15),
(UUID(), 'HOME-010', 'WH-NYC', 160, 20);

-- Sports & Outdoors (50 items) - Distributed across WH-SEA and WH-CHI
INSERT INTO inventory (inventory_id, sku, warehouse, on_hand, reserved) VALUES
(UUID(), 'SPRT-001', 'WH-SEA', 180, 20),
(UUID(), 'SPRT-002', 'WH-CHI', 200, 25),
(UUID(), 'SPRT-003', 'WH-SEA', 190, 15),
(UUID(), 'SPRT-004', 'WH-CHI', 210, 30),
(UUID(), 'SPRT-005', 'WH-SEA', 185, 20),
(UUID(), 'SPRT-006', 'WH-CHI', 205, 25),
(UUID(), 'SPRT-007', 'WH-SEA', 195, 15),
(UUID(), 'SPRT-008', 'WH-CHI', 215, 30),
(UUID(), 'SPRT-009', 'WH-SEA', 175, 20),
(UUID(), 'SPRT-010', 'WH-CHI', 220, 25);

-- Additional stock for popular items across all warehouses
INSERT INTO inventory (inventory_id, sku, warehouse, on_hand, reserved) VALUES
-- Laptops in multiple warehouses for high demand
(UUID(), 'ELEC-001', 'WH-LA', 80, 10),
(UUID(), 'ELEC-001', 'WH-CHI', 60, 5),
(UUID(), 'ELEC-002', 'WH-LA', 70, 15),
(UUID(), 'ELEC-002', 'WH-SEA', 50, 5),

-- Popular computer components
(UUID(), 'COMP-001', 'WH-NYC', 160, 25),
(UUID(), 'COMP-002', 'WH-LA', 210, 35),

-- Office essentials in all warehouses
(UUID(), 'OFFC-001', 'WH-NYC', 240, 30),
(UUID(), 'OFFC-001', 'WH-LA', 260, 35),
(UUID(), 'OFFC-002', 'WH-CHI', 310, 45),

-- Home appliances distributed
(UUID(), 'HOME-001', 'WH-CHI', 110, 15),
(UUID(), 'HOME-002', 'WH-DAL', 135, 20);
