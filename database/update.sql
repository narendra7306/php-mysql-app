.-- Step 1: Create the ltts database
CREATE DATABASE IF NOT EXISTS ltts;

-- Step 2: Switch to ltts
USE ltts;

-- Step 3: Create the users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- Step 4: Insert user Narendra
INSERT INTO users (name) VALUES ('Narendra');

-- Step 5: Verify the data
SELECT * FROM users;
