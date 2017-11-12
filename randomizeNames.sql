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
