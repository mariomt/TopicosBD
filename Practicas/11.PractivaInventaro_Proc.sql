DELIMITER //
DROP PROCEDURE IF EXISTS sp_AddSuply;
CREATE PROCEDURE sp_AddSuply(
	P_ARG_PRODUCT TEXT,
	P_QTTY_PRODUCT TEXT,
	P_ID_SUPPLIER INT(11),
	P_DATE TIMESTAMP()
)
BEGIN

	-- Declaración de variables.
	DECLARE V_TOTAL DOUBLE() DEFAULT 1;
	DECLARE V_FECHA TIMESTAMP() DEFAULT NOW();
	DECLARE V_ID INT(11);
	DECLARE p_arreglo VARCHAR(500);
	DECLARE p_arreglo2 VARCHAR(255);
	DECLARE p_mensaje VARCHAR(500) DEFAULT '';

	-- Setiar los arreglos auxiliares con la 
	-- información de los parametros.
	SET p_arreglo = P_ARG_PRODUCT;
	SET p_arreglo2= P_QTTY_PRODUCT;

	-- Sacar la longitud del arreglo de productos
	SET @num = LENGTH(p_arreglo);

	-- Si el arreglo no tiene longitud >0 
	-- esto quiere decir que no hay ningun elemento.
	IF (@num = 0) THEN 
		SIGNAL SQLSTATE '46003'
		SET MESSAGE_TEXT='No se ingreso ningun objeto.';
	END IF;

	-- si contiene una coma al final de la cadena se eliminará
	IF (SUBSTRING(p_arreglo,LENGTH(p_arreglo),1))=',' THEN
		SET p_arreglo :=SUBSTRING(p_arreglo,1,LENGTH(p_arreglo)-1);
	END IF;

	-- de igual manera se aplica para el arreglo de las cantidades.
	IF (SUBSTRING(p_arreglo2,LENGTH(p_arreglo2),1))=',' THEN
		SET p_arreglo2 :=SUBSTRING(p_arreglo2,1,LENGTH(p_arreglo2)-1);
	END IF;

	-- Calcular la cantidad de productos a ingresar
	SET @num =(LENGTH(p_arreglo) - LENGTH(REPLACE(p_arreglo, ',', '')))+1;
	-- Calcular la cantidad de parametos correspondiente a las cantidades.
	SET @num2=(LENGTH(p_arreglo2) - LENGTH(REPLACE(p_arreglo2, ',', '')))+1;

	-- El numero de objetos debe ser igual al numero de cantidades enviadas.
	IF  @num!=@num2 THEN
		SIGNAL SQLSTATE '46003'
		SET MESSAGE_TEXT='No coinciden la cantidad de columnas productos,cantidad.';
	END IF;

	-- Procedemos a realizar los registros...
	IF @num = 1 THEN
		-- Lo siguiente se hara en el caso de ser un solo producto
		IF NOT EXISTS (SELECT ID FROM PRODUCTS WHERE ID_PRODUCT=p_arreglo) THEN
			SET p_mensaje = CONCAT("El producto con id ",p_arreglo, " no se encuentra en la base de datos.");
			SIGNAL SQLSTATE '46004'
			SET MESSAGE_TEXT= p_mensaje;
		ELSE
			SET V_TOTAL=(SELECT PRICE FROM PRODUCTS WHERE ID_PRODUCT=p_arreglo);
			INSERT INTO SUPPLY(ID_SUPPLIER,USER,`DATE`,TOTAL) VALUES(P_ID_SUPPLIER,CURRENT_USER(),V_FECHA,V_TOTAL);
			SET V_ID=(SELECT ID_SUPPLY FROM SUPPLY WHERE ID_SUPPLIER=P_ID_SUPPLIER AND USER=CURRENT_USER() AND `DATE`=V_FECHA AND TOTAL=V_TOTAL);
			INSERT INTO SUPPLY_DESCRIPTION(ID_SUPPLY,ID_PRODUCT,QUANTITY) VALUES(V_ID);
		END IF;
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