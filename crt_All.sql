-- Create database user, tablespaces and database. Both user and database names are gradebook.
\i crt_user_tspace_db.sql
\! echo	    user <gradebook> and database <gradebook> are created.

-- Before you create database schema objects. Otherwise the objects will be created in postgres databse. 
--	(1) must connect to the database 'gradebook'
--      (2) Optionally, you can set 'gradebook' as user or called role.
\c gradebook
SET ROLE gradebook;

-- Create all gradebook database schema objects.
\i crt_sequences_tables.sql
\i crt_indexes.sql
\i crt_view_trigger.sql
\i crt_procedures.sql

\q
