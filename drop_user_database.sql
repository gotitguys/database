-- The gradebook database and the user have the same names.
-- To drop a database and its owner/user,  
--    (1) you must drop datbase first and then drop the owner.
--    (2) You must be login psql as 'postgres' and you are not connected to
--        the database you are going to remove.
DROP DATABASE IF EXiSTS store;
DROP USER IF EXISTS store;

