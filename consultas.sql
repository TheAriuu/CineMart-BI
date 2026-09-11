SELECT 
    f.id_sucursal,
    fe.mes,
    SUM(f.num_alquileres) AS total_alquileres,
    SUM(f.total_cobrado_alquiler) AS total_monto_cobrado
FROM 
    datamart.facts f
JOIN 
    datamart.fecha fe ON f.id_fecha = fe.fecha
GROUP BY 
    f.id_sucursal,
    fe.mes
ORDER BY 
    f.id_sucursal,
    fe.mes;



SELECT
    f.anio AS Año,
    f.mes AS Mes,
    SUM(fa.total_cobrado_alquiler) AS Total_Alquiler
FROM
    datamart.facts fa
INNER JOIN
    datamart.fecha f ON fa.id_fecha = f.fecha
GROUP BY
    f.anio, f.mes
ORDER BY
    f.anio, f.mes;




WITH actor_rentals AS (
    SELECT 
        a.actor_id,
        CONCAT(a.first_name, ' ', a.last_name) AS actor_name,
        EXTRACT(YEAR FROM r.rental_date) AS rental_year,
        COUNT(r.rental_id) AS rental_count,
        SUM(p.amount) AS total_amount
    FROM 
        actor a
        JOIN film_actor fa ON a.actor_id = fa.actor_id
        JOIN film f ON fa.film_id = f.film_id
        JOIN inventory i ON f.film_id = i.film_id
        JOIN rental r ON i.inventory_id = r.inventory_id
        JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY 
        a.actor_id, actor_name, rental_year
),

top_actors AS (
    SELECT 
        actor_id,
        actor_name
    FROM 
        actor_rentals
    GROUP BY 
        actor_id, actor_name
    ORDER BY 
        SUM(rental_count) DESC
    LIMIT 10
)

SELECT 
    ar.rental_year AS "Año",
    ta.actor_name AS "Actor",
    ar.total_amount AS "Monto Total"
FROM 
    actor_rentals ar
    JOIN top_actors ta ON ar.actor_id = ta.actor_id
ORDER BY 
    ar.rental_year, ar.total_amount DESC
