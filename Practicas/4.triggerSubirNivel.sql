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