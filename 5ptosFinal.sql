--Crear columna para indicar que la persona esta jubilada.
ALTER TABLE CEMABE_PERSONAL JUBILADO BOOLEAN DEFAULT 0;

--Realizar un programa que realice la jubilacion forsoza a las personas con edades mayores a 70 años,
--que el campo IMPARTE_CLASES =0 (quiere decir que no imparte ninguna clase) y ademas que las horas sean <15

DELIMITER //
CREATE PROCEDURE SP_JUBILADO (

)
BEGIN
    DECLARE VAL_CURP VARCHAR(255);
    DECLARE VAL_ID_PERSONA VARCHAR(255);
    DECLARE VAL_JUBILADO BOOLEAN DEFAULT 0;
    DECLARE FINALIZADO INT DEFAULT 0;
    
    DECLARE CUR_PERSONAL CURSOR FOR 
        SELECT CURP,ID_PERSONA
        FROM CEMABE_PERSONAL
        WHERE EDAD>70 AND IMPARTE_CLASES='0' AND HORA<15
        FOR UPDATE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET FINALIZADO =1;

    

END
//
DELIMITER ;

