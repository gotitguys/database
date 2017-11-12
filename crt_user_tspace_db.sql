/*______________________________________________________
-- Create default, index, and temporary  tablespaces 
   for user Gradebook.

   In Oracle 10g, 
     1. Create the subdirectory in which dababase files
	are to be held.
     2. Do not create dbf files. Otherwise syntax error
	will occur.
_______________________________________________________*/

CREATE USER store SUPERUSER PASSWORD 'store';  -- create a role.

/*
CREATE TABLESPACE gb_data 
	 OWNER gradebook
	 LOCATION '/Library/PostgreSQL/9.6/data'  -- The folder cannot be sused to hold tablespace
 --      [ WITH ( tablespace_option = value [, ... ] ) ]
;
*/
CREATE DATABASE store WITH OWNER = store;  --[TABLESPACE = gb_data]; 

