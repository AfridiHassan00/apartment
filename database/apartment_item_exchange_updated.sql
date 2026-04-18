DROP DATABASE IF EXISTS apartment_item_exchange_db;
CREATE DATABASE apartment_item_exchange_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE apartment_item_exchange_db;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS offers;
DROP TABLE IF EXISTS post_images;
DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS apartments;
DROP TABLE IF EXISTS buildings;
DROP TABLE IF EXISTS complexes;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE complexes (
    complex_id INT AUTO_INCREMENT PRIMARY KEY,
    complex_name VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_complex_name (complex_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE buildings (
    building_id INT AUTO_INCREMENT PRIMARY KEY,
    complex_id INT NOT NULL,
    building_no VARCHAR(20) NOT NULL,
    floor_count INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_buildings_complex
        FOREIGN KEY (complex_id) REFERENCES complexes(complex_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    UNIQUE KEY uq_building_per_complex (complex_id, building_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE apartments (
    apartment_id INT AUTO_INCREMENT PRIMARY KEY,
    building_id INT NOT NULL,
    unit_no VARCHAR(20) NOT NULL,
    floor_no INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_apartments_building
        FOREIGN KEY (building_id) REFERENCES buildings(building_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    UNIQUE KEY uq_apartment_per_building (building_id, unit_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    apartment_id INT NULL,
    full_name VARCHAR(120) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(120) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    profile_photo VARCHAR(255) NULL,
    verification_status ENUM('pending', 'verified', 'rejected') NOT NULL DEFAULT 'pending',
    account_status ENUM('active', 'inactive', 'suspended') NOT NULL DEFAULT 'active',
    last_login DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_apartment
        FOREIGN KEY (apartment_id) REFERENCES apartments(apartment_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    UNIQUE KEY uq_users_email (email),
    UNIQUE KEY uq_users_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    description VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_category_name (category_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE posts (
    post_id INT AUTO_INCREMENT PRIMARY KEY,
    seller_id INT NOT NULL,
    category_id INT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    condition_status ENUM('new', 'like_new', 'good', 'fair') NOT NULL DEFAULT 'good',
    post_status ENUM('available', 'reserved', 'sold', 'hidden') NOT NULL DEFAULT 'available',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_posts_seller
        FOREIGN KEY (seller_id) REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_posts_category
        FOREIGN KEY (category_id) REFERENCES categories(category_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    KEY idx_posts_status (post_status),
    KEY idx_posts_seller (seller_id),
    KEY idx_posts_category (category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE post_images (
    image_id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    image_order INT NOT NULL DEFAULT 1,
    caption VARCHAR(150) NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_post_images_post
        FOREIGN KEY (post_id) REFERENCES posts(post_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    UNIQUE KEY uq_post_image_order (post_id, image_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE offers (
    offer_id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    buyer_id INT NOT NULL,
    offer_amount DECIMAL(10,2) NOT NULL,
    offer_status ENUM('pending', 'accepted', 'rejected', 'cancelled') NOT NULL DEFAULT 'pending',
    message VARCHAR(255) NULL,
    offer_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_offers_post
        FOREIGN KEY (post_id) REFERENCES posts(post_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_offers_buyer
        FOREIGN KEY (buyer_id) REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    UNIQUE KEY uq_offer_buyer_post (post_id, buyer_id),
    KEY idx_offers_status (offer_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    buyer_id INT NOT NULL,
    transaction_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    final_price DECIMAL(10,2) NOT NULL,
    payment_status ENUM('pending', 'paid', 'refunded') NOT NULL DEFAULT 'pending',
    delivery_type ENUM('pickup', 'delivery') NOT NULL DEFAULT 'pickup',
    transaction_status ENUM('completed', 'cancelled') NOT NULL DEFAULT 'completed',
    CONSTRAINT fk_transactions_post
        FOREIGN KEY (post_id) REFERENCES posts(post_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_transactions_buyer
        FOREIGN KEY (buyer_id) REFERENCES users(user_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    UNIQUE KEY uq_transactions_post (post_id),
    KEY idx_transactions_buyer (buyer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    message VARCHAR(255) NOT NULL,
    notification_type ENUM('system', 'offer', 'transaction', 'post') NOT NULL DEFAULT 'system',
    is_read TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notifications_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    KEY idx_notifications_user_read (user_id, is_read)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO complexes (complex_name, address) VALUES
('Lakeview Residency', 'Plot 12, Kaliganj, Bangladesh'),
('Green Tower', 'Road 7, Dhaka, Bangladesh');

INSERT INTO buildings (complex_id, building_no, floor_count) VALUES
(1, 'A', 8),
(1, 'B', 10),
(2, '1', 12);

INSERT INTO apartments (building_id, unit_no, floor_no) VALUES
(1, 'A-101', 1),
(1, 'A-203', 2),
(2, 'B-305', 3),
(3, '1-804', 8);

INSERT INTO users (apartment_id, full_name, phone, email, password_hash, profile_photo, verification_status, account_status, last_login) VALUES
(1, 'Demo User', '01700000001', 'demo@example.com', '$2y$12$sv4D5drrFFXxXRGlvj7ys.nFJHO/UOL8KybzF/Hx0XYd6ka6eCBXu', NULL, 'verified', 'active', NULL),
(2, 'Ayesha Khan', '01700000002', 'ayesha@example.com', '$2y$12$sv4D5drrFFXxXRGlvj7ys.nFJHO/UOL8KybzF/Hx0XYd6ka6eCBXu', NULL, 'verified', 'active', NULL),
(3, 'Rahim Uddin', '01700000003', 'rahim@example.com', '$2y$12$sv4D5drrFFXxXRGlvj7ys.nFJHO/UOL8KybzF/Hx0XYd6ka6eCBXu', NULL, 'pending', 'active', NULL),
(4, 'Nusrat Jahan', '01700000004', 'nusrat@example.com', '$2y$12$sv4D5drrFFXxXRGlvj7ys.nFJHO/UOL8KybzF/Hx0XYd6ka6eCBXu', NULL, 'verified', 'active', NULL);

INSERT INTO categories (category_name, description) VALUES
('Electronics', 'Phones, laptops, accessories and gadgets'),
('Furniture', 'Tables, chairs, beds and household furniture'),
('Books', 'Academic and non-academic books'),
('Appliances', 'Small and large household appliances');

INSERT INTO posts (seller_id, category_id, title, description, price, condition_status, post_status) VALUES
(2, 1, 'Used Laptop', 'Core i5 laptop in good condition with charger included.', 38000.00, 'good', 'available'),
(3, 2, 'Wooden Study Table', 'Strong table suitable for study or office use.', 5500.00, 'good', 'available'),
(4, 4, 'Microwave Oven', 'Compact microwave oven, fully functional.', 9000.00, 'like_new', 'reserved'),
(2, 3, 'Database Management Book', 'Useful for university students preparing for exams.', 450.00, 'fair', 'sold');

INSERT INTO post_images (post_id, image_url, image_order, caption) VALUES
(1, 'uploads/laptop_front.jpg', 1, 'Front view'),
(1, 'uploads/laptop_keyboard.jpg', 2, 'Keyboard view'),
(2, 'uploads/study_table.jpg', 1, 'Table image'),
(3, 'uploads/microwave.jpg', 1, 'Microwave front'),
(4, 'uploads/db_book.jpg', 1, 'Book cover');

INSERT INTO offers (post_id, buyer_id, offer_amount, offer_status, message) VALUES
(1, 1, 35000.00, 'pending', 'Can you reduce the price a bit?'),
(2, 1, 5000.00, 'accepted', 'I can pick it up this evening.'),
(3, 2, 8500.00, 'rejected', 'Please let me know if still available.');

INSERT INTO transactions (post_id, buyer_id, transaction_date, final_price, payment_status, delivery_type, transaction_status) VALUES
(4, 1, '2026-04-10 18:30:00', 400.00, 'paid', 'pickup', 'completed');

INSERT INTO notifications (user_id, message, notification_type, is_read) VALUES
(1, 'Your offer on Used Laptop is still pending.', 'offer', 0),
(2, 'A new offer was placed on your post Used Laptop.', 'offer', 0),
(1, 'Your transaction for Database Management Book was completed.', 'transaction', 1),
(4, 'Your post Microwave Oven was marked as reserved.', 'post', 0);
