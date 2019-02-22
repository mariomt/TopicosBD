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

CREATE TABLE tfrases(
	id INT(11) AUTO_INCREMENT,
	frase VARCHAR(255),
	clasificacion ENUM('verde','amarillo','rojo'),
	PRIMARY KEY(id)
);


/* Vista para ver los clientes con su clasificacion*/
CREATE VIEW vw_clasificaciones AS 
SELECT numCliente,clasificacion FROM tclasificacion;


DELIMITER //
DROP PROCEDURE IF EXISTS sp_clasificacionesllenado;
CREATE PROCEDURE sp_clasificacionesllenado(
)
BEGIN
	DECLARE P_NUMCLIENTE INT(11);
	DECLARE P_COMENTARIO VARCHAR(255);
	DECLARE P_CLASIFICACION VARCHAR(50);
	DECLARE done INT DEFAULT FALSE;

	DECLARE CUR_COMENT CURSOR FOR
		SELECT numCliente,comentario 
		FROM tcomentarios 
		WHERE(numCliente,fecha)
		IN(SELECT numCliente,max(fecha) 
				FROM tcomentarios GROUP BY numCliente);

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

	OPEN CUR_COMENT;

	read_loop: LOOP
    FETCH CUR_COMENT INTO P_NUMCLIENTE,P_COMENTARIO;
    IF done THEN
      LEAVE read_loop;
    END IF;
    	
		SET P_CLASIFICACION = (SELECT fc_clasificacion(P_COMENTARIO));
    	INSERT INTO tclasificacion(clasificacion,numCliente) VALUES(P_CLASIFICACION,P_NUMCLIENTE);
  	END LOOP;
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
	UPDATE tclasificacion SET clasificacion=P_CLASIFICACION WHERE numCliente=NEW.numCliente;
	
END
//
DELIMITER ;

DELIMITER //
CREATE FUNCTION fc_clasificacion(
	P_COMENTARIO VARCHAR(255)
) RETURNS VARCHAR(50) DETERMINISTIC
BEGIN
	DECLARE P_CLASIFICACION VARCHAR(50);
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
    RETURN P_CLASIFICACION;
END
//
DELIMITER ;




INSERT INTO tclientes(nombre,ap_paterno,ap_materno) VALUES
("mario","murillo","tinoco"),
("manuel","melendrez","arango"),
("jesus alberto","ramirez","rodriguez"),
("jose","gonzalez","munguia"),
("carlos","ornelas","busani");

INSERT INTO tcomentarios(comentario,numCliente) VALUES
("Lo siento pero ando un poco ocupado, nos puede llamar despues?",1),
("Lo siento tengo que preguntar a mi esposa.",2),
("Lo siento tengo que preguntar a mi esposa.",3),
("Me interezaría saber si califico o no",4),
("sí,quiero conocer el fraccionamiento",5);

INSERT INTO tcomentarios(comentario,numCliente) VALUES
("Claro,quiero visitar la casa modelo",1),
("Perdón pero no tengo tiempo",3);


