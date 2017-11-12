/*
 Use this command to create an index on:
 
   *  one or more columns of a table, a partitioned table, or a
      cluster
   *  one or more scalar typed object attributes of a table or a
      cluster
   *  a nested table storage table for indexing a nested table column
 
 An index is a schema object that contains an entry for each value
 that appears in the indexed column(s) of the table or cluster and
 provides direct, fast access to rows. A partitioned index consists
 of partitions containing an entry for each value that appears in the
 indexed column(s) of the table.

Postgre Syntax:
CREATE [ UNIQUE ] INDEX [ CONCURRENTLY ] [ [ IF NOT EXISTS ] name ] ON table_name 
       [ USING method ] ( { column_name | ( expression ) } [ COLLATE collation ] 
       [ opclass ] [ ASC | DESC ] [ NULLS { FIRST | LAST } ] [, ...] )
       [ WITH ( storage_parameter = value [, ... ] ) ]
       [ TABLESPACE tablespace_name ]
      [ WHERE predicate ]
 
*/

-- The follwoing creating-tabelespace are correct and
-- creating index with tablespace are correct also.
-- However, for easy to export to othter machine,
-- Tbalespace will not created in the application.

--DROP   TABLESPACE tbsp_idx_gradebook;
--CREATE TABLESPACE tbsp_idx_gradebook  OWNER gradebook
--LOCATION '/Library/PostgreSQL/data/gradebook_idx';

DROP   INDEX  IF  EXISTS     idx_Customer_Lname;
CREATE INDEX   IF NOT EXISTS idx_Customer_Lname
	ON Customer(Lname)
--	TABLESPACE tbsp_idx_gradebook
;
DROP   INDEX IF EXIStS       idx_Customer_Fname ;
CREATE INDEX IF NOT EXISTS   idx_Customer_Fname
	ON Customer(Fname)
--	TABLESPACE tbsp_idx_gradebook
;
DROP          INDEX IF EXISTS      idx_Orders_num;
CREATE UNIQUE INDEX IF NOT EXISTS  idx_Orders_num
	ON Orders(Datee, Order_num)
--	TABLESPACE tbsp_idx_gradebook
;
