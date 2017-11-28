/* When the user Gradebook is created, the default TABLESPACE is
   defined. Therefore no tablespace specification is necessary
   when the tables are created in Gradebook account.
*/

\c store;

-- sequence number type can be replaced by SERIAL or BIGSERIAL type
CREATE SEQUENCE IF NOT EXISTS seqClassID
	INCREMENT BY 1
        START WITH   2000 NO CYCLE
;

CREATE TABLE IF NOT EXISTS Orders (
        Order_num     SERIAL NOT NULL,
        Datee         date NOT NULL,
        Time          time NOT NULL,
        Tax_rate      double precision  NULL,
        Card_num      BIGINT NOT NULL,
        cutomer_id    serial NOT Null 
     ) ;
CREATE TABLE IF NOT EXISTS Payment (
        Card_num      BIGINT NOT NULL,
        Fname         VARCHAR(25) NOT NULL,
        Middle_init   VARCHAR(3) NOT NULL,
        Lname         VARCHAR(30) NOT NULL,
        Experation    integer NOT NULL,    
        Cvc           integer NOT NULL,  
        Type          VARCHAR(25) NOT NULL,
        Street_no     integer NOT NULL,  
        Street        VARCHAR(25) NOT NULL,
        zip           integer NOT NULL,  
        city          VARCHAR(25) NOT NULL,
        state         VARCHAR(3) NOT NULL,
        order_num     SERIAL NOT NULL  
     );
 CREATE TABLE IF NOT EXISTS Customer (
        Customer_id   SERIAL NOT NULL,        
        Fname         VARCHAR(15) NOT NULL,
        Middle_init   VARCHAR(1)  NULL,
        Lname         VARCHAR(20) NOT NULL,
        Pword         VARCHAR(10) NOT NULL,
        Email         VARCHAR(255) NOT NULL,
        phone         BIGINT NOT NULL,
        Order_num     SERIAL NOT NULL,  
        Card_num      BIGINT NOT NULL
	);
 CREATE TABLE IF NOT EXISTS  Address(
        Street_no     integer NOT NULL,  
        Street        VARCHAR(15) NOT NULL,
        zip           integer NOT NULL,  
        city          VARCHAR(15) NOT NULL,
        state         VARCHAR(02) NOT NULL,
        order_num     SERIAL NOT NULL,  
        Type          VARCHAR(15) NOT NULL,
        Customer_id   SERIAL NOT NULL  
     );

 CREATE TABLE  IF NOT EXISTS Status (
        S_id          SERIAL NOT NULL, 
        State         VARCHAR(15) NOT NULL

     );
CREATE TABLE  IF NOT EXISTS Updates (
        Time          time NOT NULL,
        S_id          SERIAL NOT NULL,  
        order_num     SERIAL NOT NULL 
     );
CREATE TABLE  IF NOT EXISTS Contains (
        Qty_sold      integer NOT NULL,  
        Datee         date NOT NULL,
        S_price       double precision NOT NULL,
        order_num     SERIAL NOT NULL, 
        P_id          integer NOT NULL 
     );
CREATE TABLE  IF NOT EXISTS Recieves (
        Qty_recieved   integer NOT NULL, 
        Datee          date NOT NULL,
        P_price        double precision NOT NULL,
        Po_id          integer NOT NULL, 
        P_id           integer NOT NULL 
     );
CREATE TABLE  IF NOT EXISTS Products (
        P_id          integer NOT NULL, 
        Category      VARCHAR(15) NOT NULL,
        P_name        VARCHAR(100) NOT NULL,
        S_price       double precision NOT NULL,
        P_price       double precision NOT NULL,
        D_id          SERIAL NOT NULL      
     );
CREATE TABLE  IF NOT EXISTS Distributors(
        D_id            SERIAL NOT NULL,     
        Company_name    VARCHAR(65) NOT NULL,
        Home_page       VARCHAR(75) NOT NULL,
        Phone           BIGINT NOT NULL,
        Fax             BIGINT NOT NULL,
        P_id            integer NOT NULL 
     );
CREATE TABLE  IF NOT EXISTS P_order(
        P_id          integer NOT NULL, 
        Datee         date NOT NULL
     );
CREATE TABLE  IF NOT EXISTS Inventory (
        Qty_order     integer NOT NULL,  
        Qty_sold      integer NOT NULL,  
        Qty_lost      integer NOT NULL,  
        P_id          integer NOT NULL 
     );

