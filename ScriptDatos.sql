/*crear indices:*/

ALTER TABLE customer_contacts
ADD INDEX<customer_code>;


/*Como Crear indices*/
CREATE INDEX NOMBRE_INDEX
ON TABLE(COLUM1,COLUM2....);


/*Verificar indices...*/
SHOW INDEXES FROM NOMBRE_TABLA;


/*Borrar indices*/
DROP INDEX <NOMBRE DEL INDEX> ON <TABLA>;

/*INDICES PARCIALES*/
/*Podemos crear un indice utilizando solo una parte del campo (de su contenido), por ejemplo este comando crea un indice sobre los primeros 5 caracteres del campo*/

CREATE INDEX cust_name_indx ON customers<name<5>>

/*INDICE COMPUESTO*/
CREATE INDEX Nombre_llave ON nombreTabla(campo1,campo2,campo3....);



/*
SOLO LAS TABLAS CON TIPO MyISAM*(No transaccionales ) soportan indices tipo FULL-Tex/
*/
CREATE TABLE clientes(
	customes_code VARCHAR(10) NOT NULL,
	name     VARCHAR(40) NOT NULL,
	PRIMARY KEY(CUSTOMER_CODE)
)
ENGINE = MyISAM;




/*-------------------2019-01-21--------------------*/

EXPLAIN

mysql> use CEMABE;

mysql> SHOW TABLES;

mysql> DESCRIBE CEMABE_PERSONAL;

mysql> SELECT ENT,COUNT(*) FROM CEMABE_PERSONAL GOUP BY ENT;

mysql> EXPLAIN SELECT ENT,COUNT(*) FROM CEMABE_PERSONAL GOUP BY ENT;

mysql> CREATE INDEX IND_CEMABE_ENT ON CEMABE_PERSONAL(ENT);

mysql> EXPLAIN SELECT ENT,COUNT(*) FROM CEMABE_PERSONAL GOUP BY ENT;

mysql> SELECT ENT,COUNT(*) FROM CEMABE_PERSONAL GOUP BY ENT;