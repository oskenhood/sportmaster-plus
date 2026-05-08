-- ═══════════════════════════════════════════════════
-- СХЕМА БД: ИС Продаж Спортивных Товаров
-- ООО «СпортМастер Плюс»
-- Выполнить в Supabase → SQL Editor
-- ═══════════════════════════════════════════════════

-- 1. КАТЕГОРИИ ТОВАРОВ (иерархическая)
CREATE TABLE IF NOT EXISTS categories (
  id          SERIAL PRIMARY KEY,
  name        VARCHAR(150) NOT NULL,
  parent_id   INTEGER REFERENCES categories(id) ON DELETE SET NULL,
  description TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 2. ПОСТАВЩИКИ
CREATE TABLE IF NOT EXISTS suppliers (
  id             SERIAL PRIMARY KEY,
  company_name   VARCHAR(200) NOT NULL,
  inn            VARCHAR(12),
  contact_person VARCHAR(150),
  phone          VARCHAR(20),
  email          VARCHAR(100),
  address        TEXT,
  rating         NUMERIC(2,1) CHECK (rating BETWEEN 1 AND 5),
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- 3. МАГАЗИНЫ
CREATE TABLE IF NOT EXISTS stores (
  id         SERIAL PRIMARY KEY,
  name       VARCHAR(200) NOT NULL,
  city       VARCHAR(100) NOT NULL,
  address    TEXT NOT NULL,
  area       INTEGER,
  phone      VARCHAR(20),
  manager    VARCHAR(150),
  status     VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active','renovation','closed')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. ТОВАРЫ
CREATE TABLE IF NOT EXISTS products (
  id          SERIAL PRIMARY KEY,
  articul     VARCHAR(50) NOT NULL UNIQUE,
  name        VARCHAR(255) NOT NULL,
  brand       VARCHAR(100),
  category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
  supplier_id INTEGER REFERENCES suppliers(id) ON DELETE SET NULL,
  size        VARCHAR(20),
  color       VARCHAR(80),
  price       NUMERIC(10,2) NOT NULL,
  cost_price  NUMERIC(10,2),
  description TEXT,
  status      VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active','inactive','discontinued')),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 5. КЛИЕНТЫ
CREATE TABLE IF NOT EXISTS clients (
  id            SERIAL PRIMARY KEY,
  first_name    VARCHAR(100) NOT NULL,
  last_name     VARCHAR(100) NOT NULL,
  email         VARCHAR(150) UNIQUE NOT NULL,
  phone         VARCHAR(20),
  birthdate     DATE,
  bonus_points  INTEGER DEFAULT 0,
  loyalty_level VARCHAR(20) DEFAULT 'standard'
                CHECK (loyalty_level IN ('standard','silver','gold','platinum')),
  source        VARCHAR(50),
  consent_pd    BOOLEAN DEFAULT FALSE,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 6. ЗАКАЗЫ
CREATE TABLE IF NOT EXISTS orders (
  id             SERIAL PRIMARY KEY,
  client_id      INTEGER REFERENCES clients(id) ON DELETE SET NULL,
  store_id       INTEGER REFERENCES stores(id) ON DELETE SET NULL,
  total_amount   NUMERIC(12,2) NOT NULL,
  discount_amount NUMERIC(12,2) DEFAULT 0,
  channel        VARCHAR(20) DEFAULT 'offline'
                 CHECK (channel IN ('offline','online','mobile','marketplace')),
  payment_method VARCHAR(20) DEFAULT 'cash'
                 CHECK (payment_method IN ('cash','card','online','credit')),
  status         VARCHAR(20) DEFAULT 'new'
                 CHECK (status IN ('new','processing','completed','cancelled','returned')),
  notes          TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);

-- 7. ПОЗИЦИИ ЗАКАЗА
CREATE TABLE IF NOT EXISTS order_items (
  id         SERIAL PRIMARY KEY,
  order_id   INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id INTEGER REFERENCES products(id) ON DELETE SET NULL,
  quantity   INTEGER NOT NULL DEFAULT 1,
  unit_price NUMERIC(10,2) NOT NULL,
  discount   NUMERIC(5,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. СКЛАДСКИЕ ОСТАТКИ
CREATE TABLE IF NOT EXISTS inventory (
  id           SERIAL PRIMARY KEY,
  product_id   INTEGER REFERENCES products(id) ON DELETE CASCADE,
  store_id     INTEGER REFERENCES stores(id) ON DELETE CASCADE,
  quantity     INTEGER NOT NULL DEFAULT 0,
  reserved     INTEGER DEFAULT 0,
  min_quantity INTEGER DEFAULT 3,
  updated_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(product_id, store_id)
);

-- ═══════════════════════════════════════════════════
-- ТЕСТОВЫЕ ДАННЫЕ
-- ═══════════════════════════════════════════════════

-- Категории
INSERT INTO categories (name, description) VALUES
  ('Обувь', 'Спортивная обувь всех видов'),
  ('Одежда', 'Спортивная одежда'),
  ('Инвентарь', 'Спортивный инвентарь и оборудование'),
  ('Аксессуары', 'Аксессуары и дополнения'),
  ('Питание', 'Спортивное питание и добавки')
ON CONFLICT DO NOTHING;

INSERT INTO categories (name, parent_id, description) VALUES
  ('Беговые кроссовки', 1, 'Кроссовки для бега'),
  ('Футбольные бутсы', 1, 'Обувь для футбола'),
  ('Фитнес-одежда', 2, 'Одежда для зала и фитнеса'),
  ('Термобельё', 2, 'Термобельё для зимних видов спорта'),
  ('Мячи', 3, 'Спортивные мячи'),
  ('Велосипеды', 3, 'Велосипеды и аксессуары')
ON CONFLICT DO NOTHING;

-- Поставщики
INSERT INTO suppliers (company_name, inn, contact_person, phone, email, rating) VALUES
  ('ООО НикеРус', '7712345678', 'Петров А.В.', '+7-495-100-10-01', 'supply@nikerus.ru', 4.8),
  ('Адидас Россия', '7798765432', 'Сидорова М.К.', '+7-495-200-20-02', 'b2b@adidas.ru', 4.6),
  ('СпортОпт Москва', '5012345678', 'Иванов Д.Л.', '+7-499-300-30-03', 'opt@sportopt.ru', 4.2),
  ('АсикаДистриб', '7701234567', 'Козлов Р.Н.', '+7-812-400-40-04', 'dist@asics.ru', 4.7)
ON CONFLICT DO NOTHING;

-- Магазины
INSERT INTO stores (name, city, address, area, manager, status) VALUES
  ('СпортМастер Плюс Арбат', 'Москва', 'ул. Арбат, д. 35', 450, 'Громов К.Е.', 'active'),
  ('СпортМастер Плюс Митино', 'Москва', 'ТЦ «Митино», ул. Митинская, 16', 380, 'Власова Н.О.', 'active'),
  ('СпортМастер Плюс Тула', 'Тула', 'ТЦ «Макси», пр. Ленина, 57', 320, 'Орлов В.А.', 'active'),
  ('СпортМастер Плюс Калуга', 'Калуга', 'ТРЦ «Галерея», ул. Кирова, 42', 290, 'Белова Е.С.', 'active'),
  ('СпортМастер Плюс Красногорск', 'Красногорск', 'ТЦ «Июнь», Красногорский б-р, 2', 360, 'Фролов М.Ю.', 'renovation')
ON CONFLICT DO NOTHING;

-- Товары
INSERT INTO products (articul, name, brand, category_id, price, cost_price, size, color, status) VALUES
  ('NK-001-42', 'Кроссовки Air Max 2024', 'Nike', 6, 9990, 5500, '42', 'Чёрный/белый', 'active'),
  ('NK-002-40', 'Кроссовки React Infinity', 'Nike', 6, 12490, 7200, '40', 'Серый', 'active'),
  ('AD-001-43', 'Кроссовки Ultraboost 24', 'Adidas', 6, 14990, 8900, '43', 'Белый', 'active'),
  ('AD-002-S', 'Футболка Adidas Essentials', 'Adidas', 8, 2490, 1200, 'S', 'Синий', 'active'),
  ('NK-003-M', 'Шорты Nike Dri-FIT', 'Nike', 8, 3490, 1800, 'M', 'Чёрный', 'active'),
  ('AS-001-41', 'Кроссовки Gel-Nimbus 26', 'ASICS', 6, 13990, 8100, '41', 'Голубой', 'active'),
  ('SP-001', 'Мяч футбольный Pro 5', 'SportOpt', 10, 1990, 900, '5', 'Белый/Чёрный', 'active'),
  ('NK-004-L', 'Термобельё Nike Pro', 'Nike', 9, 4990, 2700, 'L', 'Чёрный', 'active'),
  ('AD-003-XL', 'Спортивный костюм Adidas Track', 'Adidas', 8, 6990, 4100, 'XL', 'Тёмно-синий', 'active'),
  ('SP-002', 'Коврик для йоги 5мм', 'SportOpt', 4, 1490, 600, NULL, 'Фиолетовый', 'active')
ON CONFLICT DO NOTHING;

-- Клиенты
INSERT INTO clients (first_name, last_name, email, phone, birthdate, bonus_points, loyalty_level, consent_pd) VALUES
  ('Александр', 'Смирнов', 'a.smirnov@mail.ru', '+7-916-111-22-33', '1990-05-15', 1250, 'silver', true),
  ('Мария', 'Козлова', 'm.kozlova@gmail.com', '+7-926-222-33-44', '1985-08-22', 3800, 'gold', true),
  ('Дмитрий', 'Петров', 'd.petrov@yandex.ru', '+7-903-333-44-55', '1993-12-10', 650, 'standard', true),
  ('Елена', 'Новикова', 'e.novikova@inbox.ru', '+7-985-444-55-66', '1988-03-07', 8200, 'platinum', true),
  ('Сергей', 'Волков', 's.volkov@rambler.ru', '+7-977-555-66-77', '1995-11-30', 200, 'standard', true),
  ('Ольга', 'Соколова', 'o.sokolova@mail.ru', '+7-916-666-77-88', '1992-07-19', 1900, 'silver', true)
ON CONFLICT DO NOTHING;

-- Заказы
INSERT INTO orders (client_id, store_id, total_amount, channel, payment_method, status) VALUES
  (1, 1, 9990,  'offline', 'card',   'completed'),
  (2, 2, 17480, 'online',  'online', 'completed'),
  (3, 1, 2490,  'offline', 'cash',   'completed'),
  (4, 3, 13990, 'mobile',  'card',   'completed'),
  (5, 4, 4990,  'offline', 'card',   'processing'),
  (6, 2, 8480,  'online',  'online', 'new'),
  (1, 1, 3490,  'offline', 'cash',   'completed'),
  (2, 1, 14990, 'marketplace', 'online', 'completed')
ON CONFLICT DO NOTHING;

-- Складские остатки
INSERT INTO inventory (product_id, store_id, quantity, reserved, min_quantity) VALUES
  (1, 1, 15, 2, 5), (1, 2, 8, 0, 3), (1, 3, 4, 1, 3),
  (2, 1, 10, 1, 5), (2, 2, 6, 0, 3),
  (3, 1, 12, 3, 5), (3, 3, 7, 0, 3),
  (4, 1, 30, 0, 10),(4, 2, 20, 2, 10),
  (5, 1, 25, 1, 10),(5, 4, 18, 0, 5),
  (6, 1, 9, 2, 5),  (6, 2, 3, 1, 3),
  (7, 1, 40, 0, 10),(7, 3, 22, 0, 10),
  (8, 1, 20, 0, 5), (8, 2, 12, 1, 5),
  (9, 1, 8, 1, 3),  (10,1, 35, 0, 10)
ON CONFLICT DO NOTHING;

-- ═══════════════════════════════════════════════════
-- RLS ПОЛИТИКИ (Row Level Security)
-- Включить для защиты данных
-- ═══════════════════════════════════════════════════

-- Разрешить чтение и запись через anon ключ (для разработки)
-- В продакшне настроить более строгие правила

ALTER TABLE categories   ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers    ENABLE ROW LEVEL SECURITY;
ALTER TABLE stores       ENABLE ROW LEVEL SECURITY;
ALTER TABLE products     ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients      ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders       ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items  ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory    ENABLE ROW LEVEL SECURITY;

-- Политики полного доступа (anon — для учебного проекта)
CREATE POLICY "allow_all_categories"  ON categories  FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_suppliers"   ON suppliers   FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_stores"      ON stores      FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_products"    ON products    FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_clients"     ON clients     FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_orders"      ON orders      FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_order_items" ON order_items FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_inventory"   ON inventory   FOR ALL USING (true) WITH CHECK (true);
