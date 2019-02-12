/*------------------------------*/
/*---------ESQUEMA_BD ---------*/
/*----------------------------*/

CREATE TABLE PRODUCTOS(
ID INT(11) AUTO_INCREMENT,
NOMBRE VARCHAR(80),
MARCA VARCHAR(50),
DESCRIPCION VARCHAR(255),
PRECIO DOUBLE NOT NULL,

PRIMARY KEY(ID)
);

CREATE TABLE ORDEN_DESCRIPCION(
ID INT(11),
ID_PRODUCTO INT(11),
CANTIDAD INT(11),

PRIMARY KEY(ID,ID_PRODUCTO),
FOREIGN KEY(ID_PRODUCTO) REFERENCES PRODUCTOS(ID)

);

CREATE TABLE ORDEN_COMPRA(
ID INT(11) AUTO_INCREMENT,
FECHA TIMESTAMP,
TOTAL DOUBLE NOT NULL,
ID_DESCRIPCION INT(11),

PRIMARY KEY(ID),
FOREIGN KEY(ID_DESCRIPCION) REFERENCES ORDEN_DESCRIPCION(ID)
);


CREATE TABLE PRODUCTOS_AUDIT(
AUDIT_DATE TIMESTAMP,
AUDIT_USER VARCHAR(40) NOT NULL,
AUDIT_ACTION ENUM('update','delete','insert'),
ID_PRODUCTO INT(11),
PRECIO DOUBLE
);


/*-----------------------------------*/
/*----DISPARADOR_ORDEN_DE_COMPRA----*/
/*---------------------------------*/

-- Cada que se realice un registro en la taba orden_compra se modificara el precio del producto
-- Por cada unidad de producto ordenada se le incrementará en 1% a su precio actual para la siguientes ventas
-- En el caso de el producto con menor demanda en esa orden, se le restará el 1% a su precio acutal para la siguiente venta.
-- En este caso cuando sea un solo producto en la orden, a este se le restará el 1%.
-- En el caso de haber dor productos con menor solo a uno se le restará el 1%, al otro se le sumara.
DELIMITER //
DROP TRIGGER IF EXISTS tg_ordenCompra_AI;
CREATE TRIGGER tg_ordenCompra_AI 
AFTER INSERT ON ORDEN_COMPRA
FOR EACH ROW
BEGIN
	-- Declaración de variables.
	DECLARE done INT DEFAULT FALSE;
	DECLARE PAR_IDPRODUCTO INT(11);
	DECLARE PAR_CANTIDAD INT(11);
	DECLARE PAR_PRECIO DOUBLE DEFAULT 1;
	

	DECLARE CUR_PRODUCTO CURSOR FOR  
	SELECT ID_PRODUCTO,CANTIDAD 
	FROM ORDEN_DESCRIPCION 
	WHERE ID=NEW.ID_DESCRIPCION AND 
	ID_PRODUCTO!=(SELECT @MENOR:=ID_PRODUCTO FROM ORDEN_DESCRIPCION 
				WHERE ID=NEW.ID_DESCRIPCION AND 
				CANTIDAD=(SELECT MIN(CANTIDAD) FROM ORDEN_DESCRIPCION WHERE ID=NEW.ID_DESCRIPCION))
	FOR UPDATE;

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
	
	-- Calcular el nuevo precio del producto con menor venta.
	SET PAR_CANTIDAD :=(SELECT CANTIDAD FROM ORDEN_DESCRIPCION WHERE ID=NEW.ID_DESCRIPCION AND ID_PRODUCTO=@MENOR);
	SET PAR_PRECIO :=(SELECT PRECIO FROM PRODUCTOS WHERE ID=@MENOR);
	SET PAR_PRECIO =(PAR_PRECIO-(PAR_CANTIDAD*(0.01*PAR_PRECIO)));

	-- el precio no puede ser menor que uno por lo cual si es menor que 1 automaticamente se asigna el 1.
	IF(PAR_PRECIO<1)THEN 
		UPDATE PRODUCTOS SET PRECIO=1 WHERE ID=@MENOR;
	ELSE
		UPDATE PRODUCTOS SET PRECIO=PAR_PRECIO WHERE ID=@MENOR;
	END IF;

	-- abrimos cursor.
	OPEN CUR_PRODUCTO;

	-- iniciamos el ciclo.
	read_loop: LOOP
	-- emparejamos las variables.
	FETCH CUR_PRODUCTO INTO PAR_IDPRODUCTO, PAR_CANTIDAD;

	-- verificamos si aun había registros en el cursor.
	-- en caso de no haber salir del ciclo.
	IF done THEN
      LEAVE read_loop;
    END IF;
    	-- calculamos el nuevo precio +1%
		SET PAR_PRECIO = (SELECT PRECIO FROM PRODUCTOS WHERE ID=PAR_IDPRODUCTO);
		SET PAR_PRECIO = PAR_PRECIO+(PAR_CANTIDAD*(0.01*PAR_PRECIO));
		UPDATE PRODUCTOS SET PRECIO=PAR_PRECIO WHERE ID=PAR_IDPRODUCTO;
	END LOOP;
	CLOSE CUR_PRODUCTO;

END
//
DELIMITER ;


/*-----------------------------------*/
/*----------TRIGGER_AUDIT-----------*/
/*---------------------------------*/
-- Cada que se modifique un registro de la tabla productos, en especifico del campo precio
-- Se almacenará en la tabla productos_audit el precio antiguo y al producto al que pertenece
-- entre otra informacion.
DELIMITER //
DROP TRIGGER IF EXISTS tg_productosAudit_BU;
CREATE TRIGGER tg_productosAudit_BU
BEFORE UPDATE ON PRODUCTOS
FOR EACH ROW
BEGIN

	IF NEW.PRECIO!=OLD.PRECIO THEN
		INSERT INTO PRODUCTOS_AUDIT(AUDIT_USER,AUDIT_ACTION,ID_PRODUCTO,PRECIO)
		VALUES (CURRENT_USER(),'update',OLD.ID,OLD.PRECIO);
	END IF;

END
//
DELIMITER ;


/*---------------------------------------*/