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

DROP   INDEX  IF  EXISTS     idx_students_lastname;
CREATE INDEX   IF NOT EXISTS idx_students_lastname
	ON students(lastname)
--	TABLESPACE tbsp_idx_gradebook
;
DROP   INDEX IF EXIStS       idx_students_firstname ;
CREATE INDEX IF NOT EXISTS   idx_students_firstname
	ON students(firstname)
--	TABLESPACE tbsp_idx_gradebook
;
DROP          INDEX IF EXISTS      idx_classes_YQSN;
CREATE UNIQUE INDEX IF NOT EXISTS  idx_classes_YQSN
	ON classes(year, quarter, CName, section)
--	TABLESPACE tbsp_idx_gradebook
;
