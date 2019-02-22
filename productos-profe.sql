-- Declaramos una variable de tipo decimal de 7 posiciones, 2 de las cuales son decimales.
DECLARE price_increase DECIMAL(7,2);

/*
Seleccionamos el valor redondeado con 2 decimales del (1% del precio actual) por la cantidad ordenada
y lo metemos en la variable proce_increase(INTO price-increase)
El WHERE nos indica que queremos los datos del producto que se esta insertando.
*/

SELECT ROUND(price*0.01*NEW.quantity,2)
INTO price_increase
FROM products
WHERE product_code=NEW.product_code;
-- Con este update incrementamos el precio de ese producto.
UPDATE productos
SET price=price +price_increase
WHERE product_code=NEW.product_code;

-- Ahora usamos un update con un query anidado, revisemos primero el query.
/*
 Seleccionamos de la lista de productos el que menos se ha ordenado, 
 con el requisito de que sea diferente al que se esta insertando.
*/
SELECT product_code
FROM order_lines
WHERE product_code<>NEW.product_code
GROUP BY product_code
ORDER BY SUM(quantity)
LIMIT 1;

/*
Veamos el update completo.
Actualizamos el producto de menor bajándole el 1% que ya había calculado(no el
1% del precio de este producto, sino 1% del producto ordenado, recordemos)
*/
UPDATE productos
SET price=GREATTEST(1.00,price-price_increase)
WHERE product_code=(
SELECT product_code
FROM order_lines
WHERE product_code<>NEW.product_code
GROUP BY product_code
ORDER BY SUM(quantity)
LIMIT 1
);
