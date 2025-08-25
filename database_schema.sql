-- Cash In-Out App Database Schema with User Isolation

-- Create users table for authentication and user isolation
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username)
);

-- Create clients table (parent table) with user isolation
CREATE TABLE clients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_name (name),
    INDEX idx_phone (phone),
    UNIQUE KEY unique_phone_per_user (user_id, phone)
);

-- Create installment_plans table (depends on clients) with user isolation
CREATE TABLE installment_plans (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    client_id INT NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    months INT NOT NULL,
    start_date DATE NOT NULL,
    status ENUM('active', 'completed', 'cancelled') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_client_id (client_id),
    INDEX idx_status (status),
    INDEX idx_start_date (start_date)
);

-- Create installments table (depends on installment_plans) with user isolation
CREATE TABLE installments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    plan_id INT NOT NULL,
    month_year VARCHAR(7) NOT NULL, -- Format: YYYY-MM
    amount DECIMAL(10,2) NOT NULL,
    status ENUM('pending', 'paid', 'overdue', 'cancelled') DEFAULT 'pending',
    due_date DATE NOT NULL,
    paid_date DATE NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (plan_id) REFERENCES installment_plans(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_plan_id (plan_id),
    INDEX idx_status (status),
    INDEX idx_month_year (month_year),
    INDEX idx_due_date (due_date)
);

-- Create payments table (depends on clients and optionally on installments) with user isolation
CREATE TABLE payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    client_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tag VARCHAR(100) NOT NULL,
    note TEXT,
    status ENUM('sent', 'received', 'pending', 'cancelled') DEFAULT 'pending',
    installment_id INT NULL,
    reference VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (installment_id) REFERENCES installments(id) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_client_id (client_id),
    INDEX idx_installment_id (installment_id),
    INDEX idx_timestamp (timestamp),
    INDEX idx_status (status),
    INDEX idx_tag (tag)
);

-- Insert sample user for testing
INSERT INTO users (username, password, email) VALUES
('admin', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin@example.com');

-- Insert sample data for testing (associated with user_id = 1)
INSERT INTO clients (user_id, name, phone, address) VALUES
(1, 'John Doe', '+1234567890', '123 Main St, City'),
(1, 'Jane Smith', '+0987654321', '456 Oak Ave, Town'),
(1, 'Bob Johnson', '+1122334455', '789 Pine Rd, Village');

-- Insert sample installment plan
INSERT INTO installment_plans (user_id, client_id, total_amount, months, start_date) VALUES
(1, 1, 5000.00, 10, '2024-01-01');

-- Insert sample installments
INSERT INTO installments (user_id, plan_id, month_year, amount, status, due_date) VALUES
(1, 1, '2024-01', 500.00, 'paid', '2024-01-31'),
(1, 1, '2024-02', 500.00, 'pending', '2024-02-29'),
(1, 1, '2024-03', 500.00, 'pending', '2024-03-31');

-- Insert sample payments
INSERT INTO payments (user_id, client_id, amount, tag, note, status, installment_id) VALUES
(1, 1, 500.00, 'Payment', 'January installment', 'received', 1),
(1, 1, -100.00, 'Expense', 'Service charge', 'sent', NULL),
(1, 2, 1000.00, 'Payment', 'Initial payment', 'received', NULL);

-- Create views for easier querying with user isolation
CREATE VIEW client_summary AS
SELECT 
    c.id,
    c.user_id,
    c.name,
    c.phone,
    c.address,
    COALESCE(SUM(CASE WHEN p.amount > 0 THEN p.amount ELSE 0 END), 0) as total_credit,
    COALESCE(SUM(CASE WHEN p.amount < 0 THEN ABS(p.amount) ELSE 0 END), 0) as total_debit,
    COALESCE(SUM(p.amount), 0) as net_balance,
    COUNT(p.id) as total_transactions,
    MAX(p.timestamp) as last_transaction_date
FROM clients c
LEFT JOIN payments p ON c.id = p.client_id AND c.user_id = p.user_id
GROUP BY c.id, c.user_id, c.name, c.phone, c.address;

CREATE VIEW installment_summary AS
SELECT 
    ip.id as plan_id,
    ip.user_id,
    c.name as client_name,
    ip.total_amount,
    ip.months,
    ip.start_date,
    ip.status as plan_status,
    COUNT(i.id) as total_installments,
    COUNT(CASE WHEN i.status = 'paid' THEN 1 END) as paid_installments,
    COUNT(CASE WHEN i.status = 'pending' THEN 1 END) as pending_installments,
    COUNT(CASE WHEN i.status = 'overdue' THEN 1 END) as overdue_installments
FROM installment_plans ip
JOIN clients c ON ip.client_id = c.id AND ip.user_id = c.user_id
LEFT JOIN installments i ON ip.id = i.plan_id AND ip.user_id = i.user_id
GROUP BY ip.id, ip.user_id, c.name, ip.total_amount, ip.months, ip.start_date, ip.status;

-- Create stored procedures for common operations with user isolation
DELIMITER //

CREATE PROCEDURE DeleteClientWithRelations(IN user_id_param INT, IN client_id INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Delete all related records in proper order (only for the specific user)
    DELETE FROM payments WHERE client_id = client_id AND user_id = user_id_param;
    DELETE FROM installments WHERE plan_id IN (SELECT id FROM installment_plans WHERE client_id = client_id AND user_id = user_id_param) AND user_id = user_id_param;
    DELETE FROM installment_plans WHERE client_id = client_id AND user_id = user_id_param;
    DELETE FROM clients WHERE id = client_id AND user_id = user_id_param;
    
    COMMIT;
END //

CREATE PROCEDURE GetClientLedger(IN user_id_param INT, IN client_id INT, IN start_date DATE, IN end_date DATE)
BEGIN
    SELECT 
        p.id,
        p.client_id,
        p.timestamp as date,
        CONCAT(p.tag, ' - ', p.note) as description,
        CASE 
            WHEN p.amount < 0 THEN ABS(p.amount)
            ELSE 0 
        END as debit,
        CASE 
            WHEN p.amount > 0 THEN p.amount
            ELSE 0 
        END as credit,
        p.amount as running_balance,
        p.tag as reference,
        p.note as notes,
        p.installment_id
    FROM payments p 
    WHERE p.client_id = client_id 
    AND p.user_id = user_id_param
    AND (start_date IS NULL OR DATE(p.timestamp) >= start_date)
    AND (end_date IS NULL OR DATE(p.timestamp) <= end_date)
    ORDER BY p.timestamp ASC, p.id ASC;
END //

DELIMITER ;

-- Grant permissions (adjust as needed for your setup)
-- GRANT ALL PRIVILEGES ON flutter_auth.* TO 'root'@'localhost';
-- FLUSH PRIVILEGES;
