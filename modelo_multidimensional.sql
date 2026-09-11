create schema Datamart;

create table Datamart.Sucursal (
	id_sucursal int primary key not null unique,
	gerente int not null);

create table Datamart.Pelicula(
	id_pelicula int primary key not null unique,
	titulo text not null
);

create table Datamart.lugar (
	id_lugar int primary key not null DEFAULT nextval('store_store_id_seq'::regclass),
	direccion text not null,
	ciudad text not null,
	pais text not null
);

create table Datamart.fecha (
	Fecha date primary key not null unique,
	dia int not null CHECK (dia >= 1 AND dia <= 31),
	mes int not null CHECK (mes >= 1 AND mes <= 12),
	anio int not null
);



create table Datamart.Facts (
	id int primary key not null DEFAULT nextval('store_store_id_seq'::regclass),
	id_lugar int not null,
	id_fecha date not null,
	id_pelicula int not null,
	id_sucursal int not null,
	FOREIGN KEY (id_lugar) REFERENCES DATAMART.lugar(ID_lugar),
	FOREIGN KEY (id_fecha) REFERENCES DATAMART.fecha(fecha),
	FOREIGN KEY (id_sucursal) REFERENCES DATAMART.sucursal(id_sucursal),
	FOREIGN KEY (id_pelicula) REFERENCES DATAMART.pelicula(id_pelicula),
	num_alquileres int,
	total_cobrado_alquiler int
);


CREATE OR REPLACE PROCEDURE InsertDateToDatamart()
LANGUAGE plpgsql
AS $$
DECLARE
    fecha_val DATE;
BEGIN
    FOR fecha_val IN SELECT DISTINCT rental_date FROM rental LOOP
        BEGIN
            INSERT INTO DATAMART.fecha (fecha, dia, mes, anio)
            VALUES (
                fecha_val,
                EXTRACT(DAY FROM fecha_val),
                EXTRACT(MONTH FROM fecha_val),
                EXTRACT(YEAR FROM fecha_val)
            )
            ON CONFLICT (fecha) DO NOTHING;
        END;
    END LOOP;
END;
$$;

call InsertDateToDatamart();




CREATE OR REPLACE PROCEDURE InsertMovieToDatamart()
LANGUAGE plpgsql
AS $$
BEGIN
insert into  DATAMART.pelicula (id_pelicula, titulo)
	select film_id, title from film
	on conflict do nothing;
END;
$$;

call InsertMovieToDatamart();


CREATE OR REPLACE PROCEDURE InsertPlaceToDatamart()
LANGUAGE plpgsql
AS $$
BEGIN
insert into  DATAMART.lugar (direccion, ciudad, pais)
	select a.address, c.city, o.country 
	from address a
	left join city c on a.city_id = c.city_id
	left join country o on o.country_id = c.country_id
	on conflict do nothing;
END;
$$;

call InsertPlaceToDatamart();


CREATE OR REPLACE PROCEDURE InsertStoreToDatamart()
LANGUAGE plpgsql
AS $$
BEGIN
insert into  DATAMART.sucursal (id_sucursal, gerente)
	select store_id, manager_staff_id from store
	on conflict do nothing;
END;
$$;

call InsertStoreToDatamart();


CREATE OR REPLACE PROCEDURE InsertFactsToDatamart()
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO DATAMART.Facts (id_lugar, id_fecha, id_pelicula, id_sucursal, num_alquileres, total_cobrado_alquiler)
    SELECT
        l.id_lugar,
        f.fecha,
        p.id_pelicula,
        s.id_sucursal,
        COUNT(r.rental_id),
        SUM(pa.amount)
    FROM Datamart.Fecha f
    LEFT JOIN rental r ON f.fecha = r.rental_date::date
    LEFT JOIN inventory i ON i.inventory_id = r.inventory_id
    LEFT JOIN Datamart.pelicula p ON p.id_pelicula = i.film_id
    LEFT JOIN Datamart.sucursal s ON i.store_id = s.id_sucursal
    LEFT JOIN store st ON st.store_id = s.id_sucursal
    LEFT JOIN address a ON a.address_id = st.address_id
    LEFT JOIN city c ON c.city_id = a.city_id
    LEFT JOIN country y ON c.country_id = y.country_id
    RIGHT JOIN Datamart.lugar l ON l.direccion = a.address AND l.ciudad = c.city AND l.pais = y.country
    JOIN payment pa ON pa.rental_id = r.rental_id
    GROUP BY
        l.id_lugar, f.fecha, p.id_pelicula, s.id_sucursal;
END;
$$;


call InsertFactsToDatamart();
