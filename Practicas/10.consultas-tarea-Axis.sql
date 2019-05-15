
-- --------
-- ---4---
-- ------

-- a)

SELECT COUNT(*),IE.ENTIDAD_FEDERATIVA 
FROM CEMABE_PERSONAL AS CP INNER JOIN INEGI_ENTIDADES AS IE ON CP.ENT=IE.id
GROUP BY IE.ENTIDAD_FEDERATIVA;

SELECT COUNT(*),estado_trab(ENT)
FROM CEMABE_PERSONAL
GROUP BY ENT;

-- b)

SELECT COUNT(*),IE.ENTIDAD_FEDERATIVA 
FROM CEMABE_PERSONAL AS CP INNER JOIN INEGI_ENTIDADES AS IE ON SUBSTR(CP.CURP,12,2)=IE.ABREVIATURA
GROUP BY IE.ENTIDAD_FEDERATIVA;

SELECT COUNT(*),estado_nac(CURP)
FROM CEMABE_PERSONAL WHERE CURP!=''
GROUP BY estado_nac(CURP);

-- c)

SELECT COUNT(*),IE.ENTIDAD_FEDERATIVA
FROM CEMABE_PERSONAL AS CP INNER JOIN INEGI_ENTIDADES AS IE ON SUBSTR(CP.CURP,12,2)=IE.ABREVIATURA
WHERE CP.ENT=(SELECT id WHERE IE.ABREVIATURA=SUBSTR(CP.CURP,12,2))
GROUP BY IE.ENTIDAD_FEDERATIVA;

-- COMPROVACIÓN
SELECT COUNT(*) FROM CEMABE_PERSONAL
WHERE CP.ENT='01' AND SUBSTR(CP.CURP,12,2)='AS';




-- d)
SELECT (SELECT ENTIDAD_FEDERATIVA FROM INEGI_ENTIDADES WHERE ABREVIATURA=SUBSTR(CURP,12,2)) AS NACIO, 
(SELECT ENTIDAD_FEDERATIVA FROM INEGI_ENTIDADES WHERE id=ENT) AS TRABAJA, COUNT(*)
FROM CEMABE_PERSONAL WHERE (SUBSTR(CURP,12,2)!='NE' AND LENGTH(TRIM(CURP))!=0)
GROUP BY (SELECT ENTIDAD_FEDERATIVA FROM INEGI_ENTIDADES WHERE ABREVIATURA=SUBSTR(CURP,12,2)), 
(SELECT ENTIDAD_FEDERATIVA FROM INEGI_ENTIDADES WHERE id=ENT);



-- e)
SELECT (SELECT ENTIDAD_FEDERATIVA FROM INEGI_ENTIDADES WHERE ABREVIATURA=SUBSTR(CURP,12,2)) AS NACIO, 
(SELECT ENTIDAD_FEDERATIVA FROM INEGI_ENTIDADES WHERE id=ENT) AS TRABAJA, COUNT(*)
FROM CEMABE_PERSONAL WHERE (SUBSTR(CURP,12,2)='NE')
GROUP BY (SELECT ENTIDAD_FEDERATIVA FROM INEGI_ENTIDADES WHERE ABREVIATURA=SUBSTR(CURP,12,2)), 
(SELECT ENTIDAD_FEDERATIVA FROM INEGI_ENTIDADES WHERE id=ENT);


-- f)
SELECT (SELECT ENTIDAD_FEDERATIVA FROM INEGI_ENTIDADES WHERE ABREVIATURA=SUBSTR(CURP,12,2)) AS NACIO, 
(SELECT ENTIDAD_FEDERATIVA FROM INEGI_ENTIDADES WHERE id=ENT) AS TRABAJA, COUNT(*)
FROM CEMABE_PERSONAL WHERE (SUBSTR(CURP,12,2)!='NE' AND LENGTH(TRIM(CURP))!=0)
GROUP BY (SELECT ENTIDAD_FEDERATIVA FROM INEGI_ENTIDADES WHERE ABREVIATURA=SUBSTR(CURP,12,2)), 
(SELECT ENTIDAD_FEDERATIVA FROM INEGI_ENTIDADES WHERE id=ENT)

UNION ALL

SELECT (SELECT ENTIDAD_FEDERATIVA FROM INEGI_ENTIDADES WHERE ABREVIATURA=SUBSTR(CURP,12,2)) AS NACIO, 
(SELECT ENTIDAD_FEDERATIVA FROM INEGI_ENTIDADES WHERE id=ENT) AS TRABAJA, COUNT(*)
FROM CEMABE_PERSONAL WHERE (SUBSTR(CURP,12,2)='NE')
GROUP BY (SELECT ENTIDAD_FEDERATIVA FROM INEGI_ENTIDADES WHERE ABREVIATURA=SUBSTR(CURP,12,2)), 
(SELECT ENTIDAD_FEDERATIVA FROM INEGI_ENTIDADES WHERE id=ENT);

-- --------
-- ---4---
-- ------

-- a)
DELIMITER //
DROP FUNCTION IF EXISTS curp_estado_nac;
CREATE FUNCTION estado_nac(CURP VARCHAR(24))RETURNS VARCHAR(100)
BEGIN
return (SELECT ENTIDAD_FEDERATIVA FROM INEGI_ENTIDADES WHERE ABREVIATURA=(SUBSTR(CURP,12,2)));
END 
//
DELIMITER ;


-- b)

DELIMITER //
DROP FUNCTION IF EXISTS estado_trab;
CREATE FUNCTION estado_trab(ENT VARCHAR(2))RETURNS VARCHAR(100)
BEGIN
return (SELECT ENTIDAD_FEDERATIVA FROM INEGI_ENTIDADES WHERE id=ENT);
END 
//
DELIMITER ;


