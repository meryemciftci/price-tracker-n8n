
USE n8n_price_tracker;

-- Ürün bilgileri tablosu
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    url VARCHAR(1000) NOT NULL,
    site_name ENUM('amazon', 'trendyol', 'hepsiburada', 'gittigidiyor', 'other') NOT NULL,
    selector VARCHAR(500) NOT NULL COMMENT 'CSS selector for price element',
    target_price DECIMAL(10,2) DEFAULT NULL COMMENT 'Hedef fiyat - bu fiyatın altına düşünce bildirim',
    discount_threshold INT DEFAULT 10 COMMENT 'Yüzde kaç indirimde bildirim gönderilsin',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY unique_product_url (url),
    INDEX idx_site_name (site_name),
    INDEX idx_is_active (is_active)
);

-- Fiyat geçmişi tablosu
CREATE TABLE IF NOT EXISTS price_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'TRY',
    is_available BOOLEAN DEFAULT TRUE,
    discount_rate DECIMAL(5,2) DEFAULT 0.00 COMMENT 'İndirim oranı',
    scraped_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    INDEX idx_product_id (product_id),
    INDEX idx_scraped_at (scraped_at),
    INDEX idx_price (price)
);

-- Bildirim ayarları tablosu
CREATE TABLE IF NOT EXISTS notification_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    notification_type ENUM('email', 'telegram', 'discord', 'webhook') NOT NULL,
    recipient VARCHAR(255) NOT NULL COMMENT 'Email adresi, Telegram chat_id vs.',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    INDEX idx_product_id (product_id),
    INDEX idx_notification_type (notification_type)
);

-- Bildirim geçmişi tablosu
CREATE TABLE IF NOT EXISTS notification_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    recipient VARCHAR(255) NOT NULL,
    message TEXT,
    old_price DECIMAL(10,2),
    new_price DECIMAL(10,2),
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('sent', 'failed', 'pending') DEFAULT 'pending',
    
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    INDEX idx_product_id (product_id),
    INDEX idx_sent_at (sent_at),
    INDEX idx_status (status)
);

-- Site konfigürasyonları tablosu
CREATE TABLE IF NOT EXISTS site_configs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    site_name VARCHAR(50) NOT NULL UNIQUE,
    base_url VARCHAR(255),
    price_selector VARCHAR(500) NOT NULL,
    title_selector VARCHAR(500),
    availability_selector VARCHAR(500),
    wait_time INT DEFAULT 2000 COMMENT 'Sayfanın yüklenmesi için bekleme süresi (ms)',
    user_agent TEXT,
    headers JSON,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Örnek site konfigürasyonları
INSERT INTO site_configs (site_name, price_selector, title_selector, availability_selector, user_agent) VALUES
('trendyol', '.prc-dsc', '.pr-in-nm', '.pr-in-dt', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'),
('hepsiburada', '.price-value', '.product-name', '.availability', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'),
('amazon', '.a-price-whole', '#productTitle', '#availability', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36');

-- Sistem ayarları tablosu
CREATE TABLE IF NOT EXISTS system_settings (
    setting_key VARCHAR(100) PRIMARY KEY,
    setting_value TEXT,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Varsayılan sistem ayarları
INSERT INTO system_settings (setting_key, setting_value, description) VALUES
('scrape_interval_minutes', '60', 'Fiyat kontrol aralığı (dakika)'),
('max_retry_attempts', '3', 'Başarısız scraping için maksimum deneme sayısı'),
('telegram_bot_token', '', 'Telegram bot token'),
('smtp_host', '', 'Email SMTP sunucu adresi'),
('smtp_port', '587', 'Email SMTP port'),
('smtp_username', '', 'Email SMTP kullanıcı adı'),
('smtp_password', '', 'Email SMTP şifre'),
('default_currency', 'TRY', 'Varsayılan para birimi');

-- Örnek ürün ekleme (test için)
INSERT INTO products (name, url, site_name, selector, target_price, discount_threshold) VALUES
('iPhone 15 Pro', 'https://www.trendyol.com/apple/iphone-15-pro-128-gb-p-123456', 'trendyol', '.prc-dsc', 50000.00, 15),
('Samsung Galaxy S24', 'https://www.hepsiburada.com/samsung-galaxy-s24-p-123456', 'hepsiburada', '.price-value', 30000.00, 20);

-- Views oluşturma
CREATE VIEW product_current_prices AS
SELECT 
    p.id,
    p.name,
    p.url,
    p.site_name,
    p.target_price,
    ph.price as current_price,
    ph.currency,
    ph.discount_rate,
    ph.scraped_at as last_checked,
    CASE 
        WHEN p.target_price IS NOT NULL AND ph.price <= p.target_price THEN 'TARGET_REACHED'
        WHEN ph.discount_rate >= p.discount_threshold THEN 'DISCOUNT_ALERT'
        ELSE 'NORMAL'
    END as alert_status
FROM products p
LEFT JOIN price_history ph ON p.id = ph.product_id
WHERE ph.id = (
    SELECT MAX(ph2.id) 
    FROM price_history ph2 
    WHERE ph2.product_id = p.id
)
AND p.is_active = TRUE;