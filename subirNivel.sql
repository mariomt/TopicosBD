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
	IN PAR_NIVEL INT)
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

--SE DECLARAN ALGUNAS VARIABLES QUE NOS VAN AYUDAR

DECLARE VAL_CURP VARCHAR(255);
DECLARE VAL_ID_PERSONA VARCHAR(255);
DECLARE VAL_CLAVE_CT VARCHAR(255);
	DECLARE VAL_NIVEL INT;
	DECLARE VAL_NIVEL_NUEVO INT;
	DECLARE FINALIZADO INT DEFAULT 0;

	--Un cursor es un ciclo, y lo va a recorrer son los registros del SELECT que lo pongamos.
		--En este caso seleccionamos l clave primaria y el valor del NIVEL(para poder hacer la operacion y actualizarlo)
		--Como en nuvel maximo es 9, hacemos SELECT sobre los registros con nivel menor a 9, para continuar.
		--FOR UPDATE indica que los calores pueden ser actualiados con una sentencia UPDATE.

	DECLARE CUR_PERSONAL CURSOR FOR
		SELECT CURP,ID_PERSONA,CLAVE_CT,NIVEL
			FROM CEMABE_PERSONAL
			WHERE NIVEL <9
			FOR UPDATE;


		--Los cursores corren y corren hasta terminar con un indicarod "NOT FOUND", esta variable se pone en 1 cuando esto pasa y nos ayuda a terminar el ciclo.
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET FINALIZADO=1;

		--Se abre el cursor, es decir, se inicia

		OPEN CUR_PERSONAL;

		--Hacemos un ciclo para recorrer el cursor.
		REPEAT

			/*Fetch es la sentencia que ontiene los valores del registro actual del cursor, mete esos valores en las 
			variables que declaramos y avanza al siguiente registro automaticamente.*/

			/* Recordemos que el cursor que declaramos es "SELECT CURP,ID_PERSONA,CLAVE_CT,NIVEL"...
			estos campos caen exactamente en las variables que tiene el FETCH*/

		FETCH CUR_PERSONAL INTO VAL_CURP,VAL_ID_PERSONA,VAL_CLAVE_CT,VAL_NIVEL

		--Hacemos la operacion
		SET VAL_NIVEL_NUEVO = VAL_NIVEL+2;
		IF VAL_NIVEL_NUEVO>=9 THEN
			SET VAL_NIVEL_NUEVO=9;
		END IF;

		--Actualizamos ese registro especifico de la tabla con el nuevo valor del Nivel.

		UPDATE CEMABE_PERSONAL SET NIVEL=VAL_NIVEL_NUEVO WHERE CURP=VAL_CURP AND ID_PERSONA=VAL_ID_PERSONA AND CLAVE_CT=VAL_CLAVE_CT;

		--El ciclo se repite hasta que FINALIZADO = 1, esto sucederá automáticamente cuando el CURSOR haya recorrido todos los registros y regrese un "NOT FOUND"

		UNTIL FINALIZADO = 1 END REPEAT;

		--FINALMENTE cerramos el cursor.

		CLOSE CUR_PERSONAL;


END//
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

