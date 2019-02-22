/*
Primero que nada para este problema se modificaron todo aquellos
valores en donde el campo NUM_PLAZAS estuviera vaío y se coloco un 0
en su lugar. Para lo anterior se utilizo la siguiente consulta...
UPDATE cemabe_personal SET NUM_PLAZAS='0' WHERE LENGTH(TRIM(NUM_PLAZAS))=0;

A parte se realizó una modificación del tipo de dato sobre el mismo campo de 
VARCHAR a INT.
*/


-- Tabla para auditar cada que se realice un incremento de plazas
DROP TABLE IF EXISTS cemabePersonal_audit;
CREATE TABLE cemabePersonal_audit(
	audit_date TIMESTAMP,
    audit_user VARCHAR(40),
    audit_action ENUM('update'),
    audit_field ENUM('UP','DOWN'),
    ID_PERSONA VARCHAR(7),
    CURP VARCHAR(24),
    CLAVE_CT VARCHAR(23),
    NUM_PLAZAS_ANT INT(11),
    CANTIDAD_INCRE INT(11)
);




-- Este trigger monitorea los cambios realizados en el numero de plazas de las personas
-- y limita a que las personas solo puedan subir en 5 el numero de plazas por año.
DELIMITER //
DROP TRIGGER IF EXISTS tg_cemabePeronal_BU;
CREATE TRIGGER tg_cemabePeronal_BU
BEFORE UPDATE ON cemabe_personal
FOR EACH ROW
BEGIN
	DECLARE P_FIELD VARCHAR(4);
	DECLARE P_DIFF INT(11) DEFAULT 0;
	DECLARE P_TOTAL INT(11);

	-- Obtenemos el total ncrementos que se han registrado en el ultimo año.
	SET P_TOTAL=(SELECT SUM(CANTIDAD_INCRE) 
		FROM cemabePersonal_audit 
		WHERE ID_PERSONA=OLD.ID_PERSONA
		AND CLAVE_CT=OLD.CLAVE_CT
		AND CURP = OLD.CURP
		AND audit_field='UP'
		AND YEAR(audit_date)=YEAR(CURRENT_DATE())
		);

	-- calculamos la cantidad que se esta intentando incrementar.
	SET P_DIFF= NEW.NUM_PLAZAS-OLD.NUM_PLAZAS;
	

	IF P_TOTAL>5 THEN
		SIGNAL SQLSTATE '46011'
		SET MESSAGE_TEXT='Solo se pueden incrementar 5 niveles por año.';
	END IF;

	IF P_DIFF>5 THEN
		SIGNAL SQLSTATE '46011'
		SET MESSAGE_TEXT='Solo se pueden incrementar 5 niveles por año.';
	END IF;

	IF P_DIFF>0 THEN
		IF (P_TOTAL+P_DIFF)>5 THEN
			SIGNAL SQLSTATE '46011'
			SET MESSAGE_TEXT='Solo se pueden incrementar 5 niveles por año.';
		END IF;
		SET P_FIELD='UP';
	ELSEIF P_DIFF<0 THEN
		SET P_FIELD='DOWN';
		SET P_DIFF=(P_DIFF*(-1));
	ELSE
		SET P_FIELD='NOTCH';
	END IF;

	IF P_DIFF!='NOTCH' THEN
		-- Almacenamos el cambio en la tabla de auditoria.
		INSERT INTO cemabePersonal_audit(audit_user,audit_action,audit_field,ID_PERSONA,CURP,CLAVE_CT,NUM_PLAZAS_ANT,CANTIDAD_INCRE) 
		VALUES(CURRENT_USER(),'update',P_FIELD,OLD.ID_PERSONA,OLD.CURP,OLD.CLAVE_CT,OLD.NUM_PLAZAS,P_DIFF);
	END IF;

END
//
DELIMITER ;




-- Procedimiento para subir o bajar el numero
-- de plazas de un determinado maestro.
DELIMITER //
DROP PROCEDURE IF EXISTS sp_subirPlazas;
CREATE PROCEDURE sp_subirPlazas(
	IN PAR_CURP VARCHAR(255),
	IN PAR_ID_PERSONA VARCHAR(255),
	IN PAR_CLAVE_CT VARCHAR(255),
	IN PAR_PLAZAS INT(11)
)
BEGIN
	IF PAR_PLAZAS>99 THEN
		SIGNAL SQLSTATE '46010'
		SET MESSAGE_TEXT='El N° plazas máximo es 99.';
	END IF;

	UPDATE cemabe_personal SET NUM_PLAZAS=PAR_PLAZAS 
	WHERE ID_PERSONA=PAR_ID_PERSONA
	AND CLAVE_CT=PAR_CLAVE_CT
	AND CURP=PAR_CURP;


END
//
DELIMITER ;


-- La siguiente vista lo que nos devuelve son las personas a las cuales
-- en el ultimo año se les subio el numero de plazas.
-- Con esta tabla podemos sacar alguna informacion como por ejemplo
-- las edades de las personas que suben el numero de plazas.
DROP VIEW vw_subirPlaza_UltA;
CREATE VIEW vw_subirPlaza_UltA AS 
SELECT DISTINCT cp.ID_PERSONA, cp.CLAVE_CT, cp.CURP,cp.NOMBRE_MAE,cp.AP_MATERNO,cp.AP_PATERNO,cp.FECHA_NAC,cp.EDAD,cp.NUM_PLAZAS
FROM  cemabePersonal_audit as cpa 
LEFT JOIN cemabe_personal as cp ON cpa.ID_PERSONA=cp.ID_PERSONA 
WHERE cpa.audit_field='UP' AND YEAR(cpa.audit_date)=YEAR(CURRENT_DATE()) GROUP BY cp.ID_PERSONA;