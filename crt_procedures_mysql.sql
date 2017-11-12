DELIMITER $$
drop procedure if exists addStudent;  
CREATE PROCEDURE addStudent (
	stuID	INT,
	last	varchar(20),
	first	varchar(25),
	active	varchar(1),
	osUser	varchar(15),
	mjCode	smallint)
BEGIN
	set transaction read write;
	insert into students values(stuID, last, first, active, osUser, mjCode );
	commit;
END ;

drop function if exists getAllGrades;
CREATE FUNCTION getAllGrades( stuID INT )   
RETURNS VARCHAR(300)
BEGIN

     -- Declare local varables for catching data from database.
    declare str	    VARCHAR(300); 
    declare fName   VARCHAR(25);
    declare lName   VARCHAR(20);
    declare cnm	    VARCHAR(10);
    declare qtr	    VARCHAR(8);
    declare grd	    VARCHAR(2);
    declare yr	    smallInt;

   -- declare cursor, its handler and related variable. The order of 3 things is important   

    DECLARE done INT DEFAULT FALSE;
    DECLARE gCursor CURSOR FOR  SELECT cname,  quarter,  year,  grade 
        		FROM gradebook.classes natural join  gradebook.grades where sid = stuID;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    select firstName, lastName into fName, lName from students where SID = stuID;
    set str = CONCAT(fName, ' ',  lName, ' [',  stuID, ']: ') ;

    OPEN gCursor;
    get_grades: LOOP 

	FETCH gCursor INTO cnm, qtr, yr, grd; 
	IF done THEN
		LEAVE get_grades; 
	END IF;
	set str = CONCAT(str, '\n  ', cnm, '/', qtr, '/', yr, '\t', grd);
    END LOOP;
    
    CLOSE gCursor;

    RETURN str;
END ;


drop function if exists getCourseID;
CREATE FUNCTION getCourseID ( yr smallint, term VARCHAR(8), cr VARCHAR(10), sec  TINYINT )
		RETURNS INT 
BEGIN
    
    declare classID INT default -1;
    SELECT CID INTO classID FROM classes 
    WHERE year = yr AND quarter like term AND cName like cr and section = sec limit 1;
    return classID;
END;

-- Notice that the un-purged dropped table will cause the dynamic sql
-- in getRecordCount executed unsuccessfully.
drop function if exists getRecordCount;
CREATE FUNCTION getRecordCount()  returns INT 

BEGIN
   declare cnt, total INT default -5;
   declare tName varchar(25);
   declare done INT default FALSE;
   declare totalCur CURSOR FOR SELECT SUM(TABLE_ROWS) FROM INFORMATION_SCHEMA.TABLES 
		WHERE table_schema = DataBase() and table_type like 'Base Table';

   declare CONTINUE HANDLER FOR NOT FOUND set done = TRUE;

   OPEN totalCur;
   calTotal_loop : LOOP
      FETCH  totalCur INTO total;
      IF done THEN LEAVE calTotal_loop; END IF;
   END LOOP;
   CLOSE totalCUr;

   return total;                                                                                                        
end;

DROP   FUNCTION IF EXISTS getCourseTitle;
CREATE FUNCTION getCourseTitle ( id INT ) RETURNS VARCHAR(30) 
BEGIN

    DECLARE cTitle VARCHAR(30) default 'cmps3390'; 

    SELECT  CONCAT (cName, '/', quarter, '/', year, '-', section)
    INTO cTitle FROM classes  WHERE cid = id;

    RETURN cTitle;
END ;

drop procedure if exists rankClass;
CREATE PROCEDURE rankClass(in  ccid int) 
BEGIN
   
   declare stuID, rank int;
   declare currentTotal, previousTotal double default 0 ;
   DECLARE done INT DEFAULT FALSE; 
   declare updateRankCursor CURSOR FOR SELECT sid, Total FROM grades 
	    WHERE  CID = ccid ORDER BY Total DESC;
   DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN updateRankCursor;
    SET rank = 0;

    updateRank_loop :  LOOP

	FETCH updateRankCursor INTO stuID, currentTotal; 
	if done THEN LEAVE updateRank_loop; END IF ;
	if  currentTotal <> previousTotal THEN 
	    SET rank = rank + 1; 
	    SET previousTotal = currentTotal;
	end if;
	UPDATE Grades SET Ranking  = rank WHERE SID = stuID AND CID = ccid ;  

    END LOOP ;  
    CLOSE updateRankCursor;
    Commit;
END ;

drop procedure if exists calTotal;
CREATE PROCEDURE calTotal( ccid INT )
BEGIN

   -- Variables for saving grading policy data. 
   declare vNumHWK, vMaxHWK, vPCTHWK, vHWKDrops TINYINT default 0;
   declare vMaxMid1, vPCTMid1, vMaxMid2, vPCTMid2, vMaxFinal, vPCTFinal TINYINT default 0;

   -- Variables for saving homework grades.
   declare  h1, h2, h3, h4, h5, h6, h7, h8, h9, h10 DOUBLE(5,2) default 0.0 ;
   declare  h11, h12, h13, h14, h15, h16, h17, h18, h19, h20 DOUBLE(5,2) default 0.0;

   -- variable for saving original and calculated miderms and final 
   declare  calHwkTotal, calMid1, calMid2, calFinal, calTotal   DOUBLE(5, 2) default 0.0;
   declare  previousTotal, currentTotal DOUBLE(5, 2) default 0.0;
   declare  stuID, calRank, hwkCount INT default 0;

   -- Cursor variable: cursor process status: done, cursors: cUsr, calcTotalCursor and hanlder.
   DECLARE done INT DEFAULT FALSE; 

   declare calcTotalCursor CURSOR FOR SELECT SID, hw1, hw2, hw3, hw4, hw5, hw6, hw7, hw8, hw9, hw10,
		 hw11, hw12, hw13, hw14, hw15, hw16, hw17, hw18, hw19, hw20, midterm1, midterm2,
		final, total, ranking FROM grades WHERE  CID = ccid ;
   
   declare sumHWKPointsCursor CURSOR FOR SELECT points  FROM Homework ORDER BY points DESC;

   DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

	SELECT  NumHWK, MaxHWK, PCTHWK, HWKDrops, MaxMidterm1, PCTMidterm1, MaxMidterm2, PCTMidterm2,
               MaxFinal, PCTFinal
	INTO    vNumHWK, vMaxHWK, vPCTHWK, vHWKDrops, vMaxMid1, vPCTMid1, vMaxMid2, vPCTMid2, vMaxFinal, vPCTFinal
    	FROM Policy WHERE CID = ccid ;

    OPEN calcTotalCursor;
    calcTotal_loop : LOOP  -- Calculate each of students up-t0-date total based homework, tests.

	   FETCH calcTotalCursor INTO stuID, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12,
		h13, h14, h15, h16, h17, h18, h19, h20, calMid1, calMid2, calFinal, calTotal, calRank;

           IF done THEN LEAVE calcTotal_loop; END IF;  -- all students' total grades are done.

	   DELETE QUICK FROM homework ;    -- Get one students grades of hwk, midters, and final.
	   insert into Homework value(  h1 ); insert into Homework value( h2 );
	   insert into Homework value(  h3 ); insert into Homework value( h4 );
	   insert into Homework value(  h5 ); insert into Homework value( h6 );
	   insert into Homework value(  h7 ); insert into Homework value( h8 );
	   insert into Homework value(  h9 ); insert into Homework value( h10 );
	   insert into Homework value( h11 ); insert into Homework value( h12 );
	   insert into Homework value( h13 ); insert into Homework value( h14 );
	   insert into Homework value( h15 ); insert into Homework value( h16 );
	   insert into Homework value( h17 ); insert into Homework value( h18 );
	   insert into Homework value( h19 ); insert into Homework value( h20 );

	-- All 20 homework grades are save into Homework table. Since
	--	1. Actually assigned homework is less than 20 and
	--      2. Some grading policy allow class to drop k lowest grades.
	--  The following get highest point based on numbers of assigned and dropped.

	   SET calHwkTotal = 0; SET hwkCount = 0;  -- Calculate homework total 
						-- xcluding dropped loweest homemwork.
	
	    OPEN sumHWKPointsCursor;

	    sumHWKPoints_loop: LOOP

	       FETCH sumHWKPointsCursor INTO h1;
	      
	       IF done THEN LEAVE sumHWKPoints_loop;   END IF; 

	       IF hwkCount >= ( vNumHWK - vHWKDrops ) Then LEAVE sumHWKPoints_loop; END IF;

	       SET calHwkTotal = calHwkTotal + h1;
	       SEt hwkCount = hwkCount + 1; 
	    END LOOP;     -- end of sumarizing higest undropped homework points.
	
	    CLOSE sumHWKPointsCursor;
	 
	    SET done = FALSE;
        
            If vMaxMid1 > 1.0  AND vPCTMid1 > 1.0 Then set calMid1 =  calMid1 / vMaxMid1 ; End if ;
	    If vMaxMid2 > 1.0  AND vPCTMid2 > 1.0 Then set calMid2 =  calMid2 / vMaxMid2 ; End if;
            If vMaxFinal > 0 AND vPCTFinal > 0 Then set calFinal = calFinal / vMaxFinal ; End if;

            If vMaxFinal = 0.0  AND vPCTFinal > 0 Then -- distribute finalPCT % 
                set vPCTHWK  = vPCTHWK+round(vPCTHWK/(vPCTHWK + vPCTMid1 + vPCTMid2)) * vPCTFinal;
                set vPCTMid1 = vPCTMid1+round(vPCTMid1/(vPCTHWK + vPCTMid1 + vPCTMid2))*vPCTFinal;
                set vPCTMid2 = vPCTMid2+round(vPCTMid2/(vPCTHWK + vPCTMid1 + vPCTMid2))*vPCTFinal;
		set vPCTFinal = 0;
            End if;

            If vMaxMid2 = 0 AND vPCTMid2 > 0 Then -- Distribute mid2 % 
                SET vPCTHWK  = vPCTHWK + round(vPCTHWK/(vPCTHWK + vPCTMid1)) * vPCTMid2;
                SET vPCTMid1 = vPCTMid1 + round(vPCTMid1/(vPCTHWK + vPCTMid1)) * vPCTMid2;
		SET vPCTMid2 = 0.0;
            End if;

            If vMaxMid1 = 0 AND vPCTMid1 > 0 Then -- Distribute mid1 PCT % 
                If vMaxMid2 = 0.0 Then
			SET vPCTHWK = vPCTHWK + vPCTMid1 ;
		Else	
                        SET vPCTHWK = vPCTHWK + round(vPCTHWK/(vPCTHWK + vPCTMid2)) * vPCTMid1;
                        SET vPCTMid2 = vPCTMid2 +round(vPCTMid2/(vPCTHWK + vPCTMid2)) * vPCTMid1;
		End if;
		SET vPCTMid1 = 0;
            End if;
	    set currentTotal = calHwkTotal / hwkCount * vNumHWK * vPCTHWK / vMaxHwk + calMid1 * vPCTMid1
					    + calMid2 * vPCTMid2 + calFinal * vPCTFinal;
            UPDATE Grades SET Total = currentTotal WHERE SID = stuID AND CID = ccid; 
        
    END LOOP ;        -- End of calculating total points of each studen and new total is saved

    CLOSE calcTotalCursor;
    commit;
    call rankClass( ccid );
END;

drop procedure if exists changeIDTo ;
CREATE PROCEDURE changeIDTo(in  oldID int, in newID int) 
BEGIN
    
    declare lName varchar(20) default 'wang'; 
    declare fName varchar(25) default 'Huaqing';
    declare act	  char(1)     default 'Y';
    declare osname varchar(15) default 'hwang';
    declare mcode smallint(6) default -1;
    declare cnt   int	      default 0;
 
    SELECT LastName, FirstName, ACTIVE, OSUserName, MajorCode
    INTO   lName, fName, act, osname, mcode 
    FROM Students
    WHERE SID = oldID;
   
--    if  ROW_FOUND() = 1  then
	set transaction read write;
	insert into students values (newID, lName, fName, act, osname, mcode);
	update grades set SID = newID where SID =oldID;
	delete from students where SID = oldID;
	commit;
--    end if;
END;

-- Change course ID or course number in CSUB.
drop procedure if exists changeCIDTo;
CREATE PROCEDURE changeCIDTo(in oldCID INT, in newCID INT)
BEGIN
    declare oriIID	INT ;
    declare oriYear 	smallint ;
    declare oriQtr	varchar(8);
    declare oriCName	varchar(10);
    declare oriSec	tinyint;
 
    select IID, Year, quarter, cname, section
    INTO   oriIID, oriYear, oriQtr, oriCName, oriSec
    FROM Classes 
    WHERE CID = oldCID;
  
    if  ROW_FOUND() = 1  then
	set transaction read write;
	insert into classes values (newCID, oriIID, oriYear, oriQtr, oriCName, oriSec);
	update grades set CID = newCID where CID = oldCID;
	update policy set CID = newCID where CID = oldCID;
	delete from classes where CID = oldCID;
	commit;
    end if;
END;
 
drop procedure if exists deleteStudentFromClass;

CREATE PROCEDURE         deleteStudentFromClass ( in stuID INT, in classID INT ) 
BEGIN

    declare cnt INT default 0;
   
    select count(*) into cnt from grades where SID = stuID and CID = classID;
    delete from grades where SID  = stuID AND CID = classID; 
    
    if cnt = 1 then
	commit;
    else
	rollback;
    end if;

END ;

drop procedure if  exists addClass;
CREATE PROCEDURE addClass(		
	classID  	INT,
	instID		INT,
	yr		smallint,
	qtr		varchar(8),
	className	varchar(10),
	section		tinyint)
BEGIN
	set transaction read write;
	insert into classes     values(classID, instID, yr, qtr, className, section);
	insert into policy(CID) values( classID );
	commit;
END ;


drop procedure if exists addStudentToClass;
CREATE PROCEDURE addStudentToClass ( stuID INT, classID	INT )   
BEGIN
	insert into grades (SID, CID) values ( stuID,  classID ) ;
	commit;
END ;

drop procedure if exists deleteStudent;
CREATE PROCEDURE deleteStudent ( stuID INT, instID INT)  
BEGIN

    declare  classCount int default 0; 

    delete from grades where SID = stuID AND exists (
	select c.cid from classes  where classes.cid = grades.cid and classes.iid = instID );
    
    select count(*) into classCount from grades where sid = stuID; 
    
    if ( classCount = 0 ) THEN
	delete from students where SID = stuID;
	commit;	
    end if;

END ;


drop PROCEDURE IF EXISTS removeClassRoster;
CREATE PROCEDURE removeClassRoster( courseID INT  )
BEGIN
    delete from grades where cid = courseID;
    commit;
END;

drop procedure if exists deleteClass;
CREATE PROCEDURE deleteClass( classID INT, instID INT)   
BEGIN

	delete from grades  where CID = classID AND exists (
		select cid from classes  where classes.cid = grades.cid and classes.iid = instID );

	delete from policy where CID = classID;
	
	delete from classes where CID = classID AND IID = instID;
	commit;
END ;


drop procedure if exists updateHomework;   
CREATE PROCEDURE updateHomework (			
	classID		INT,
	studentID	INT,
	hwkNo		INT,
	newScore	INT )
BEGIN
    
    CASE 
	WHEN  1 THEN update grades set hw1 = newScore where CID = classID and SID = studentID;
	WHEN  2 THEN update grades set hw2 = newScore where CID = classID and SID = studentID;
	WHEN  3 THEN update grades set hw2 = newScore where CID = classID and SID = studentID;
	WHEN  4 THEN update grades set hw4 = newScore where CID = classID and SID = studentID;
	WHEN  5 THEN update grades set hw5 = newScore where CID = classID and SID = studentID;
	WHEN  6 THEN update grades set hw6 = newScore where CID = classID and SID = studentID;
	WHEN  7 THEN update grades set hw7 = newScore where CID = classID and SID = studentID;
	WHEN  8 THEN update grades set hw8 = newScore where CID = classID and SID = studentID;
	WHEN  9 THEN update grades set hw9 = newScore where CID = classID and SID = studentID;
	WHEN  10 THEN update grades set hw10 = newScore where CID = classID and SID = studentID;
	WHEN  11 THEN update grades set hw11 = newScore where CID = classID and SID = studentID;
	WHEN  12 THEN update grades set hw12 = newScore where CID = classID and SID = studentID;
	WHEN  13 THEN update grades set hw13 = newScore where CID = classID and SID = studentID;
	WHEN  14 THEN update grades set hw14 = newScore where CID = classID and SID = studentID;
	WHEN  15 THEN update grades set hw15 = newScore where CID = classID and SID = studentID;
	WHEN  16 THEN update grades set hw16 = newScore where CID = classID and SID = studentID;
	WHEN  17 THEN update grades set hw17 = newScore where CID = classID and SID = studentID;
	WHEN  18 THEN update grades set hw18 = newScore where CID = classID and SID = studentID;
	WHEN  19 THEN update grades set hw19 = newScore where CID = classID and SID = studentID;
	WHEN  20 THEN update grades set hw20 = newScore where CID = classID and SID = studentID;
    END CASE ;
    
    IF ( ROW_COUNT() ) THEN commit;
    ELSE		  rollback;
    END IF;
       rollback;
END ;

drop procedure if exists updateMidterm;
CREATE PROCEDURE updateMidterm (	    
	classID		INT,
	studentID	INT,
	MidtermNo	INT,
	newScore	INT )
BEGIN

    IF    ( MidtermNo = 1  ) THEN
	update grades set midterm1 = newScore where CID = classID and SID = studentID;
    ELSE 
	update grades set Midterm2 = newScore where CID = classID and SID = studentID;
    END IF;
    IF ( ROW_COUNT() = 1 ) THEN commit;
    ELSE		        rollback;
    END IF;
END ;

drop procedure if exists updateFinal;
CREATE PROCEDURE updateFinal(
	classID		INT,
	studentID	INT,
	newScore	INT )
BEGIN
    update grades set final = newScore where CID = classID and SID = studentID;
    IF ( ROW_COUNT() = 1 ) THEN commit;
    ELSE			  rollback;
    END IF;
END ;


drop procedure if exists updateGrade;
CREATE PROCEDURE updateGrade(
	classID		INT,
	studentID	INT,
	newGrade	varchar(2) )
BEGIN
    update grades set grade = newGrade where CID = classID and SID = studentID;
    IF (ROW_COUNT() = 1 ) THEN
        commit;
    END IF;
END ;

$$
DELIMITER ;
