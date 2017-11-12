-- All columns in grades are updatable, insertable and deletable
-- through the view while firstname and lastname are not updatable.
-- Call show_UID_cols.sql in utils to see which columns of a view
-- or table are updatable, insertable and deletable.

CREATE OR REPLACE view vClasses AS
SELECT CID, year, substring( upper(quarter), 1, 1) || substring(lower(quarter), 2) Quarter, cName
from   classes;

CREATE OR REPLACE View allTables AS
SELECT  tablename tname FROM  pg_tables
WHERE tableowner = 'gradebook'
;


CREATE OR REPLACE VIEW vtable_fk AS 
SELECT
    ccu.table_name AS tname,  	-- table referenced by foreign key  
    tc.table_name AS  tname_w_fk -- table with foreign key
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
WHERE constraint_type = 'FOREIGN KEY'
;


-- The view will list all tables of gradebook in such an order
-- so that the tables with primary keys referenced by other tables
-- will appear first in the list while the tables with foreign key
-- constraints will list late. The orer is critial to to import and
--- output utilities.

CREATE or REPLACE VIEW vTable_in_Order AS 
SELECT a.tname  
FROM 	alltables a left outer join vtable_fk b on a.tname = b.tname
ORDER BY tname_w_fk
;

CREATE OR REPLACE VIEW vYears AS
    SELECT DISTINCT Year From Classes
    Order by Year DESC
;
CREATE OR REPLACE VIEW vStudents AS
    SELECT sid , lastName, firstName, Active, OSuserName, majorCode, major
    From Students s, Majors m
    WHERE m.code = majorCode
;

CREATE OR REPLACE VIEW vMajors AS
   SELECT Code "Major Code", Major "Long Name", ShortName "Short Name"
   FROM Majors
;

CREATE OR REPLACE VIEW vgrades AS
    SELECT grades.CID, grades.SID,
	students.lastname,
	students.firstname,
	grades.rank, grades.Total, grades.Grade, 
	grades.hw1, grades.hw2, grades.hw3, grades.hw4, grades.hw5, grades.hw6,
	grades.hw7, grades.hw8, grades.hw9, grades.hw10,
	grades.hw11, grades.hw12, grades.hw13, grades.hw14, grades.hw15,
	grades.hw16, grades.hw17, grades.hw18, grades.hw19, grades.hw20,
	grades.mid1, grades.mid2, grades.final, grades.comments
    FROM students, grades
    WHERE students.sid = grades.sid
;

CREATE OR REPLACE VIEW vActiveStudents AS
    SELECT sid , lastName, firstName, Active, OSuserName, majorCode  From Students
    WHERE  upper(active) = 'Y'
;

CREATE OR REPLACE VIEW vInactiveStudents AS
    SELECT sid , lastName, firstName, Active, OSuserName, majorCode  From Students
    WHERE  upper(active) <> 'Y' 
;

CREATE OR REPLACE VIEW vAllgrades AS
   select grades.sid, lastname, firstName, grade as gr,
       CName, initCap(lower(quarter)) || '/' || year as when,
       IID
   from students, grades, classes
   where students.sid = grades.sid AND grades.cid = classes.cid
;

/* Need to read more to write a INSTEAD OF TRIGGER in postgresSQL.
CREATE OR REPLACE TRIGGER trg_update_on_vgrades
INSTEAD OF update on vgrades
FOR EACH ROW
BEGIN
   update grades set
		hw1 = :new.hw1,
		hw2 = :new.hw2
   where cid = :old.cid and sid = :old.sid;
   insert into vgrades_log values( OLD.hw1 || ' : ' || NEW.hw1
		|| ' at ' || to_char( now(), 'YYYY month dd, HH12:MI:SS' ));
END
;
*/

CREATE OR REPLACE VIEW vClassReport AS
   select
	classes.cid, PCTHWK, PCTMid1, PCTMid2, PCTFinal,
	CNAME || '(' || section|| ') ' || initCap(lower(quarter)) ||
	  ' ' || year as ClassName, lastname || ', ' ||  firstName as sname,
	  hw1 + hw2 + hw3 + hw4 + hw5 + hw6 + hw7 + hw8 + hw9 + hw10 + 
	  hw11 + hw12 + hw13 + hw14 + hw15 + hw16 + hw17 + hw18 + hw19 + hw20
	  HW_Total, 
	  grades.sid, mid1, mid2, final, Total, grade, to_char(Total / 10, '999') as RTotal
   from students, grades, classes, Policy
   where students.sid = grades.sid AND grades.cid = classes.cid and
	 classes.cid = policy.cid;
;


CREATE OR REPLACE VIEW vClassTrack  AS
    SELECT
	g.CID,
	g.SID,
	s.lastname,
	s.firstname,
	s.osUserName,
	g.grade,
	m.major,
        g.total
    FROM students s inner join  grades g on ( s.sid = g.sid )
	    left outer join  majors m on ( majorCode = code )
;

CREATE OR REPLACE VIEW vMajors AS
   SELECT Code "Major Code", Major "Long Name", ShortName "Short Name"
   FROM Majors
