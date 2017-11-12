-- 1 created and tested. Use SELECT  getCouseTitle( an-valid-courseID );
CREATE OR REPLACE FUNCTION getCourseTitle ( IN id Integer )
RETURNS VARCHAR AS
$$
DECLARE 

    courseTitle varchar = null;
BEGIN

    SELECT cName || '/' || quarter || '/' || year || '-' || section
    INTO courseTitle FROM classes  WHERE  cid  =  id;
    return courseTitle;
END; 
$$ LANGUAGE plpgsql; 

-- 2 created and tested
CREATE OR REPLACE FUNCTION addStudent(
        IN stuID   Integer,
        IN last    VARCHAR,
        IN first   VARCHAR,
        IN active  CHARACTER,
        IN osUser  VARCHAR,
        IN mjCode  SMALLINT ) RETURNS VOID AS 
$$
BEGIN
	SET Transaction READ WRITE;
        insert into students values(stuID, last, first, active, osUser, mjCode );
EXCEPTION
        WHEN others THEN
	raise 'AddStudemt() failed due to  %', SQLERRM; 
END;
$$ LANGUAGE plpgsql;


-- 3 create and tested with :  select * from getAllGrades( 1 );.
CREATE OR REPLACE FUNCTION getAllGrades( stuID Integer )
 RETURNS VARCHAR AS
$$
DECLARE 
    str     VARCHAR(300);
    fName   VARCHAR(25);
    lName   VARCHAR(20);
    gCursor CURSOR  IS
        SELECT cname || '/' ||  quarter || '/' || year || CHR(9) || grade Grade
        FROM classes natural join  grades where sid = stuID;
BEGIN
    select firstName, lastName into fName, lName from students where SID = stuID;
    str = fName || ' ' ||  lName || ' [' ||  stuID || ']: ' ;

    FOR  c1 IN gCursor LOOP
        str := str || CHR(10) || '  ' || c1.grade;
    END LOOP;
    RETURN(str);
END; 
$$ LANGUAGE plpgsql;

-- 4 Tested wih : select getcourseID(2017, 'Spring', 'CMPS 3390', 1);
CREATE OR REPLACE FUNCTION getCourseID (
   yr IN Integer, term VARCHAR, cr VARCHAR,
   sec  IN Integer)
RETURNS Integer AS  -- must be 'AS' not 'IS'
$$
DECLARE

    cnum integer = -100;
BEGIN
    SELECT CID INTO cnum FROM classes
    WHERE year = yr AND term = substring(upper(quarter), 1, 1) || substring(lower(quarter), 2 )
    AND cName = cr and section = sec  limit 1;
    return cnum;
EXCEPTION
    WHEN OTHERS THEN
    RAISE NOTICE 'In getCourseID( % % % %) : %', cr, term, yr, sec, SQLERRM;
    return -1;
END;
$$ LANGUAGE plpgsql;

-- 5 tested. rankClass is called by calTotatl(cid).
CREATE OR REPLACE FUNCTION rankClass(in ccid int ) RETURNS VOID AS
$$
DECLARE    
   
   stuID int = 0;
   vRank int = 0;
   currentTotal NUMERIC = 0;
   previousTotal NUMERIC = 0 ;
   updateRankCursor CURSOR FOR SELECT sid, Total FROM grades 
	    WHERE  CID = ccid ORDER BY Total DESC;
BEGIN
    OPEN updateRankCursor;
    LOOP
	FETCH updateRankCursor INTO stuID, currentTotal; 
	EXIT WHEN NOT FOUND;
	if  currentTotal <> previousTotal THEN 
	    vRank = vRank + 1; 
	    previousTotal = currentTotal;
	end if;
	UPDATE Grades SET rank  = vRank WHERE SID = stuID AND CID = ccid ;  

    END LOOP ;  
    CLOSE updateRankCursor;
END;
$$ 
LANGUAGE plpgsql;


-- 6 tested with : set total = 0, and rank = 0 for all grades with cid = 3390.
--   use select * from CalTotal ( 3390 );
CREATE OR REPLACE FUNCTION calTotal( ccid INT ) RETURNS void AS
$$

DECLARE 
   -- Variables for saving grading policy data. 
   vNumHWK SMALLINT = 0; vMaxHWK SMALLINT = 0;
   vPCTHWK SMALLINT = 0; vHWKDrops SMALLINT = 0;
   vMaxMid1 SMALLINT =0; vPCTMid1 SMALLINT =0;
   vMaxMid2 SMALLINT =0; vPCTMid2 SMALLINT =0; 
   vMaxFinal SMALLINT; vPCTFinal SMALLINT = 0;

   -- Variables for saving homework grades.
    h1 NUMERIC(5, 2) = 0.0;  h2 NUMERIC(5, 2) = 0.0;  h3 NUMERIC(5, 2) = 0.0; 
    h4 NUMERIC(5, 2) = 0.0;  h5 NUMERIC(5, 2) = 0.0;  h6 NUMERIC(5, 2) = 0.0;  
    h7 NUMERIC(5, 2) = 0.0;  h8 NUMERIC(5, 2) = 0.0;  h9 NUMERIC(5, 2) = 0.0;  h10 NUMERIC(5,2) = 0.0 ;
    h11 NUMERIC(5, 2) = 0;  h12 NUMERIC(5, 2) = 0;  h13 NUMERIC(5, 2) = 0; 
    h14 NUMERIC(5, 2) = 0;  h15 NUMERIC(5, 2) = 0;  h16 NUMERIC(5, 2) = 0;
    h17 NUMERIC(5, 2) = 0;  h18 NUMERIC(5, 2) = 0;  h19 NUMERIC(5, 2) = 0;  h20 NUMERIC(5,2) = 0.0;

   -- variable for saving original and calculated miderms and final 
    calHwkTotal NUMERIC(5, 2) = 0.0;  calMid1 NUMERIC(5, 2) = 0.0; calMid2 NUMERIC(5, 2) = 0.0;
    calFinal NUMERIC(5, 2) = 0.0; calTotal   NUMERIC(5, 2) = 0.0; 
    previousTotal NUMERIC(5, 2) = 0; currentTotal NUMERIC(5, 2) = 0.0;
    stuID INT =0; calRank INT =0; hwkCount INT = 0;

   -- Cursor variable: cursor process status: done, cursors: cUsr, calcTotalCursor and hanlder.

   calcTotalCursor CURSOR FOR SELECT SID, hw1, hw2, hw3, hw4, hw5, hw6, hw7, hw8, hw9, hw10,
		 hw11, hw12, hw13, hw14, hw15, hw16, hw17, hw18, hw19, hw20, mid1, mid2,
		final, total, rank FROM grades WHERE  CID = ccid ;
   sumHWKPointsCursor CURSOR FOR SELECT points  FROM Homework ORDER BY points DESC;

BEGIN
   SELECT  NumHWK, MaxHWK, PCTHWK, HWKDrops, MaxMid1, PCTMid1, MaxMid2, 
	    PCTMid2, MaxFinal, PCTFinal
   INTO    vNumHWK, vMaxHWK, vPCTHWK, vHWKDrops, vMaxMid1, vPCTMid1, vMaxMid2, vPCTMid2, vMaxFinal, vPCTFinal
   FROM Policy WHERE CID = ccid ;

    OPEN calcTotalCursor;
    LOOP  -- Calculate each of students up-t0-date total based homework, tests.

	   FETCH calcTotalCursor INTO stuID, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12,
		h13, h14, h15, h16, h17, h18, h19, h20, calMid1, calMid2, calFinal, calTotal, calRank;

	   EXIT WHEN NOT FOUND ;

	   DELETE FROM homework ;    -- Get one students grades of hwk, midters, and final.
	   insert into Homework values(  h1 ); insert into Homework values ( h2 );
	   insert into Homework values(  h3 ); insert into Homework values( h4 );
	   insert into Homework values(  h5 ); insert into Homework values( h6 );
	   insert into Homework values(  h7 ); insert into Homework values( h8 );
	   insert into Homework values(  h9 ); insert into Homework values( h10 );
	   insert into Homework values( h11 ); insert into Homework values( h12 );
	   insert into Homework values( h13 ); insert into Homework values( h14 );
	   insert into Homework values( h15 ); insert into Homework values( h16 );
	   insert into Homework values( h17 ); insert into Homework values( h18 );
	   insert into Homework values( h19 ); insert into Homework values( h20 );

	-- All 20 homework grades are save into Homework table. Since
	--	1. Actually assigned homework is less than 20 and
	--      2. Some grading policy allow class to drop k lowest grades.
	--  The following get highest point based on numbers of assigned and dropped.

	    calHwkTotal = 0; hwkCount = 0;  -- Calculate homework total -- excluding dropped loweest homemwork.
	    OPEN sumHWKPointsCursor;

	    LOOP
		FETCH sumHWKPointsCursor INTO h1; 
		EXIT WHEN NOT FOUND; 
		EXIT WHEN hwkCount >= ( vNumHWK - vHWKDrops ); 
		calHwkTotal = calHwkTotal + h1;
		hwkCount = hwkCount + 1;
	    END LOOP;     -- end of sumarizing higest undropped homework points.
	
	    CLOSE sumHWKPointsCursor;
	 
        
            If vMaxMid1 > 1.0  AND vPCTMid1 > 1.0 Then calMid1 =  calMid1 / vMaxMid1 ; End if ;
	    If vMaxMid2 > 1.0  AND vPCTMid2 > 1.0 Then calMid2 =  calMid2 / vMaxMid2 ; End if;
            If vMaxFinal > 0 AND vPCTFinal > 0    Then calFinal = calFinal / vMaxFinal ; End if;

            If vMaxFinal = 0.0  AND vPCTFinal > 0 Then -- distribute finalPCT % 
                vPCTHWK  = vPCTHWK+round(vPCTHWK/(vPCTHWK + vPCTMid1 + vPCTMid2)) * vPCTFinal;
                vPCTMid1 = vPCTMid1+round(vPCTMid1/(vPCTHWK + vPCTMid1 + vPCTMid2))*vPCTFinal;
                vPCTMid2 = vPCTMid2+round(vPCTMid2/(vPCTHWK + vPCTMid1 + vPCTMid2))*vPCTFinal;
		vPCTFinal = 0;
            End if;

            If vMaxMid2 = 0 AND vPCTMid2 > 0 Then -- Distribute mid2 % 
                vPCTHWK  = vPCTHWK + round(vPCTHWK/(vPCTHWK + vPCTMid1)) * vPCTMid2;
                vPCTMid1 = vPCTMid1 + round(vPCTMid1/(vPCTHWK + vPCTMid1)) * vPCTMid2;
		vPCTMid2 = 0.0;
            End if;

            If vMaxMid1 = 0 AND vPCTMid1 > 0 Then -- Distribute mid1 PCT % 
                If vMaxMid2 = 0.0 Then
			vPCTHWK = vPCTHWK + vPCTMid1 ;
		Else	
                        vPCTHWK = vPCTHWK + round(vPCTHWK/(vPCTHWK + vPCTMid2)) * vPCTMid1;
                        vPCTMid2 = vPCTMid2 +round(vPCTMid2/(vPCTHWK + vPCTMid2)) * vPCTMid1;
		End if;
		vPCTMid1 = 0;
            End if;
	    currentTotal = calHwkTotal/hwkCount * vNumHWK * vPCTHWK / vMaxHwk + calMid1 * vPCTMid1
					    + calMid2 * vPCTMid2 + calFinal * vPCTFinal;
            UPDATE Grades SET Total = currentTotal WHERE SID = stuID AND CID = ccid; 
        
    END LOOP ;        -- End of calculating total points of each studen and new total is saved

    CLOSE calcTotalCursor;
    execute rankClass( ccid );
END;
$$ LANGUAGE plpgsql;

-- 7 Tested with select from changeIDTo(1, 10); the student's 
--    and the correspoing ID of grades are changed.
-- Change Student ID
CREATE OR REPLACE FUNCTION changeIDTo( oldID Integer, newID Integer ) RETURNS VOID AS
$$
BEGIN
   -- Useing table foreikey constraints with "ON UPDATE CASCADE" in grades table declaration.
   -- only one line of code is necessary.
   
   UPDATE students set SID = newID where SID = oldID;
EXCEPTION
    WHEN others THEN
    raise 'Changing  Student [Id] from % [to]  [%], failed due to  [%]', OldID, newID, SQLERRM;
END;
$$ LANGUAGE plpgsql;


-- 8 created and tested with select from changeCIDTo(3390, 342)
-- the class ID and corresponding cid of grades are changed.
-- Chage class ID from old number to new member.
CREATE OR REPLACE FUNCTION changeCIDTo( oldCID Integer, newCID integer ) RETURNS VOID AS
$$
BEGIN
    update classes set CID = newCID where CID = oldCID;
EXCEPTION
    WHEN others THEN
    RAISE 'Changing class ID from s[%] to [%] failed due to [%]', oldCID, newCID,  SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 9 Delete a givenstudent grades records of a given same class, 
-- the student record is not deleted.
-- Tested with select deleteStudentFrom (1, 394);
CREATE OR REPLACE FUNCTION deleteStudentFromClass (
	stuID	Integer, classID Integer ) RETURNS VOID AS
$$
BEGIN
    delete from grades where SID  = stuID AND CID = classID;
EXCEPTION 
    WHEN others THEN
    RAISE 'Removing student % from class %  failed due to: %', stuID, classID, SQLERRM ;
	
END;
$$ LANGUAGE plpgsql;

-- 10 Add a new class into classes table
-- Tested with select from addClass(342, 1131, 2017, 'Fall', 'CMPS 3420', 1::smallint)
CREATE OR REPLACE FUNCTION addClass(
        classID         Integer,
        instID          Integer,
        yr              Integer,
        qtr             in VARCHAR,
        className       in VARCHAR,
        section         Integer) RETURNS VOID AS
$$
BEGIN
    insert into classes     values(classID, instID, yr, qtr, className, section);
    insert into policy(CID) values( classID );
EXCEPTION
    WHEN others THEN
    RAISE 'Adding new class -%/%/%-% failed due to [%]', classID, yr, qtr, section,  SQLERRM ;
END;
$$ LANGUAGE plpgsql;

-- 11 remove all grades with of given class. Students records remain untouched.
-- Tested with select * from removeclassroster(394); succesfully.
CREATE OR REPLACE FUNCTION removeClassRoster( courseID Integer ) RETURNS VOID  AS
$$
BEGIN
    delete from grades where cid = courseID;
EXCEPTION
    WHEN others THEN
    RAISE 'Remove all students from class %-%/%/%-% due to  %', classID, className, yr, qtr, section,  SQLERRM ;
END;
$$ LANGUAGE plpgsql;

-- 12 Enroll an existing student into a existing class. A grade record is created.
-- Tested with 
CREATE OR REPLACE FUNCTION addStudentToClass (
	stuID	Integer,
	classID	Integer ) RETURNS VOID  AS
$$
BEGIN
	insert into grades (SID, CID) values ( stuID,  classID ) ;

EXCEPTION
	WHEN others THEN 
	RAISE 'Adding Stuent % to class % failed due to %', stuID, classID, SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 13 Rmeove a student from database, and all correspoing grades. The instructor ID is
-- not used. Test successfully with gradebook=# select * from deleteStudent( 1, 1131 );
CREATE OR REPLACE FUNCTION deleteStudent ( stuID Integer, instID Integer ) RETURNS VOID AS
$$
DECLARE 
	classCount Integer ;
BEGIN
	delete FROM students where SID = stuID;
EXCEPTION
	WHEN others THEN
	RAISE 'Removing Stuent [%] and grades from class[%] failed due to %', stuID, classID, SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 14 Move a class and all grades associated with the class. The students information enrolled in class
-- is nove removed.
-- Tested with  select [*] from deleteClass(3390, 1131 ); 
CREATE OR REPLACE FUNCTION deleteClass(
	classID		Integer,
	instID		Integer ) RETURNS VOID AS
$$
BEGIN
	delete from classes where cid = classID ;
EXCEPTION
	WHEN others THEN
	RAISE 'Deleting class [%] failed  due to % ', classID,  SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 15 This program is used to update one of twenty homework grads in case of 
--	1. DBMS dosen't allow change grades through vgrades and
--	2. DBMS does support INSTEAD OF trigger.
--  So far, the following are tested:
--	1. Oracle DBM allow to  upate grades throguth view. Therefore updatesHomwqoek is not needed.
--	2. MySQL community version doesn't support updable view even its document says yes.
--		mysql doen't support INSTEAD OF trigger. Therefore, updateHomework is necessary.
--	3. Postgres support INStEAD OF, and I will test whether updatable view is supported or not.
-- Tested successfully with select * from updateHomework( 3390, 1, 3,  5);
 
CREATE OR REPLACE FUNCTION updateHomework(
	classID		Integer,
	studentID	Integer,
	hwkNo		Integer,
	newScore	Numeric ) RETURNS VOID AS
$$
BEGIN
    IF (hwkNo = 1) THEN
	update grades set hw1 = newScore where CID = classID and SID = studentID;
	ELSIF ( hwkNo =  2 ) THEN update grades set hw2 = newScore where CID = classID and SID = studentID;
	ELSIF ( hwkNo =  3 ) THEN update grades set hw2 = newScore where CID = classID and SID = studentID;
	ELSIF ( hwkNo =  4 ) THEN update grades set hw4 = newScore where CID = classID and SID = studentID;
	ELSIF ( hwkNo =  5 ) THEN update grades set hw5 = newScore where CID = classID and SID = studentID;
	ELSIF ( hwkNo =  6 ) THEN update grades set hw6 = newScore where CID = classID and SID = studentID;
	ELSIF ( hwkNo =  7 ) THEN update grades set hw7 = newScore where CID = classID and SID = studentID;
	ELSIF ( hwkNo =  8 ) THEN update grades set hw8 = newScore where CID = classID and SID = studentID;
	ELSIF ( hwkNo =  9 ) THEN update grades set hw9 = newScore where CID = classID and SID = studentID;
	ELSIF ( hwkNo =  10 ) THEN update grades set hw10 = newScore where CID = classID and SID = studentID;
	ELSIF ( hwkNo =  11 ) THEN update grades set hw11 = newScore where CID = classID and SID = studentID;
	ELSIF ( hwkNo =  12 ) THEN update grades set hw12 = newScore where CID = classID and SID = studentID;
	ELSIF ( hwkNo =  13 ) THEN update grades set hw13 = newScore where CID = classID and SID = studentID;
	ELSIF ( hwkNo =  14 ) THEN update grades set hw14 = newScore where CID = classID and SID = studentID;
	ELSIF ( hwkNo =  15 ) THEN update grades set hw15 = newScore where CID = classID and SID = studentID;
	ELSIF ( hwkNo =  16 ) THEN update grades set hw16 = newScore where CID = classID and SID = studentID;
	ELSIF ( hwkNo =  17 ) THEN update grades set hw17 = newScore where CID = classID and SID = studentID;
	ELSIF ( hwkNo =  18 ) THEN update grades set hw18 = newScore where CID = classID and SID = studentID;
	ELSIF ( hwkNo =  19 ) THEN update grades set hw19 = newScore where CID = classID and SID = studentID;
	ELSIF ( hwkNo =  20 ) THEN update grades set hw20 = newScore where CID = classID and SID = studentID;
    END IF;
EXCEPTION
    WHEN others THEN
    RAISE 'Updating student[%] class[%] grade[%] failed due to [%]', studentID,  classID, hwkNo,  SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 16 Each class has upto 2 mid.The function is to change grade of mid 1 or 2.
-- Testd with select * from updateMid( 3390, 1, 2, 78) that changed mid2 of student 1 for class 3390.
CREATE OR REPLACE FUNCTION updateMid (
	classID		Integer,
	studentID	Integer,
	MidNo	Integer,
	newScore	Numeric ) RETURNS VOID AS
$$
BEGIN
    IF    ( MidNo = 1  ) THEN    update grades set mid1 = newScore where CID = classID and SID = studentID;
    ELSIF ( MidNo =  2 ) THEN    update grades set mid2 = newScore where CID = classID and SID = studentID;
    END IF;
EXCEPTION
    WHEN others THEN
    RAISE 'Updating student[%] class[%] mid-% grade  failed due to [%]', studentID,  classID, midNo,  SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 17 Each class has one final exam..The function is to change grade of one student's specified class..
-- Testd with select * from updateMid( 3390, 1, 2, 87) that changed mid2 of student 1 for class 3390.
CREATE OR REPLACE FUNCTION updateFinal(
	classID		Integer,
	studentID	Integer,
	newScore	Numeric ) RETURNS VOID AS
$$
BEGIN
    update grades set final = newScore where CID = classID and SID = studentID;
EXCEPTION
    WHEN others THEN
    RAISE 'Updating student[%] class[%] final exam grade  failed due to [%]', studentID,  classID,  SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 18 The function change the letter grade of a Student.
--    Tesed successfully with select * from updateGrade( 3390, 1,'B+');   
CREATE OR REPLACE FUNCTION updateGrade(
	classID		Integer,
	studentID	Integer,
	newGrade	in VARCHAR ) RETURNS VOID AS
$$
BEGIN
    update grades set grade = newGrade where CID = classID and SID = studentID;
EXCEPTION
    WHEN others THEN
    RAISE 'Updating student[%] class[%] letter grade failed due to [%]', studentID,  classID,  SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Notice that the un-purged dropped table will cause the dynamic sql
-- in getRecordCount executed unsuccessfully.


-- 19 The function retrieve number of records of all tables in gradebook database. The function needs to two DBMS
-- supports 
--	1. Dynamic sql execution, and 
--	2. Get row count, or support select count(*) into rowcount.
--  Oracl and mysql support both and can implement the his function woriking correctly regardless of number of classes
--  changes.
--  Unfortuanally, the second support is missing from postgresSQL.
--  There are couple of ways of get total of records:
--	1.  Non-flexible: select count(*) from each of existing class -- not good and not flexible.
--	2.  Reuturn all table name to client, and let client program to use select count(*) into cnt from table.
-- total row number if umber of tables of gradebook changes

-- CREATE OR REPLACE FUNCTION getRecordCount()  RETURNS Integer  AS
-- $$
-- DECLARE
--    cnt Integer  	:= 0;
--    total Integer        := 0;
--    tblName VARCHAR 	= '';
   -- tabCur CURSOR IS  select tablename from pg_tables  where tableowner = 'gradebook';
-- BEGIN
--   open tabCUr;
--   loop
--	FETCH tabCur into tblName; 
--	EXIT WHEN NOT FOUND;
--       EXECUTE ('select count(*) INTO cnt from ' || tblName) ;
--        total := total + cnt;
--   end loop;
--   return (total) ;
--EXCEPTION
--    WHEN others THEN
--    RAISE 'Getting total number of records of tables failed due to [%]', SQLERRM;
--    return 0;
--end;
--$$ LANGUAGE plpgsql;

-- An temporary not-good solutions, When tables are added or removed the progrm will not work.
CREATE OR REPLACE FUNCTION getRecordCount()  RETURNS Integer  AS
$$
DECLARE
    cnt Integer       := 0;
      total Integer        := 0;
BEGIN
     select count(*) into cnt from classes; total = total + cnt;
     select count(*) into cnt from grades ; total = total + cnt;
     select count(*) into cnt from homework; total = total + cnt;
     select count(*) into cnt from instructors; total = total + cnt;
     select count(*) into cnt from majors; total = total + cnt;
     select count(*) into cnt from policy; total = total + cnt;
     select count(*) into cnt from students; total = total + cnt;
     select count(*) into cnt from vgrades_log; total = total + cnt;
     return total ;
EXCEPTION
     WHEN others THEN
     RAISE 'Getting total number of records of tables failed due to [%]', SQLERRM;
     return total;
end;
$$ LANGUAGE plpgsql;

-- 20 The function return a string of all table names separated by ';'.
-- Testd with select getalltablenames();
CREATE OR REPLACE FUNCTION getALLTableNames()  RETURNS VARCHAR AS
$$
DECLARE
   cnt Integer  := 0;
   total Integer        := 0;
   tblName VARCHAR = '';
   str VARCHAR = '';
   tabCur CURSOR IS  select tablename from pg_tables  where tableowner = 'gradebook';
BEGIN
   open tabCUr;
   loop
	FETCH tabCur into tblName; 
   	EXIT WHEN NOT FOUND;
	str = str || tblName  || '; ' ;
   end loop;
   return (str) ;
EXCEPTION
    WHEN others THEN
    RAISE 'Getting total number of records of tables failed due to [%]', SQLERRM;

end;
$$ LANGUAGE plpgsql;


-- 21 Randomly exchange IDs of students. 
-- Tested successfully with SELECT randomizeID(); 
create Function randomizeSID () RETURNS int AS
$$

DECLARE 
    oldID int;
    newID double precision;
    count int = 0;
    cur cursor IS select sid  from students;
BEGIN
    OPEN cur;
    LOOP
	FETCH cur INTO oldID;
	EXIT WHEN NOT FOUND;
	newID = round( oldID * random() * (random() + 1.433223294) ) ; 
	newID = MOD (newID, 1000000000);
	execute changeIDTo(oldID, newID);
	count = count + 1;
    END LOOP ;
    CLOSE cur;
    return count;
EXCEPTION
    WHEN others THEN
    return count;
END;
$$ LANGUAGE plpgsql;

-- 22 Randomly exchange names of students. 
-- Tested successfully with SELECT randomizeNams ();
create function randomizeNames ( ) returns int AS
$$

DECLARE 

    count int = 0;
    sid1 int;
    fN1	    varchar(25); 
    fN2	    varchar(25); 
    lN1	    varchar(25); 
    lN2	    varchar(25); 
    cur1 cursor IS select sid, firstName, lastName from students order by SID DESC;
    cur2 cursor IS select firstName from students order by SID;
    cur3 cursor IS select lastName from students order by lastName, SID;

BEGIN
    open cur1;
    open cur2;
    open cur3;
    LOOP
	FETCH cur1 INTO sid1, fN1, lN1;
	EXIT WHEN NOT FOUND;
	FETCH cur2 INTO fN2;
	EXIT WHEN NOT FOUND;
	FETCH cur3 INTO lN2;
	EXIT WHEN NOT FOUND;
	-- update students set firstName = fN2 where current of cur1;
	update students set firstName = fN2, lastName = lN2 where sid = sid1 ;
	count = count + 1;
    end loop;

    close cur1;
    close cur2;
    close cur3;
    return count;
EXCEPTION 
    WHEN others THEN
    return count;
END;
$$ LANGUAGE plpgsql ;
