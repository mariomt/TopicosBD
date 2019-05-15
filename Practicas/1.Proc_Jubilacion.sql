
/*
Crear programa que realice una jubilación forsoza 
a las personas con edades mayores a 70 años, que el campo 
IMPARTE_CLASES sea igual a cero (quiere decir que no imparte ninguna 
clase), y ademas que las horas sean menores a 15
*/

/*
Para identificar a las personas jubiladas y a las 
no jubiladas se creara una columna nueva llamada 
JUBILADO en la base de datos CEMABE_PERSONAL.
*/

--Crear columna para indicar que la persona esta jubilada.
ALTER TABLE CEMABE_PERSONAL ADD JUBILADO BOOLEAN DEFAULT 0;


DELIMITER //

DROP PROCEDURE IF EXISTS SP_JUBILADO;
CREATE PROCEDURE IF NOT EXISTS SP_JUBILADO()
BEGIN
    --Declaración de variables.
    DECLARE VAL_CURP VARCHAR(255);
    DECLARE VAL_ID_PERSONA VARCHAR(255);
    DECLARE VAL_EDAD INT;
    DECLARE VAL_IMPARTE_CLASES INT;
    DECLARE VAL_HORAS INT; 
    DECLARE VAL_JUBILADO BOOLEAN DEFAULT 0;
    DECLARE FINALIZADO INT DEFAULT 0;
    
    --Crear cursor.
    DECLARE CUR_PERSONAL CURSOR FOR 
        SELECT CURP,ID_PERSONA,EDAD,IMPARTE_CLASES,CAST(HORAS AS UNSIGNED INTEGER),JUBILADO
        FROM CEMABE_PERSONAL
        WHERE EDAD>70
        FOR UPDATE;


    DECLARE CONTINUE HANDLER FOR NOT FOUND SET FINALIZADO =1;

    --Abrimos el cursor
    OPEN CUR_PERSONAL;

    --Empezamos a recorer el cursor.
    REPEAT

    --Emparejar los valores devueltos con las variables.
    FETCH CUR_PERSONAL INTO VAL_CURP,VAL_ID_PERSONA,VAL_EDAD,VAL_IMPARTE_CLASES,VAL_HORAS,VAL_JUBILADO;

    --Si la persona es mayor de 70 años, imparte 0 clases y tiene signadas
    --menos de 15 horas entonces jubílalo.
    IF VAL_EDAD>70 AND VAL_IMPARTE_CLASES=0 AND VAL_HORAS<15 THEN
        SET VAL_JUBILADO=1;
	ELSE 
		SET VAL_JUBILADO=0;
    END IF;

    --Actualiza el campo en la BD.
    UPDATE CEMABE_PERSONAL SET JUBILADO=VAL_JUBILADO 
    WHERE CURP=VAL_CURP AND ID_PERSONA=VAL_ID_PERSONA;

    UNTIL FINALIZADO = 1 END REPEAT;

    CLOSE CUR_PERSONAL;
    

END
//

DELIMITER ;