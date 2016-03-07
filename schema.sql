DROP DATABASE IF EXISTS mez_main;
CREATE DATABASE mez_main;


-- CREATE USERS 'sidewinders_fang_admin'@'localhost';
-- CREATE USERS 'sidewinders_fang_rw'@'localhost';
-- CREATE USER 'sidewinders_fang_ro'@'localhost’;

GRANT ALL ON *.* TO 'sfang_admin'@'localhost';
GRANT CREATE, DROP, SELECT, INSERT, UPDATE, DELETE ON *.* TO 'sfang_rw'@'localhost';
GRANT SELECT ON *.* TO 'sfang_ro'@'localhost';

USE mez_main;

-- UUIDs:
-- binary(16) is better, then we can use UNHEX(REPLACE(UUID(),'-','')) and HEX(?)
-- to pass values in and out, but varchar is easier to debug.
