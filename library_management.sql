-- =============================================
-- Library Management System Database
-- Author: [Your Name]
-- Date: [Current Date]
-- =============================================

-- Create Database
CREATE DATABASE IF NOT EXISTS library_management_system;
USE library_management_system;

-- =============================================
-- 1. Core Entity Tables
-- =============================================

-- Members table (Patrons/Library Users)
CREATE TABLE members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    library_card_number VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE NOT NULL,
    address TEXT,
    city VARCHAR(50),
    state VARCHAR(50),
    zip_code VARCHAR(20),
    membership_type ENUM('Student', 'Faculty', 'Staff', 'Public') DEFAULT 'Public',
    membership_status ENUM('Active', 'Inactive', 'Suspended') DEFAULT 'Active',
    date_joined DATE NOT NULL,
    expiry_date DATE NOT NULL,
    max_books_allowed INT DEFAULT 5,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_email (email),
    INDEX idx_membership_status (membership_status),
    INDEX idx_expiry_date (expiry_date)
);

-- Authors table
CREATE TABLE authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE,
    death_date DATE,
    nationality VARCHAR(50),
    biography TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_author_name (last_name, first_name)
);

-- Publishers table
CREATE TABLE publishers (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY,
    publisher_name VARCHAR(100) UNIQUE NOT NULL,
    address TEXT,
    city VARCHAR(50),
    country VARCHAR(50),
    phone VARCHAR(20),
    email VARCHAR(100),
    website VARCHAR(200),
    established_year YEAR,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_publisher_name (publisher_name)
);

-- =============================================
-- 2. Book-Related Tables
-- =============================================

-- Books table (Main book information)
CREATE TABLE books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    isbn VARCHAR(20) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    edition VARCHAR(10),
    publication_year YEAR,
    publisher_id INT NOT NULL,
    language VARCHAR(30) DEFAULT 'English',
    page_count INT,
    description TEXT,
    genre VARCHAR(50),
    dewey_decimal_number VARCHAR(20),
    acquisition_date DATE NOT NULL,
    acquisition_price DECIMAL(10,2),
    book_status ENUM('Available', 'Checked Out', 'Lost', 'Damaged', 'Under Repair') DEFAULT 'Available',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (publisher_id) REFERENCES publishers(publisher_id) ON DELETE RESTRICT,
    
    INDEX idx_title (title),
    INDEX idx_isbn (isbn),
    INDEX idx_genre (genre),
    INDEX idx_book_status (book_status),
    INDEX idx_publication_year (publication_year)
);

-- Book-Author relationship (Many-to-Many)
CREATE TABLE book_authors (
    book_author_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    author_order INT DEFAULT 1, -- To indicate primary author (1), secondary (2), etc.
    
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE CASCADE,
    
    UNIQUE KEY unique_book_author (book_id, author_id),
    INDEX idx_book_id (book_id),
    INDEX idx_author_id (author_id)
);

-- Book Copies table (Multiple copies of the same book)
CREATE TABLE book_copies (
    copy_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    barcode VARCHAR(50) UNIQUE NOT NULL,
    copy_number INT NOT NULL,
    location VARCHAR(100), -- Shelf location
    condition ENUM('New', 'Good', 'Fair', 'Poor', 'Damaged') DEFAULT 'Good',
    status ENUM('Available', 'Checked Out', 'Lost', 'Damaged', 'Under Repair') DEFAULT 'Available',
    acquisition_date DATE,
    last_maintenance_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    
    UNIQUE KEY unique_book_copy (book_id, copy_number),
    INDEX idx_barcode (barcode),
    INDEX idx_status (status),
    INDEX idx_location (location)
);

-- =============================================
-- 3. Transaction Tables
-- =============================================

-- Loans table (Book checkouts)
CREATE TABLE loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    copy_id INT NOT NULL,
    member_id INT NOT NULL,
    checkout_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE,
    loan_status ENUM('Active', 'Returned', 'Overdue', 'Lost') DEFAULT 'Active',
    renewed_count INT DEFAULT 0,
    late_fee DECIMAL(8,2) DEFAULT 0.00,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (copy_id) REFERENCES book_copies(copy_id) ON DELETE RESTRICT,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE RESTRICT,
    
    INDEX idx_member_id (member_id),
    INDEX idx_due_date (due_date),
    INDEX idx_loan_status (loan_status),
    INDEX idx_checkout_date (checkout_date)
);

-- Reservations table
CREATE TABLE reservations (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    reservation_date DATETIME NOT NULL,
    reservation_status ENUM('Active', 'Fulfilled', 'Cancelled', 'Expired') DEFAULT 'Active',
    priority_number INT,
    expiry_date DATETIME,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    
    UNIQUE KEY unique_active_reservation (book_id, member_id, reservation_status),
    INDEX idx_reservation_date (reservation_date),
    INDEX idx_reservation_status (reservation_status),
    INDEX idx_member_reservations (member_id, reservation_status)
);

-- Fines table
CREATE TABLE fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    loan_id INT,
    fine_type ENUM('Late Return', 'Lost Book', 'Damage', 'Other') NOT NULL,
    amount DECIMAL(8,2) NOT NULL,
    fine_date DATE NOT NULL,
    due_date DATE NOT NULL,
    payment_date DATE,
    fine_status ENUM('Pending', 'Paid', 'Waived', 'Cancelled') DEFAULT 'Pending',
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id) ON DELETE SET NULL,
    
    INDEX idx_member_id (member_id),
    INDEX idx_fine_status (fine_status),
    INDEX idx_due_date (due_date)
);

-- =============================================
-- 4. Library Staff and Management Tables
-- =============================================

-- Staff table
CREATE TABLE staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    position VARCHAR(50) NOT NULL,
    department VARCHAR(50),
    hire_date DATE NOT NULL,
    salary DECIMAL(10,2),
    status ENUM('Active', 'Inactive', 'On Leave') DEFAULT 'Active',
    username VARCHAR(50) UNIQUE,
    password_hash VARCHAR(255), -- For authentication
    last_login DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_email (email),
    INDEX idx_position (position),
    INDEX idx_department (department)
);

-- Staff roles and permissions
CREATE TABLE staff_roles (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) UNIQUE NOT NULL,
    permissions JSON, -- Store permissions as JSON
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Staff role assignments
CREATE TABLE staff_role_assignments (
    assignment_id INT AUTO_INCREMENT PRIMARY KEY,
    staff_id INT NOT NULL,
    role_id INT NOT NULL,
    assigned_date DATE NOT NULL,
    assigned_by INT, -- Staff who assigned this role
    
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES staff_roles(role_id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by) REFERENCES staff(staff_id) ON DELETE SET NULL,
    
    UNIQUE KEY unique_staff_role (staff_id, role_id),
    INDEX idx_staff_id (staff_id)
);

-- =============================================
-- 5. Additional Feature Tables
-- =============================================

-- Library branches table (for multi-branch systems)
CREATE TABLE library_branches (
    branch_id INT AUTO_INCREMENT PRIMARY KEY,
    branch_code VARCHAR(10) UNIQUE NOT NULL,
    branch_name VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50),
    zip_code VARCHAR(20),
    phone VARCHAR(20),
    email VARCHAR(100),
    manager_id INT,
    opening_hours JSON, -- Store as JSON for flexibility
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (manager_id) REFERENCES staff(staff_id) ON DELETE SET NULL,
    
    INDEX idx_branch_code (branch_code)
);

-- Book categories/genres table
CREATE TABLE genres (
    genre_id INT AUTO_INCREMENT PRIMARY KEY,
    genre_name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    parent_genre_id INT, -- For hierarchical categories
    
    FOREIGN KEY (parent_genre_id) REFERENCES genres(genre_id) ON DELETE SET NULL,
    
    INDEX idx_genre_name (genre_name)
);

-- Reviews and ratings table
CREATE TABLE book_reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    rating INT CHECK (rating >= 1 AND rating <= 5),
    review_title VARCHAR(200),
    review_text TEXT,
    review_date DATETIME NOT NULL,
    approved BOOLEAN DEFAULT FALSE, -- For moderation
    approved_by INT,
    approved_date DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES staff(staff_id) ON DELETE SET NULL,
    
    UNIQUE KEY unique_member_book_review (member_id, book_id),
    INDEX idx_book_id (book_id),
    INDEX idx_rating (rating),
    INDEX idx_review_date (review_date)
);

-- =============================================
-- 6. Audit and Logging Tables
-- =============================================

-- Activity log table
CREATE TABLE activity_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    staff_id INT,
    member_id INT,
    activity_type VARCHAR(50) NOT NULL,
    activity_description TEXT NOT NULL,
    table_affected VARCHAR(50),
    record_id INT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    log_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE SET NULL,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE SET NULL,
    
    INDEX idx_activity_type (activity_type),
    INDEX idx_log_timestamp (log_timestamp),
    INDEX idx_staff_activity (staff_id, log_timestamp)
);

-- System settings table
CREATE TABLE system_settings (
    setting_id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT NOT NULL,
    setting_description TEXT,
    data_type ENUM('string', 'integer', 'boolean', 'json') DEFAULT 'string',
    is_public BOOLEAN DEFAULT FALSE,
    updated_by INT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (updated_by) REFERENCES staff(staff_id) ON DELETE SET NULL,
    
    INDEX idx_setting_key (setting_key)
);

-- =============================================
-- 7. Views for Common Queries
-- =============================================

-- View for currently checked out books
CREATE VIEW current_loans AS
SELECT 
    l.loan_id,
    m.member_id,
    m.first_name,
    m.last_name,
    m.library_card_number,
    b.book_id,
    b.title,
    b.isbn,
    bc.copy_id,
    bc.barcode,
    l.checkout_date,
    l.due_date,
    l.loan_status,
    DATEDIFF(CURDATE(), l.due_date) AS days_overdue
FROM loans l
JOIN members m ON l.member_id = m.member_id
JOIN book_copies bc ON l.copy_id = bc.copy_id
JOIN books b ON bc.book_id = b.book_id
WHERE l.loan_status = 'Active' AND l.return_date IS NULL;

-- View for book availability
CREATE VIEW book_availability AS
SELECT 
    b.book_id,
    b.title,
    b.isbn,
    COUNT(bc.copy_id) AS total_copies,
    SUM(CASE WHEN bc.status = 'Available' THEN 1 ELSE 0 END) AS available_copies,
    SUM(CASE WHEN bc.status = 'Checked Out' THEN 1 ELSE 0 END) AS checked_out_copies,
    COUNT(r.reservation_id) AS active_reservations
FROM books b
LEFT JOIN book_copies bc ON b.book_id = bc.book_id
LEFT JOIN reservations r ON b.book_id = r.book_id AND r.reservation_status = 'Active'
GROUP BY b.book_id, b.title, b.isbn;

-- View for member overview
CREATE VIEW member_overview AS
SELECT 
    m.member_id,
    m.library_card_number,
    m.first_name,
    m.last_name,
    m.email,
    m.membership_type,
    m.membership_status,
    COUNT(DISTINCT l.loan_id) AS total_loans,
    COUNT(DISTINCT CASE WHEN l.loan_status = 'Active' THEN l.loan_id END) AS current_loans,
    COUNT(DISTINCT r.reservation_id) AS active_reservations,
    COALESCE(SUM(f.amount), 0) AS total_fines,
    COALESCE(SUM(CASE WHEN f.fine_status = 'Pending' THEN f.amount ELSE 0 END), 0) AS pending_fines
FROM members m
LEFT JOIN loans l ON m.member_id = l.member_id
LEFT JOIN reservations r ON m.member_id = r.member_id AND r.reservation_status = 'Active'
LEFT JOIN fines f ON m.member_id = f.member_id
GROUP BY m.member_id, m.library_card_number, m.first_name, m.last_name, m.email, m.membership_type, m.membership_status;

-- =============================================
-- 8. Sample Data Insertion
-- =============================================

-- Insert sample publishers
INSERT INTO publishers (publisher_name, city, country, established_year) VALUES
('Penguin Random House', 'New York', 'USA', 2013),
('HarperCollins', 'New York', 'USA', 1989),
('Simon & Schuster', 'New York', 'USA', 1924),
('Macmillan Publishers', 'London', 'UK', 1843),
('Hachette Livre', 'Paris', 'France', 1826);

-- Insert sample authors
INSERT INTO authors (first_name, last_name, birth_date, nationality) VALUES
('George', 'Orwell', '1903-06-25', 'British'),
('J.K.', 'Rowling', '1965-07-31', 'British'),
('Stephen', 'King', '1947-09-21', 'American'),
('Agatha', 'Christie', '1890-09-15', 'British'),
('J.R.R.', 'Tolkien', '1892-01-03', 'British');

-- Insert sample books
INSERT INTO books (isbn, title, publication_year, publisher_id, page_count, genre) VALUES
('978-0451524935', '1984', 1949, 1, 328, 'Dystopian Fiction'),
('978-0439064866', 'Harry Potter and the Chamber of Secrets', 1998, 2, 341, 'Fantasy'),
('978-1501142970', 'The Shining', 1977, 3, 447, 'Horror'),
('978-0062073501', 'Murder on the Orient Express', 1934, 4, 256, 'Mystery'),
('978-0547928227', 'The Hobbit', 1937, 5, 310, 'Fantasy');

-- Insert book-author relationships
INSERT INTO book_authors (book_id, author_id, author_order) VALUES
(1, 1, 1), -- 1984 by George Orwell
(2, 2, 1), -- Harry Potter by J.K. Rowling
(3, 3, 1), -- The Shining by Stephen King
(4, 4, 1), -- Murder on the Orient Express by Agatha Christie
(5, 5, 1); -- The Hobbit by J.R.R. Tolkien

-- Insert sample book copies
INSERT INTO book_copies (book_id, barcode, copy_number, location, condition) VALUES
(1, 'BC001001', 1, 'Fiction Section - Shelf A1', 'Good'),
(1, 'BC001002', 2, 'Fiction Section - Shelf A1', 'New'),
(2, 'BC002001', 1, 'Fantasy Section - Shelf B2', 'Good'),
(3, 'BC003001', 1, 'Horror Section - Shelf C3', 'Fair'),
(4, 'BC004001', 1, 'Mystery Section - Shelf D4', 'Good'),
(5, 'BC005001', 1, 'Fantasy Section - Shelf B2', 'New');

-- Insert sample members
INSERT INTO members (library_card_number, first_name, last_name, email, date_of_birth, membership_type, date_joined, expiry_date) VALUES
('LC1001', 'John', 'Smith', 'john.smith@email.com', '1990-05-15', 'Public', '2023-01-15', '2024-01-15'),
('LC1002', 'Sarah', 'Johnson', 'sarah.j@email.com', '1985-08-22', 'Faculty', '2023-02-20', '2024-02-20'),
('LC1003', 'Michael', 'Brown', 'm.brown@email.com', '1995-12-10', 'Student', '2023-03-10', '2024-03-10');

-- Insert sample staff
INSERT INTO staff (employee_id, first_name, last_name, email, position, hire_date) VALUES
('EMP001', 'Alice', 'Williams', 'alice.w@library.com', 'Head Librarian', '2020-01-15'),
('EMP002', 'David', 'Miller', 'david.m@library.com', 'Assistant Librarian', '2021-06-01'),
('EMP003', 'Emily', 'Davis', 'emily.d@library.com', 'Circulation Desk', '2022-03-15');

-- =============================================
-- 9. Database Documentation
-- =============================================

-- Show table relationships
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'library_management_system' 
AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, CONSTRAINT_NAME;

-- Display table counts
SELECT 
    TABLE_NAME,
    TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'library_management_system'
ORDER BY TABLE_NAME;

-- =============================================
-- 10. Utility Queries for Common Operations
-- =============================================

-- Query to find overdue books
DELIMITER //
CREATE PROCEDURE GetOverdueBooks()
BEGIN
    SELECT 
        m.library_card_number,
        m.first_name,
        m.last_name,
        b.title,
        l.due_date,
        DATEDIFF(CURDATE(), l.due_date) AS days_overdue
    FROM loans l
    JOIN members m ON l.member_id = m.member_id
    JOIN book_copies bc ON l.copy_id = bc.copy_id
    JOIN books b ON bc.book_id = b.book_id
    WHERE l.loan_status = 'Active' 
    AND l.return_date IS NULL 
    AND l.due_date < CURDATE();
END //
DELIMITER ;

-- Query to calculate member statistics
DELIMITER //
CREATE PROCEDURE GetMemberStatistics(IN member_id_param INT)
BEGIN
    SELECT 
        m.first_name,
        m.last_name,
        COUNT(l.loan_id) AS total_loans,
        COUNT(CASE WHEN l.loan_status = 'Active' THEN 1 END) AS current_loans,
        COUNT(r.reservation_id) AS active_reservations,
        COALESCE(SUM(f.amount), 0) AS total_fines_owed
    FROM members m
    LEFT JOIN loans l ON m.member_id = l.member_id
    LEFT JOIN reservations r ON m.member_id = r.member_id AND r.reservation_status = 'Active'
    LEFT JOIN fines f ON m.member_id = f.member_id AND f.fine_status = 'Pending'
    WHERE m.member_id = member_id_param
    GROUP BY m.member_id;
END //
DELIMITER ;

-- =============================================
-- End of Library Management System Database
-- =============================================