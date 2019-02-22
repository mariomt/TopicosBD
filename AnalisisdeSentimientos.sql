-- Estructura de la base de datos.
DROP DATABASE IF EXISTS AnalisisSentimientos;

CREATE DATABASE AnalisisSentimientos;

USE AnalisisSentimientos;

DROP TABLE IF EXISTS tclientes;
CREATE TABLE tclientes(
	numCliente INT(11) AUTO_INCREMENT,
	nombre VARCHAR(50),
	ap_paterno VARCHAR(50),
	ap_materno VARCHAR(50),
	PRIMARY KEY(numCliente)
);

DROP TABLE IF EXISTS tcomentarios;
CREATE TABLE tcomentarios(
	id INT(11) AUTO_INCREMENT,
	fecha TIMESTAMP NOT NULL,
	comentario VARCHAR(255),
	numCliente INT(11),
	PRIMARY KEY(id),
	FOREIGN KEY(numCliente) REFERENCES tclientes(numCliente)
);


DROP TABLE IF EXISTS tclasificacion;
CREATE TABLE tclasificacion(
	id INT(11) AUTO_INCREMENT,
	clasificacion ENUM('verde','amarillo','rojo','blanco'),
	numCliente INT(11),
	PRIMARY KEY(id),
	FOREIGN KEY(numCliente) REFERENCES tclientes(numCliente);
);



/* Vista para ver los clientes con su clasificacion*/
CREATE VIEW vw_clasificaciones AS 
SELECT numCliente,clasificacion FROM tclasificacion;


DELIMITER //
DROP PROCEDURE IF EXISTS sp_clasificacionesllenado;
CREATE PROCEDURE sp_clasificacionesllenado(
)
BEGIN
	-- Declaracion de variables.
	DECLARE P_NUMCLIENTE INT(11);
	DECLARE P_COMENTARIO VARCHAR(255);
	DECLARE P_CLASIFICACION VARCHAR(50);
	DECLARE done INT DEFAULT FALSE;

	-- Cursor con el ultimo comentario de cada cliente.
	DECLARE CUR_COMENT CURSOR FOR
		SELECT numCliente,comentario 
		FROM tcomentarios 
		WHERE(numCliente,fecha)
		IN(SELECT numCliente,max(fecha) 
				FROM tcomentarios GROUP BY numCliente);

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

	-- Abrir o iniciar el cursor.
	OPEN CUR_COMENT;

	read_loop: LOOP
	    FETCH CUR_COMENT INTO P_NUMCLIENTE,P_COMENTARIO;

	    -- Conprobar si se encontro un NOT FOUND
	    IF done THEN
	      LEAVE read_loop;
	    END IF;

	    -- Llamar a la función que me dice la clasificación del comentario
	    -- y guardar el resultado en la variable P_CLASIFICACION.
	    SET P_CLASIFICACION = (SELECT fc_clasificacion(P_COMENTARIO));
	    
	    -- Si existe ya existe una clasificacion de este cliente entonces solo se modifica.
		-- en caso contrario se debe realizar el registro del mismo.
	    IF EXISTS(SELECT id FROM tclasificacion WHERE numCliente=P_NUMCLIENTE) THEN
	    	UPDATE tclasificacion SET clasificacion=P_CLASIFICACION WHERE numCliente=P_NUMCLIENTE;
	    ELSE
	    	INSERT INTO tclasificacion(clasificacion,numCliente) VALUES(P_CLASIFICACION,P_NUMCLIENTE);
	    END IF;

  	END LOOP;

  	--Cerrar el cursor.
  	CLOSE CUR_COMENT;
END
//
DELIMITER ;


DELIMITER //
DROP TRIGGER IF EXISTS tg_tcomentarios_AI;
CREATE TRIGGER tg_tcomentarios_AI
AFTER INSERT ON tcomentarios
FOR EACH ROW
BEGIN
	DECLARE P_CLASIFICACION VARCHAR(50);
	SET P_CLASIFICACION = (SELECT fc_clasificacion(NEW.comentario));

	-- Si existe ya existe una clasificacion de este cliente entonces solo se modifica.
	-- en caso contrario se debe realizar el registro del mismo.
	IF EXISTS(SELECT id FROM tclasificacion WHERE numCliente=P_NUMCLIENTE) THEN
		UPDATE tclasificacion SET clasificacion=P_CLASIFICACION WHERE numCliente=NEW.numCliente;
    ELSE
	    INSERT INTO tclasificacion(clasificacion,numCliente) VALUES(P_CLASIFICACION,NEW.numCliente);
	END IF;
	
END
//
DELIMITER ;

DELIMITER //
CREATE FUNCTION fc_clasificacion(
	P_COMENTARIO VARCHAR(255)
) RETURNS VARCHAR(50) DETERMINISTIC
BEGIN
	-- Variable donde se almacenará el tipo de clasificación.
	DECLARE P_CLASIFICACION VARCHAR(50);

	-- Comparar el comentario con las frases.
	-- Si el comnetario contiene alguna de las frases indicadas
	-- se le asignara el color señalado en cada bloque.
	IF (LOCATE(("Quiero conocer el fraccionamiento"),P_COMENTARIO)>0) 
				OR (LOCATE("quiero visitar la casa modelo",P_COMENTARIO)>0) THEN
    	SET P_CLASIFICACION="verde";

    ELSEIF (LOCATE(("llamenme"),P_COMENTARIO)>0) 
    			OR (LOCATE("saber si califico",P_COMENTARIO)>0) THEN
    	SET P_CLASIFICACION="amarillo";

    ELSEIF (LOCATE(("nos puede llamar despues"),P_COMENTARIO)>0) 
    			OR (LOCATE("preguntar a mi esposa",P_COMENTARIO)>0) THEN
    	SET P_CLASIFICACION="rojo";

    ELSE
    	SET P_CLASIFICACION="blanco";
    END IF;

    -- valor a devolver.
    RETURN P_CLASIFICACION;
END
//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_cambio(
	IN p_nombre VARCHAR(255),
	IN p_id INT(11)
)
BEGIN
	IF EXISTS(UPDATE t1 SET nombre=p_nombre where id=p_id) THEN
		SELECT * from t1;
	END IF;
END
//
DELIMITER ;









