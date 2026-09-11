-- 1.1 Procedimientos y funciones
CREATE OR REPLACE PROCEDURE insertar_cliente(store_id INT, nombre TEXT, apellido TEXT, email TEXT, address_id INT, active INT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM store s WHERE s.store_id = insertar_cliente.store_id) THEN
        INSERT INTO customer(store_id, first_name, last_name, email, address_id, active)
        VALUES (insertar_cliente.store_id, nombre, apellido, email, address_id, active);
        RAISE NOTICE 'El cliente se ha insertado correctamente :)';
    ELSE
        RAISE NOTICE 'No se pudo ingresar el cliente: store_id % no existe.', store_id;
    END IF;
END;
$$;



CREATE OR REPLACE PROCEDURE registrar_alquiler(inventory_id int, nombre text, apellido text, staff_id int)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    cust_id int;
BEGIN
	select customer_id into cust_id from customer where first_name = nombre and last_name = apellido;
    INSERT INTO rental(inventory_id, customer_id, staff_id)
    VALUES (inventory_id, cust_id, staff_id);
	RAISE NOTICE 'El alquiler se ha insertado correctamente :)';
EXCEPTION 
	WHEN OTHERS THEN
		RAISE NOTICE 'Alguno de los datos ingresado es incorrecto';
END;
$$;


CREATE OR REPLACE PROCEDURE registrar_devolucion(rental_id int, return_date date)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE rental
    SET return_date = return_date
    WHERE rental.rental_id = rental_id;
	RAISE NOTICE 'La devolución se ha insertado correctamente :)';
EXCEPTION 
	WHEN OTHERS THEN
		RAISE NOTICE 'No existe el rental id ingresado';
END;
$$;



CREATE OR REPLACE FUNCTION buscar_pelicula(titulo TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    mensaje TEXT;
    id1 INT;
    descr TEXT;
    anio INT;
BEGIN
    SELECT film_id, description, release_year
    INTO id1, descr, anio
    FROM film
    WHERE title = titulo;

    mensaje := 'El id de este film es: ' || id1 || ', ' || descr || ', su año de lanzamiento es: ' || anio;

    RETURN mensaje;
EXCEPTION 
	WHEN OTHERS THEN
		RAISE NOTICE 'No existe la película';
END;
$$;

-- 1.2 Seguridad
create role EMP;
grant execute on procedure registrar_alquiler to EMP;
grant execute on procedure registrar_devolucion to EMP;
grant execute on function buscar_pelicula to EMP;

CREATE ROLE ADMIN IN ROLE EMP;

CREATE ROLE video NOLOGIN;

SET ROLE video;

GRANT EXECUTE ON PROCEDURE insertar_cliente TO ADMIN;

CREATE USER empleado1 PASSWORD 'empleado1234';
GRANT EMP TO empleado1;

CREATE USER administrador1 PASSWORD 'admin1234';
GRANT ADMIN TO administrador1;

ALTER TABLE actor OWNER TO video;
ALTER TABLE address OWNER TO video;
ALTER TABLE category OWNER TO video;
ALTER TABLE city OWNER TO video;
ALTER TABLE country OWNER TO video;
ALTER TABLE customer OWNER TO video;
ALTER TABLE film OWNER TO video;
ALTER TABLE film_actor OWNER TO video;
ALTER TABLE film_category OWNER TO video;
ALTER TABLE inventory OWNER TO video;
ALTER TABLE language OWNER TO video;
ALTER TABLE payment OWNER TO video;
ALTER TABLE rental OWNER TO video;
ALTER TABLE staff OWNER TO video;
ALTER TABLE store OWNER TO video;

ALTER PROCEDURE insertar_cliente(INT, TEXT, TEXT, TEXT, INT, INT) OWNER TO video;
ALTER PROCEDURE registrar_alquiler(INT, TEXT, TEXT, INT) OWNER TO video;
ALTER PROCEDURE registrar_devolucion(INT, DATE) OWNER TO video;
ALTER FUNCTION buscar_pelicula(TEXT) OWNER TO video;
