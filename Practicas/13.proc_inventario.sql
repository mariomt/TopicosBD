
/*
USUARIO DE LA BD:
CREATE USER IF NOT EXISTS inventario@localhost;
GRANT EXCECUTE ON INVENTORY.* TO inventario@localhost; 
GRANT INSERT ON INVENTORY.SUPPLIERS TO inventario@localhost;
GRANT INSERT ON INVENTORY.PRODUCTS TO inventario@localhost;
GRANT INSERT ON INVENTORY.BRANDS TO inventario@localhost;
GRANT SELECT ON INVENTORY.* TO inventory@localhost;
GRANT UPDATE ON INVENTORY.BRANDS TO inventory@localhost;
GRANT UPDATE ON INVENTORY.SUPPLIERS TO inventory@localhost;
*/

/*---------------------------------*/
/* -----------VENTAS--------------*/
/*-------------------------------*/
-- NOTA: Los siguientes procedimientos
-- deben realizarse dentro de la misma
-- conexion ya que se ocupan variables
-- creadas en la sesion del usuario.
/*
Procedimiento para registrar una venta
y que al final me devuelva el id de la
de la venta actual para poder ingresar
descripciones a la venta.
*/

DELIMITER //
DROP PROCEDURE IF EXISTS sp_OpenSale;
CREATE PROCEDURE sp_OpenSale(
	P_ID_SALE INT(11)
)
BEGIN
	DECLARE V_FECHA TIMESTAMP DEFAULT NOW();
	IF(P_ID_SALE IS NULL OR P_ID_SALE=0) THEN
		INSERT INTO SALES(USER,`DATE`) VALUES(CURRENT_USER(),V_FECHA);
		SELECT ID_SALE INTO @id_Sale FROM SALES WHERE USER=CURRENT_USER() AND `DATE`=V_FECHA;
	ELSE
		IF NOT EXISTS(SELECT ID_SALE FROM SALES WHERE ID_SALE=P_ID_SALE)THEN
			SIGNAL SQLSTATE '46003'
			SET MESSAGE_TEXT='Sale Not Found';
		END IF;
		SELECT ID_SALE INTO @id_Sale FROM SALES WHERE ID_SALE=P_ID_SALE;
	END IF; 
END
//
DELIMITER ;

/*
Agregar productos a la venta
actual.
*/
DELIMITER //
DROP PROCEDURE IF EXISTS sp_AddProductSale;
CREATE PROCEDURE sp_AddProductSale(
	P_ID_PRODUCT INT(11),
	P_QUANTITY INT(11)
)
BEGIN
	DECLARE V_MESSAGE VARCHAR(20);
	IF (@id_Sale IS NULL)THEN
		SIGNAL SQLSTATE '46003'
		SET MESSAGE_TEXT='You have not opened a sale.';
	END IF;
	SELECT QTTY_STOCK INTO @qtty FROM PRODUCTS WHERE ID_PRODUCT=P_ID_PRODUCT;
	IF @qtty=0 THEN
		SIGNAL SQLSTATE '46004'
		SET MESSAGE_TEXT='Out of stock.';
	END IF;

	IF (P_QUANTITY > @qtty)THEN
		SET V_MESSAGE = CONCAT('Only', @qtty,' products left in the stock');
		SIGNAL SQLSTATE '46004'
		SET MESSAGE_TEXT=V_MESSAGE;
	END IF;

	SELECT PRICE INTO @var_price FROM PRODUCTS WHERE ID_PRODUCT=P_ID_PRODUCT;

	INSERT INTO SALES_DESCRIPTION(ID_SALE,ID_PRODUCT,QUANTITY,PRICE)
	VALUES(@id_Sale,P_ID_PRODUCT,P_QUANTITY,@var_price);
END
//
DELIMITER ;

/*
Remover un producto de la venta
actual.
*/
DELIMITER //
DROP PROCEDURE IF EXISTS sp_removeProductSale;
CREATE PROCEDURE sp_removeProductSale(
	P_ID_PRODUCT INT(11)
)
BEGIN
	DELETE FROM SALES_DESCRIPTION WHERE ID_PRODUCT=P_ID_PRODUCT;
END
//
DELIMITER ;

/*
Terminar la venta
*/
DELIMITER //
DROP PROCEDURE IF EXISTS sp_ClosedSale;
CREATE PROCEDURE sp_ClosedSale()
BEGIN
	IF NOT EXISTS(SELECT ID_SALE FROM SALES_DESCRIPTION WHERE ID_SALE=@id_Sale)THEN
		DELETE FROM SALES WHERE ID_SALE=@id_Sale;
	END IF;
	SELECT CONCAT('$',fc_totalSale(@id_Sale)) AS TOTAL;
	SET @id_Sale = NULL;
END
//
DELIMITER ;

/*---------------------------------*/
/* -----------COMPRAS-------------*/
/*-------------------------------*/

/*
Iniciar una nueva entrada de
productos.
*/
DELIMITER //
DROP PROCEDURE IF EXISTS sp_OpenSupply;
CREATE PROCEDURE sp_OpenSupply(
	P_ID_SUPPLY INT(11),
	P_ID_SUPPLIER INT(11)
)
BEGIN
	DECLARE V_FECHA TIMESTAMP DEFAULT NOW();

	

	IF(P_ID_SUPPLY IS NULL OR P_ID_SUPPLY=0) THEN
		IF NOT EXISTS(SELECT ID_SUPPLIER FROM SUPPLIERS WHERE ID_SUPPLIER=P_ID_SUPPLIER)THEN
			SIGNAL SQLSTATE '46003'
			SET MESSAGE_TEXT='Suppier Not Found';
		END IF;
		INSERT INTO SUPPLY(ID_SUPPLIER,USER,`DATE`) VALUES(P_ID_SUPPLIER,CURRENT_USER(),V_FECHA);
		SELECT ID_SUPPLY INTO @id_Supply FROM SUPPLY WHERE ID_SUPPLIER=P_ID_SUPPLIER AND USER=CURRENT_USER() AND `DATE`=V_FECHA;
	ELSE
		IF NOT EXISTS(SELECT ID_SUPPLY FROM SUPPLY WHERE ID_SUPPLY=P_ID_SUPPLY)THEN
			SIGNAL SQLSTATE '46003'
			SET MESSAGE_TEXT='Sale Not Found';
		END IF;
		SELECT ID_SUPPLY INTO @id_Supply FROM SUPPLY WHERE ID_SUPPLY=P_ID_SUPPLY;
	END IF; 
END
//
DELIMITER ;

/*
Agregar productos a la entrada
actual.
*/
DELIMITER //
DROP PROCEDURE IF EXISTS sp_AddProductSupply;
CREATE PROCEDURE sp_AddProductSupply(
	P_ID_PRODUCT INT(11),
	P_QUANTITY INT(11),
	P_PRICE DOUBLE(20,2)
)
BEGIN
	IF (@id_Supply IS NULL)THEN
		SIGNAL SQLSTATE '46003'
		SET MESSAGE_TEXT='You have not opened a supply.';
	END IF;
	INSERT INTO SUPPLY_DESCRIPTION(ID_SUPPLY,ID_PRODUCT,QUANTITY,PRICE)
	VALUES(@id_Supply,P_ID_PRODUCT,P_QUANTITY,P_PRICE);
END
//
DELIMITER ;

/*
Remover un producto de la entrada
actual.
*/
DELIMITER //
DROP PROCEDURE IF EXISTS sp_removeProductSupply;
CREATE PROCEDURE sp_removeProductSupply(
	P_ID_PRODUCT INT(11)
)
BEGIN
	DELETE FROM SUPPLY_DESCRIPTION WHERE ID_PRODUCT=P_ID_PRODUCT;
END
//
DELIMITER ;

/*
Terminar la entrada
*/
DELIMITER //
DROP PROCEDURE IF EXISTS sp_ClosedSupply;
CREATE PROCEDURE sp_ClosedSupply()
BEGIN
	IF NOT EXISTS(SELECT ID_SUPPLY FROM SUPPLY_DESCRIPTION WHERE ID_SUPPLY=@id_Supply)THEN
		DELETE FROM SUPPLY WHERE ID_SALE=@id_Supply;
	END IF;
	SELECT CONCAT('TOTAL: $',fc_totalSupply(@id_Supply));
	SET @id_Supply = NULL;
END
//
DELIMITER ;
/*---------------------------------*/
/* -----------FUNCTIONS-----------*/
/*-------------------------------*/

-- Objtener el TOTAL de una venta.
DELIMITER //

-- Obtener el TOTAL de una Compra.
DELIMITER //
DROP FUNCTION IF EXISTS fc_totalSupply;
CREATE FUNCTION fc_totalSupply(P_ID_SUPPLY INT(11))RETURNS DOUBLE
BEGIN
	-- Declaracion de variables
	DECLARE done INT DEFAULT FALSE;
	DECLARE V_TOTAL DOUBLE DEFAULT 0;
	DECLARE V_ID_PRODUCT INT(11);
	DECLARE V_PRICE DOUBLE;
	DECLARE V_CANT INT;
	
	-- Declarar el cursor con los productos y los precios
	DECLARE CUR_PRODUCTS CURSOR FOR 
	SELECT ID_PRODUCT,PRICE,QUANTITY
	FROM SUPPLY_DESCRIPTION
	WHERE ID_SUPPLY=P_ID_SUPPLY;


	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

	-- Abrir cursor
	OPEN CUR_PRODUCTS;

	-- Iniciar ciclo
	read_loop: LOOP
		FETCH CUR_PRODUCTS INTO V_ID_PRODUCT,V_PRICE, V_CANT;
		-- Salir del siclo si ya no trae registros el cursor.
		IF done THEN
	      LEAVE read_loop;
	    END IF;

	    -- Sumar el costo del producto actual.
	    SET V_TOTAL = V_TOTAL + (V_PRICE*V_CANT);

	END LOOP;
    CLOSE CUR_PRODUCTS;

    RETURN V_TOTAL;
END
//
DELIMITER ;


/*---------------------------------*/
/* -----------TRIGGERS------------*/
/*-------------------------------*/
/*
Trigger para que cuando se realice un insert
de un producto este se inicialice en 0
*/
DELIMITER //
DROP TRIGGER IF EXISTS tg_products_BI;
CREATE TRIGGER tg_Products_BI BEFORE INSERT 
ON PRODUCTS FOR EACH ROW
BEGIN 
	SET NEW.QTTY_STOCK=0;
END
//
DELIMITER ;

/*
Trigger para cuando se realice una descripcion 
de ventas se actualicen las cantidades del stock
*/
DELIMITER //
DROP TRIGGER IF EXISTS tg_SalesDescription_BI;
CREATE TRIGGER tg_SalesDescription_BI AFTER INSERT 
ON SALES_DESCRIPTION FOR EACH ROW
BEGIN
	UPDATE PRODUCTS SET QTTY_STOCK=(QTTY_STOCK-NEW.QUANTITY) WHERE ID_PRODUCT=NEW.ID_PRODUCT;
END
//
DELIMITER ;


/*
Trigger para cuando se realice una 
descripcion en entradade producto, se 
actualicen las cantidades del stock.
*/
DELIMITER //
DROP TRIGGER IF EXISTS tg_SupplyDescription_BI;
CREATE TRIGGER tg_SupplyDescription_BI AFTER INSERT 
ON SUPPLY_DESCRIPTION FOR EACH ROW
BEGIN
	UPDATE PRODUCTS SET QTTY_STOCK=(QTTY_STOCK+NEW.QUANTITY) WHERE ID_PRODUCT=NEW.ID_PRODUCT;
END
//
DELIMITER ;


/*---------------------------------*/
/* -------------VIEWS-------------*/
/*-------------------------------*/

/*
Vista para obtener los productos que
requieren ser solicitados al proveedor.
*/
DELIMITER //
DROP VIEW IF EXISTS vw_reorden;
CREATE VIEW vw_reorden AS
SELECT P.ID_PRODUCT,P.NAME,B.NAME AS BRAND,P.QTTY_STOCK
FROM PRODUCTS P INNER JOIN BRANDS B ON P.ID_BRAND=B.ID_BRAND
WHERE P.QTTY_STOCK<=P.REORDER;
//
DELIMITER ;