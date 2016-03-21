DROP DATABASE IF EXISTS mez_main;
CREATE DATABASE mez_main;

DROP USER IF EXISTS 'sfang_admin'@'localhost';
CREATE USER 'sfang_admin'@'localhost' IDENTIFIED BY 'password';
DROP USER IF EXISTS 'sfang_rw'@'localhost';
CREATE USER 'sfang_rw'@'localhost' IDENTIFIED BY 'password';
DROP USER IF EXISTS 'sfang_ro'@'localhost';
CREATE USER 'sfang_ro'@'localhost' IDENTIFIED BY 'password';

GRANT ALL ON *.* TO 'sfang_admin'@'localhost';
GRANT CREATE, DROP, SELECT, INSERT, UPDATE, DELETE ON *.* TO 'sfang_rw'@'localhost';
GRANT SELECT ON *.* TO 'sfang_ro'@'localhost';

USE mez_main;

-- UUIDs:
-- binary(16) is better, then we can use UNHEX(REPLACE(UUID(),'-','')) and HEX(?)
-- to pass values in and out, but varchar is easier to debug.
