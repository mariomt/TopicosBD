/*
------------------------------------
Autor:Murillo Tinoco Mario Gilberto
------------------------------------
*/


/*if(Logic_expression,true,false);*/

ALTER TABLE CEMABE_PERSONAL ADD NIVELMOD VARCHAR(1);

DELIMITER //
CREATE PROCEDURE subirNivel()
BEGIN
	UPDATE CEMABE_PERSONAL SET NIVELMOD=if(CAST(NIVEL AS UNSIGNED INTEGER)<8, NIVEL+2,if(CAST(NIVEL AS UNSIGNED INTEGER)=8,NIVEL+1,NIVEL+0));
	SELECT NIVEL,NIVELMOD,COUNT(*) FROM CEMABE_PERSONAL GROUP BY NIVEL;
END//
DELIMITER ;


/*+--------------------+
  |SOLUCION DEL PROFE  |
  +--------------------+*/


/*
	
*/
DELIMITER $$

CREATE PROCEDURE SP_NIVEL(
	IN PAR_CURP VARCHAR(255),
	IN PAR_ID_PERSONA VARCHAR(255),
	IN PAR_CLAVE_CT VARCHAR(255),
	IN PAR_NIVEL INT
)
BEGIN

	SET NIVEL_NUEVO=NIVEL_ACTUAL+2;

	IF NIVEL_NUEVO>9 THEN
		SET= NIVEL_NUEVO=9;
	END IF;

	UPDATE CEMABE_PERSONAL SET NIVEL=PAR_NIVEL WHERE CURP=PAR_CURP AND ID_PERSONA=PAR_ID_PERSONA AND CLAVE_CT=PAR_CLAVE_CT;
END$$

DELIMITER ;

CALL SP_NIVEL('VIPR521125HJCLRC06','1764176','14EES0015U1');

COMMIT;


/*OTRA OPCION*/

DELIMITER //

CREATE PROCEDURE SP_NIVEL()
BEGIN

-- SE DECLARAN ALGUNAS VARIABLES QUE NOS VAN AYUDAR

DECLARE VAL_CURP VARCHAR(255);
DECLARE VAL_ID_PERSONA VARCHAR(255);
DECLARE VAL_CLAVE_CT VARCHAR(255);
	DECLARE VAL_NIVEL INT;
	DECLARE VAL_NIVEL_NUEVO INT;
	DECLARE FINALIZADO INT DEFAULT 0;

	-- Un cursor es un ciclo, y lo va a recorrer son los registros del SELECT que lo pongamos.
		-- En este caso seleccionamos l clave primaria y el valor del NIVEL(para poder hacer la operacion y actualizarlo)
		-- Como en nuvel maximo es 9, hacemos SELECT sobre los registros con nivel menor a 9, para continuar.
		-- FOR UPDATE indica que los calores pueden ser actualiados con una sentencia UPDATE.

	DECLARE CUR_PERSONAL CURSOR FOR
		SELECT CURP,ID_PERSONA,CLAVE_CT,NIVEL
			FROM CEMABE_PERSONAL
			WHERE NIVEL <9
			FOR UPDATE;


		-- Los cursores corren y corren hasta terminar con un indicarod "NOT FOUND", esta variable se pone en 1 cuando esto pasa y nos ayuda a terminar el ciclo.
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET FINALIZADO=1;

		-- Se abre el cursor, es decir, se inicia

		OPEN CUR_PERSONAL;

		--Hacemos un ciclo para recorrer el cursor.
		REPEAT

			/*Fetch es la sentencia que ontiene los valores del registro actual del cursor, mete esos valores en las 
			variables que declaramos y avanza al siguiente registro automaticamente.*/

			/* Recordemos que el cursor que declaramos es "SELECT CURP,ID_PERSONA,CLAVE_CT,NIVEL"...
			estos campos caen exactamente en las variables que tiene el FETCH*/

		FETCH CUR_PERSONAL INTO VAL_CURP,VAL_ID_PERSONA,VAL_CLAVE_CT,VAL_NIVEL

		-- Hacemos la operacion
		SET VAL_NIVEL_NUEVO = VAL_NIVEL+2;
		IF VAL_NIVEL_NUEVO>=9 THEN
			SET VAL_NIVEL_NUEVO=9;
		END IF;

		-- Actualizamos ese registro especifico de la tabla con el nuevo valor del Nivel.

		UPDATE CEMABE_PERSONAL SET NIVEL=VAL_NIVEL_NUEVO WHERE CURP=VAL_CURP AND ID_PERSONA=VAL_ID_PERSONA AND CLAVE_CT=VAL_CLAVE_CT;

		-- El ciclo se repite hasta que FINALIZADO = 1, esto sucederá automáticamente cuando el CURSOR haya recorrido todos los registros y regrese un "NOT FOUND"

		UNTIL FINALIZADO = 1 END REPEAT;

		-- FINALMENTE cerramos el cursor.

		CLOSE CUR_PERSONAL;


END//
DELIMITER ;

/*
Convertir o rescatar lo mayor posible del procedimieto
anterior con la finalidad de colocarlo en un trigger. 
*/

DELIMITER //
DROP TRIGGER IF EXISTS tg_nivel_BU;
CREATE TRIGGER tg_nivel_BU
BEFORE UPDATE ON MAESTROS_ISSTESON.CEMABE_PERSONAL
FOR EACH ROW
BEGIN 

	DECLARE diferencia INT(11) DEFAULT 0;
	SET diferencia= NEW.NIVEL-OLD.NIVEL;
	IF diferencia<0 THEN
	-- Si la diferencia es menor a 0 esto nos indica que se intenta bajar
	-- el nivel, por lo tanto no se ejecuta esta accion.
		SET NEW.NIVEL=OLD.NIVEL;
	ELSEIF OLD.NIVEL<8 THEN
	-- Si el nivel actual es menor a 8 esto nos indica que al nivel se le
	-- puede incrementar 2 unidades.
		IF diferencia > 2 THEN
			-- En el caso de que al nivel actual se le intente incrementar mas 2 unidades
			-- este se ajustará automaticamente para que solo suba 2 unidades.
			SET NEW.NIVEL = OLD.NIVEL+2;
		ELSEIF diferencia=1 THEN
			-- En el caso de que se intente incrementar a 1 unidad el nivel, este automaticamente le
			-- aumentara otra unidad para que cumpla con la regla de subir 2 niveles.
			SET NEW.NIVEL= NEW.NIVEL+1;
		END IF;
	-- En el siguiente caso del if, si el valor acutal es 8 quiere 
	-- decir que solo se puede incrementar en uno el nivel actual.
	ELSEIF OLD.NIVEL = 8 THEN
		IF diferencia>1 THEN
			-- En el caso de que se este intentando incrementar un 
			-- numero mayor a uno este solo se incrementara en uno.
			SET NEW.NIVEL = OLD.NIVEL+1;
		END IF;
	ELSEIF OLD.NIVEL = 9 THEN
		-- si se esta intentando modificar el valor 
		-- actual el cual ya es 9, este de mantiene en 9
		IF diferencia!=0 THEN
			SET NEW.NIVEL=9;
		END IF;
	END IF; 


END
//
DELIMITER ;



















DELIMITER //

CREATE PROCEDURE SP_NIVEL()
BEGIN


	DECLARE VAL_CURP VARCHAR(255);
	DECLARE VAL_ID_PERSONA VARCHAR(255);
	DECLARE VAL_CLAVE_CT VARCHAR(255);
	DECLARE VAL_NIVEL INT(11);
	DECLARE VAL_NIVEL_NUEVO INT;
	DECLARE FINALIZADO INT DEFAULT 0;


	DECLARE CUR_PERSONAL CURSOR FOR
		SELECT CURP,ID_PERSONA,CLAVE_CT,NIVEL
			FROM CEMABE_PERSONAL
			WHERE NIVEL <9
			FOR UPDATE;
		
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET FINALIZADO=1;


		OPEN CUR_PERSONAL;


		FETCH CUR_PERSONAL INTO VAL_CURP,VAL_ID_PERSONA,VAL_CLAVE_CT,VAL_NIVEL;

		SET VAL_NIVEL_NUEVO = VAL_NIVEL+2;
		IF VAL_NIVEL_NUEVO>=9 THEN
			SET VAL_NIVEL_NUEVO=9;
		END IF;


		UPDATE CEMABE_PERSONAL SET NIVEL=VAL_NIVEL_NUEVO WHERE CURP=VAL_CURP AND ID_PERSONA=VAL_ID_PERSONA AND CLAVE_CT=VAL_CLAVE_CT;G

		
		UNTIL FINALIZADO = 1 END REPEAT;


		CLOSE CUR_PERSONAL;

END//
DELIMITER ;

