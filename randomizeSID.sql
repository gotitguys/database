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
