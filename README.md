# 🎬 CineMart BI — Replicación y Análisis de Datos para Alquiler de Películas

Proyecto #2 del curso **Base de Datos II** — Escuela de Ingeniería en Computación, Sede Interuniversitaria de Alajuela, TEC.
Prof. Alberto Shum Chan · Semestre I, 2025

## 📌 Descripción

**CineMart BI** es un proyecto de inteligencia de negocio construido sobre la base de datos transaccional de alquiler de películas **dvdrental** (PostgreSQL Sample Database). El proyecto separa la carga transaccional (OLTP) de la carga analítica (OLAP) mediante un ambiente de **replicación física** (streaming replication) y construye, sobre la instancia réplica, un **datamart con modelo estrella** que alimenta un **dashboard en Tableau** para apoyar la toma de decisiones sobre alquileres, ingresos, películas, actores y sucursales.

El proyecto cubre cuatro grandes componentes:

1. **Procedimientos almacenados y seguridad** sobre el sistema transaccional (instancia maestra).
2. **Replicación** maestro–esclavo de PostgreSQL (sin contenedores).
3. **Modelo multidimensional (datamart)** construido en la instancia réplica.
4. **Dashboard analítico en Tableau** sobre el modelo estrella.

## 🎯 Objetivos

- Implementar un ambiente de replicación que separe el modelo multidimensional de la instancia transaccional.
- Diseñar e implementar un datamart basado en un modelo multidimensional (esquema estrella).
- Alimentar el datamart desde la base de datos transaccional replicada.
- Diseñar un dashboard en Tableau que resuma la información relevante del negocio.

## 🗂️ Estructura del repositorio

```
.
├── Proyectos_BD2_-_Proyecto_2_-_Replicacion_y_BI.pdf   # Enunciado del proyecto
├── Replicación.md                                       # Guía paso a paso de la replicación
├── Procedimientos_y_seguridad.sql                       # Procedimientos, funciones, roles y usuarios
├── modelo_multidimensional.sql                          # Esquema estrella (datamart) + ETL
├── consultas.sql                                        # Consultas analíticas de apoyo al dashboard
└── README.md                                            # Este archivo
```

## 🧱 1. Base de datos transaccional (instancia maestra)

Se usa la base de datos de ejemplo **dvdrental** de PostgreSQL, compuesta por 15 tablas (`actor`, `film`, `film_actor`, `category`, `film_category`, `store`, `inventory`, `rental`, `payment`, `staff`, `customer`, `address`, `city`, `country`, entre otras) que modelan el alquiler de películas en distintas sucursales.

### Procedimientos y funciones (`Procedimientos_y_seguridad.sql`)

| Objeto | Tipo | Descripción |
|---|---|---|
| `insertar_cliente` | Procedimiento | Inserta un nuevo cliente validando que la sucursal (`store_id`) exista. |
| `registrar_alquiler` | Procedimiento | Registra un alquiler asociando inventario, cliente (buscado por nombre/apellido) y empleado. |
| `registrar_devolucion` | Procedimiento | Actualiza la fecha de devolución de un alquiler existente. |
| `buscar_pelicula` | Función | Retorna el id, descripción y año de lanzamiento de una película por título. |

Todos corren con `SECURITY DEFINER` bajo el dueño `video`.

### Seguridad

- **Rol `EMP`**: puede ejecutar `registrar_alquiler`, `registrar_devolucion` y `buscar_pelicula`.
- **Rol `ADMIN`** (hereda de `EMP`): además puede ejecutar `insertar_cliente`.
- **Usuario `video`** (`NOLOGIN`): dueño de todas las tablas y procedimientos.
- **Usuario `empleado1`**: con rol `EMP`.
- **Usuario `administrador1`**: con rol `ADMIN`.

## 🔁 2. Replicación (`Replicación.md`)

Se implementa **replicación física en streaming** entre dos instancias de PostgreSQL en la misma estación de trabajo (sin Docker):

1. Crear el directorio de la réplica.
2. Configurar `postgresql.conf` del maestro (`wal_level = replica`, `max_wal_senders`, `wal_keep_size`, `archive_mode`).
3. Configurar `pg_hba.conf` del maestro para permitir conexiones de replicación.
4. Reiniciar el servidor maestro.
5. Clonar la base con `pg_basebackup -R` para crear la réplica ya configurada como standby.
6. Ajustar `postgresql.conf` de la réplica (puerto distinto, `hot_standby = on`).
7. Iniciar la réplica y registrarla en pgAdmin4 como un nuevo servidor.

**Verificación:**
- En el maestro: `SELECT * FROM pg_stat_replication;`
- En la réplica: `SELECT pg_is_in_recovery();` (debe devolver `true`)

La réplica es de **solo lectura** y se mantiene sincronizada en tiempo real con el maestro; sobre ella se construye el datamart.

## 📊 3. Modelo multidimensional / Datamart (`modelo_multidimensional.sql`)

Esquema estrella creado en el schema `Datamart`, sobre la instancia réplica:

**Dimensiones**
- `Datamart.Pelicula` — jerarquía película → categoría → actores.
- `Datamart.lugar` — jerarquía dirección → ciudad → país.
- `Datamart.fecha` — jerarquía día → mes → año.
- `Datamart.Sucursal` — sucursal y gerente.

**Tabla de hechos**
- `Datamart.Facts`: llaves foráneas a las 4 dimensiones, y las medidas:
  - `num_alquileres` — número de alquileres.
  - `total_cobrado_alquiler` — monto total cobrado por alquileres.

**Procedimientos de carga (ETL)**
| Procedimiento | Función |
|---|---|
| `InsertDateToDatamart` | Carga las fechas distintas de `rental` a `Datamart.fecha`. |
| `InsertMovieToDatamart` | Carga las películas desde `film`. |
| `InsertPlaceToDatamart` | Carga direcciones/ciudad/país desde `address`, `city`, `country`. |
| `InsertStoreToDatamart` | Carga las sucursales desde `store`. |
| `InsertFactsToDatamart` | Calcula y carga la tabla de hechos agregando alquileres y pagos por lugar, fecha, película y sucursal. |

## 🔍 4. Consultas analíticas (`consultas.sql`)

Consultas de soporte a los reportes del dashboard, entre ellas:

- Total de alquileres y monto cobrado por sucursal y mes.
- Total cobrado por alquiler agrupado por año y mes.
- Monto total por año para los 10 actores con más alquileres (usando CTEs `actor_rentals` y `top_actors`).

## 📈 5. Dashboard (Tableau)

El dashboard sobre el modelo estrella debe resolver:

1. Número de alquileres y monto cobrado por mes para una sucursal seleccionable (todos los años).
2. Montos cobrados por mes para un año seleccionable.
3. Número de alquileres y monto cobrado por año para una categoría de película seleccionable.
4. Montos totales por año (o todos los años) para los 10 actores con más alquileres.
5. Mapa de ciudades con el monto total de alquiler por año, representado por el tamaño del punto.

*(Los archivos `.twbx`/`.twb` de Tableau se entregan por separado junto con este repositorio.)*

## ⚙️ Cómo reproducir el ambiente

1. Restaurar `dvdrental` en la instancia maestra (`pg_restore`).
2. Ejecutar `Procedimientos_y_seguridad.sql` sobre la instancia maestra.
3. Seguir los pasos de `Replicación.md` para levantar la instancia réplica.
4. Ejecutar `modelo_multidimensional.sql` sobre la instancia réplica para crear el datamart y cargarlo.
5. Ejecutar las consultas de `consultas.sql` para validar los datos.
6. Conectar Tableau a la instancia réplica (schema `Datamart`) y construir/abrir el dashboard.

## 👥 Créditos

Proyecto elaborado para el curso **Base de Datos II**, TEC, Semestre I 2025, en grupos de 3 personas.
