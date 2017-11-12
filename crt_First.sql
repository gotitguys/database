-- Create database user, tablespaces and database. Both user and database names are gradebook.
\i crt_user_tspace_db.sql

\! echo	    "\n\n\tUser <store> and Database <store> are created."
\! echo     "\tWARNING: Logout as <postgres> and relogin as <store:> and run <crt_Second.sql> pgsql file.\n"
