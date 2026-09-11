# PASOS PARA LA REPLICACIÓN:

## 1. Crear un directorio para almacenar la réplica:
```bash
mkdir C:\PostgreSQL\replica
```

## 2. Buscar el archivo `postgresql.conf` en `C:\Program Files\PostgreSQL\17\data` y modificar las siguientes líneas del archivo:
```conf
wal_level = replica
max_wal_senders = 5
wal_keep_size = 64MB
archive_mode = on
listen_addresses = 'localhost'
```

## 3. Buscar el archivo `pg_hba.conf` en el mismo directorio y modificar la siguiente línea:
```conf
host replication all 127.0.0.1/32 trust
```

## 4. Reiniciar el servidor maestro
```bash
pg_ctl restart -D "C:\Program Files\PostgreSQL\16\data"
```
En caso de que dé error, utilizar este comando:
```bash
pg_ctl -D "C:\Program Files\PostgreSQL\16\data" start
```
y posteriormente volver a correr el comando de arriba.

## 5. Crear la réplica:
```bash
pg_basebackup -h localhost -p 5432 -U postgres -D "C:\PostgreSQL\replica" -Fp -Xs -P -R
```

## 6. Buscar el archivo `postgresql.conf` en `C:\PostgreSQL\replica` y modificar las siguientes líneas:
```conf
port = 5433
hot_standby = on
listen_addresses = 'localhost'
```

## 7. Iniciar la réplica:
```bash
pg_ctl -D "C:\PostgreSQL\replica" -o "-p 5433" start
```

## ✅ PARA VERIFICAR QUE LA RÉPLICA EXISTE Y FUNCIONA HAY QUE CREAR UN NUEVO SERVIDOR EN pgAdmin4:
1. Click derecho en **"Servers" -> Create -> Server**
2. En la pestaña **General** ponerle nombre al servidor: _Ejemplo_: `Replica - 5433`
3. En la pestaña **Connection** específicar lo siguiente:
```
Host name/address:     localhost  
Port:                  5433  
Maintenance database:  dvdrental  
Username:              postgres  
Password:              ***** (marcar "Save Password")  
```
4. Hacer click en **Save**.

## PRUEBAS:
- En pgAdmin se puede conectar al servidor maestro (puerto 5432) y abrir una pestaña de query tool para ejecutar la siguiente consulta y ver el estado de la réplica: `SELECT * FROM pg_stat_replication;`
- En la réplica (puerto 5433) se puede ejecutar la siguiente consulta y si devuelve true, significa que esa instancia está en modo réplica: `SELECT pg_is_in_recovery();
`

### ℹ️ Notas
- Al conectarse a este nuevo servidor se podrá observar que contiene la base de datos dvdrental con sus respectivas tablas.
- La réplica es solo para lectura, no se pueden hacer operaciones DDL como create, insert y updata.
- La réplica también se actualiza en tiempo real con los cambios del servidor maestro.
