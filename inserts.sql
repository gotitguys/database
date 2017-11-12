insert into instructors values (1131, 'hwang', '1234', 'ftp');

insert into majors values (1::smallint, 'Computer Science', 'CMPS');

insert into classes values ( 3390, 1131, 2017, 'Spring', 'CMPS 3390', 1::smallint);
insert into policy values ( 3390, 10, 100, 100, 0, 0, 0, 0, 0, 0, 0 );

insert into students values(1, 'Doe', 'John', 'Y', 'jdoe', 1::smallint);
insert into students values(2, 'Smith', 'Rob', 'Y', 'rsmith', 1::smallint);


insert into grades values (1, 3390,
		    10, 10, 10, 10, 10, 10, 10, 10, 5, 5,
		    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		    0, 0, 0, 90, 
		    '-', 0, 'well done.');
insert into grades values (2, 3390,
		    5, 5, 5, 5, 5, 5, 5, 5, 2, 3,
		    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		    0, 0, 0, 45, 
		    '-', 0, 'Work harder.');
