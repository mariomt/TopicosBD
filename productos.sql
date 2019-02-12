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

/*------------------------------------------*/



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

	


-- NOTA: esto no es parte de la tarea.

/*----------------------------*/
/*-----------VENTA-----------*/
/*--------------------------*/

-- Este método hace el registro de la orden de compra y descripcion de la compra.
-- el primer parametro debe ser una cadena con el id de los productos separados por comas.
-- el segundo parametro debe ser una cadena con las cantidades de productos respectivos al primer paramentro.   
DELIMITER //
DROP PROCEDURE IF EXISTS sp_orden;
CREATE PROCEDURE sp_orden(
	IN P_ARG_PROD VARCHAR(500),
	IN P_ARG_CANT VARCHAR(255)
)
BEGIN
	DECLARE p_id_control INT(11) DEFAULT 1;
	DECLARE p_arreglo VARCHAR(500);
	DECLARE p_arreglo2 VARCHAR(255);
	DECLARE total DOUBLE DEFAULT 0;
	DECLARE p_mensaje VARCHAR(500) DEFAULT '';
	SET p_arreglo = P_ARG_PROD;
	SET p_arreglo2= P_ARG_CANT;

	SET @num = LENGTH(p_arreglo);
	IF (@num = 0) THEN 
		SIGNAL SQLSTATE '46003'
		SET MESSAGE_TEXT='No se ingreso ningun objeto.';
	END IF;
	 
	IF NOT EXISTS (SELECT id FROM ORDEN_DESCRIPCION) THEN
		SET @id_venta = 1;
	ELSE
		SELECT @id_venta:= max(id) FROM ORDEN_DESCRIPCION;
		SET @id_venta= @id_venta + 1;
	END IF;

	-- si contiene una coma al final de la cadena se eliminará
	IF (SUBSTRING(p_arreglo,LENGTH(p_arreglo),1))=',' THEN
		SET p_arreglo :=SUBSTRING(p_arreglo,1,LENGTH(p_arreglo)-1);
	END IF;

	IF (SUBSTRING(p_arreglo2,LENGTH(p_arreglo2),1))=',' THEN
		SET p_arreglo2 :=SUBSTRING(p_arreglo2,1,LENGTH(p_arreglo2)-1);
	END IF;
	
	/*Calcular la cantidad de productos a vender*/
	SET @num =(LENGTH(p_arreglo) - LENGTH(REPLACE(p_arreglo, ',', '')))+1;
	SET @num2=(LENGTH(p_arreglo2) - LENGTH(REPLACE(p_arreglo2, ',', '')))+1;

	IF  @num!=@num2 THEN
		SIGNAL SQLSTATE '46003'
		SET MESSAGE_TEXT='No coinciden la cantidad de columnas productos,cantidad.';
	END IF;



	IF @num = 1 THEN
		IF NOT EXISTS (SELECT ID FROM PRODUCTOS WHERE ID=p_arreglo) THEN
			SET p_mensaje = CONCAT("El producto con id ",p_arreglo, " no se encuentra en la base de datos.");
			SIGNAL SQLSTATE '46004'
			SET MESSAGE_TEXT= p_mensaje;
		ELSE
			SET total=(SELECT PRECIO FROM PRODUCTOS WHERE ID=p_arreglo);
			INSERT INTO ORDEN_DESCRIPCION(ID,ID_PRODUCTO,CANTIDAD) VALUES(@id_venta,p_arreglo,p_arreglo2);
		END IF;
		INSERT INTO ORDEN_COMPRA(TOTAL,ID_DESCRIPCION) VALUES(total,@id_venta);
	ELSEIF @num > 1 THEN
		SET p_arreglo= CONCAT(p_arreglo,",");
		SET p_arreglo2= CONCAT(p_arreglo2,",");
		WHILE @num > 0 DO
			SET @argTemp=SUBSTRING(p_arreglo,1,LOCATE(",",p_arreglo)-1);
			SET @argTemp2=SUBSTRING(p_arreglo2,1,LOCATE(",",p_arreglo2)-1);
			
			IF NOT EXISTS(SELECT id FROM PRODUCTOS WHERE ID=CAST(@argTemp AS SIGNED INTEGER)) THEN
				SET p_mensaje= CONCAT(p_mensaje,"El producto ", @argTemp," no se encuentra en la base de datos. ");
			ELSE
				INSERT INTO ORDEN_DESCRIPCION(ID,ID_PRODUCTO,CANTIDAD) VALUES (@id_venta,CAST(@argTemp AS SIGNED INTEGER),CAST(@argTemp2 AS SIGNED INTEGER));
				SET p_id_control= p_id_control + 1;
				SET total=total+(SELECT PRECIO FROM PRODUCTOS WHERE ID=p_arreglo);
			END IF;
			SET @num = @num - 1;
			
			IF (@num >0) THEN
				SET p_arreglo := SUBSTRING(p_arreglo,LOCATE(",",p_arreglo)+1,LENGTH(p_arreglo));
				SET p_arreglo2 := SUBSTRING(p_arreglo2,LOCATE(",",p_arreglo2)+1,LENGTH(p_arreglo2));
			END IF;
		END WHILE;
		INSERT INTO ORDEN_COMPRA(TOTAL,ID_DESCRIPCION) VALUES(total,@id_venta);
	ELSE
		SIGNAL SQLSTATE '46005'
		SET MESSAGE_TEXT='Error: Hay un problema en la cadena introducida.';
	END IF;

END
//
DELIMITER ;





/*-------------------------------*/



/*-------DATOS-------*/
INSERT INTO PRODUCTOS(NOMBRE,MARCA,DESCRIPCION,PRECIO) VALUES
('DORITOS','SABRITAS','INCOGNITA',11.50),
('CHETOS','SABRITAS','VERDES',8),
('RUFLES','SABRITAS','ORIG',12.3),
('COCA-COLA','COCA-COLA','2.5L',25),
('LECHE','YAQUI','TAPA ROJA 5L',24.5),
('CACAHUATES','SABRITAS','JAPONESES 12gr',10.5);

