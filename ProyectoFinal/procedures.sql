/* ------Created by----- */
-- Ayala Daniel.
-- Murillo Mario.
/* -------------------- */


DELIMITER //
DROP PROCEDURE IF EXISTS sp_nuevoCombo;
CREATE PROCEDURE sp_nuevoCombo(
	in p_nombre varchar(255),
	in p_procedencia varchar(30),
	in p_descripcion varchar(500),
	in arg_productos varchar(1000),
	in arg_cantidades varchar(1000)
)
BEGIN
	DECLARE p_mensaje VARCHAR(500) DEFAULT ''; 
	DECLARE p_arreglo VARCHAR(1000);
	DECLARE p_arreglo2 VARCHAR(1000);
	DECLARE p_idCombo BIGINT(20) DEFAULT 0;

	SET p_arreglo = arg_productos;
	SET p_arreglo2 = arg_cantidades;

	-- Si la cadena esta bacía manda error
	SET @num = LENGTH(p_arreglo);
	IF (@num = 0) THEN 
		SIGNAL SQLSTATE '46003'
		SET MESSAGE_TEXT='No se ingreso ningun producto al combo.';
	END IF;

	SET @num2 = LENGTH(p_arreglo2);
	IF (@num2 = 0) THEN 
		SIGNAL SQLSTATE '46003'
		SET MESSAGE_TEXT='Debe especificar las cantidades de cada producto';
	END IF;

	/*Calcular la cantidad de objetos a registrar*/
	SET @num =(LENGTH(p_arreglo) - LENGTH(REPLACE(p_arreglo, ',', '')))+1;
	SET @num2 =(LENGTH(p_arreglo2) - LENGTH(REPLACE(p_arreglo2, ',', '')))+1;

	IF (@num <> @num2) THEN 
		SIGNAL SQLSTATE '46003'
		SET MESSAGE_TEXT='Debe especificar las cantidades de cada producto';
	END IF;

	IF EXISTS (SELECT ID FROM CINE.PRODUCTOS WHERE UPPER(NOMBRE)=UPPER(TRIM(p_nombre))) THEN
		SET p_mensaje = CONCAT("El combo con nombre ",UPPER(p_nombre), " ya existe.");
		SIGNAL SQLSTATE '46004'
		SET MESSAGE_TEXT= p_mensaje;
	ELSE
		INSERT INTO CINE.PRODUCTOS(ID_MARCA,NOMBRE,PROCEDENCIA,DESCRIPCION,COMBO) VALUES(9,UPPER(p_nombre),p_procedencia,p_descripcion,1);
		SET p_idCombo=(SELECT @@identity AS id);
		
		IF @num = 1 THEN
			INSERT INTO CINE.COMBOS(ID_COMBO,ID_PRODUCTO,CANTIDAD) VALUES (p_idCombo,p_arreglo,p_arreglo2);
		ELSEIF @num > 1 THEN
			SET p_arreglo= CONCAT(p_arreglo,",");
			SET p_arreglo2= CONCAT(p_arreglo2,",");
			WHILE @num > 0 DO
				SET @argTemp=SUBSTRING(p_arreglo,1,LOCATE(",",p_arreglo)-1);
				SET @argTemp2=SUBSTRING(p_arreglo2,1,LOCATE(",",p_arreglo2)-1);

				IF NOT EXISTS(SELECT ID FROM CINE.PRODUCTOS WHERE ID=CAST(@argTemp AS SIGNED)) THEN
					SET p_mensaje= CONCAT(p_mensaje,"El producto ", @argTemp," no se encuentra en la base de datos. ");
				ELSE
					INSERT INTO CINE.COMBOS(ID_COMBO,ID_PRODUCTO,CANTIDAD) VALUES (p_idCombo,@argTemp,@argTemp2);
				END IF;
				SET @num = @num - 1;
				SET @num2 = @num2 - 1;
				IF (@num >0) THEN
					SET p_arreglo := SUBSTRING(p_arreglo,LOCATE(",",p_arreglo)+1,LENGTH(p_arreglo));
					SET p_arreglo2 := SUBSTRING(p_arreglo2,LOCATE(",",p_arreglo2)+1,LENGTH(p_arreglo2));
				END IF;
			END WHILE;
		ELSE
			SIGNAL SQLSTATE '46005'
			SET MESSAGE_TEXT='Error: Hay un problema en la cadena introducida.';
		END IF;
	END IF;
END
//
DELIMITER ; 