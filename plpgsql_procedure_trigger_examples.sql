CREATE OR REPLACE FUNCTION f_insert_book(_book book, _authors integer[])
   RETURNS void AS 
$func$
BEGIN
    WITH y AS (
        INSERT INTO book b
        SELECT (_book).*
        RETURNING b.book_id
        )
    INSERT INTO author_book (book_id, author_id)
    SELECT y.book_id, unnest(_authors)
    FROM   y;
END
$func$ LANGUAGE plpgsql;

REATE OR REPLACE FUNCTION f_insert_book(_book json, _authors json)
   RETURNS void AS 
$$
BEGIN
-- insert book into table books
Insert into books values select * from json_populate_recordset(null:book, _book);
    -- for each author add an entry to author_books table
Insert into authors values select * from json_populate_recordset(null:authors, _authors);
end;
$$ language plpgsql;

create trigger calc_trigger 
   before insert or update on X
   for each row
   execute procedure update_calc_column();

create or replace function update_calc_column()
  returns trigger
as
$$
begin
  new.x3 := new.x1 + new.x2;
  return new;
end;
$$
language plpgsql;


