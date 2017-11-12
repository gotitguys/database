CREATE OR REPLACE FUNCTION getCourseID (
   yr IN NUMBER, term IN VARCHAR2, cr IN VARCHAR2,
   sec  IN NUMBER ) 
RETURN NUMBER
IS
    cid NUMBER;
    cursor c IS 
        SELECT CID FROM classes
	WHERE year = yr AND quarter = term AND cName = cr and section = sec;
BEGIN
    open c;
    fetch c into cid;
    if c%notfound then
	cid := -1;
    end if;
    close c;
    return cid;
EXCEPTION
    WHEN OTHERS THEN 
    raise_application_error(-9999, 'An error occured in getCourseID - '
        || SQLCODE || '-ERROR- ' || SQLERRM);
END;
/
