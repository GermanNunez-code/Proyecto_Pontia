/*
______           _   _        ______             _      _____  _       
| ___ \         | | (_)       | ___ \           | |    /  ___|| |      
| |_/ /__  _ __ | |_ _  __ _  | |_/ / __ _ _ __ | | __ \ `--. | |      
|  __/ _ \| '_ \| __| |/ _` | | ___ \/ _` | '_ \| |/ /  `--. \| |      
| | | (_) | | | | |_| | (_| | | |_/ / (_| | | | |   <  /\__/ /| |_____ 
\_|  \___/|_| |_|\__|_|\__,_| \____/ \__,_|_| |_|_|\_\ \____(_)_____(_)

*/


-- Observaciones importantes sobre el tipo de datos:
/*
- Los clientes aparecen dos veces por cada transacción, es decir, uno como emisor (origen) y otro como receptor (destino).
- En cada transacción se guardan los balances previos y posteriores tanto del emisor como del receptor.
- Existen campos que son propiedades intrínsecas de la transacción: t_id, tiempo, tipo, cuantia, alarma_fraude, es_fraude.
	+ Una propiedad intrínseca es una propiedad específica que existe dentro del sujeto
- El campo tiempo se representa como un número entero que indica las horas transcurridas desde un instante de referencia.
- El tipo de transacción se puede gestionar con una tabla extra que liste los  tipos posibles y, dentro de la tabla de transacciones, usar una
clave foránea.
*/


# Eliminamos la base de datos si estuviera creada previamente

DROP DATABASE IF EXISTS pontia_bank;

# Creamos la base de datos

CREATE SCHEMA pontia_bank;
USE pontia_bank;

# Aumentamos el tiepo máximo de ejecución

SET SESSION max_execution_time = 200000;

-- 1. Tabla clientes

CREATE TABLE accounts (
	account_id VARCHAR(20) PRIMARY KEY -- IDs de la cuenta de clientes (ej: C1178022746, C842884964, etc.)
);

# account_id es la clave primaria que usaremos para referenciar al cliente desde la tabla de transacciones.

-- 2. Tabla de tipos_transaccion

/*Los tipos de transacciones son:
	· CASH OUT
    · PAYMENT
    · CASH_IN
    · TRANSFER
    · DEBIT
*/

CREATE TABLE tipos_transaccion (
	tipo_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_tipo VARCHAR(50) UNIQUE NOT NULL
);


-- 3. Tabla transacciones

CREATE TABLE transacciones (
	t_id BIGINT PRIMARY KEY, -- ID único de la transacción (t_id)
    origen_id VARCHAR(20),  -- ID de cuenta origen (FK → accounts)
    destino_id VARCHAR(20), -- ID de cuenta destino (FK → accounts)
    cuantia DECIMAL(15,2) NOT NULL, -- Cuantía transferida
    tipo_id INT, -- FK → tipo_transaccion
    es_fraude BOOLEAN DEFAULT 0, -- 0 = No fraude, 1 = Fraude
    alerta_fraude VARCHAR(50) NOT NULL, -- "Detectado_fraude en caso de que salte la alarma y "No_detectado_fraude" en caso contrario
    hora_transaccion DATETIME NOT NULL, -- Fecha y hora de la transacción
	balance_prev_or DECIMAL(15,2) NOT NULL,  -- Balance antes en la cuenta origen
    balance_post_or DECIMAL(15,2) NOT NULL,  -- Balance después en la cuenta origen
    balance_prev_des DECIMAL(15,2) NOT NULL, -- Balance antes en la cuenta destino
    balance_post_des DECIMAL(15,2) NOT NULL, -- Balance después en la cuenta destino
    
    # Claves foráneas
    FOREIGN KEY (origen_id) REFERENCES accounts(account_id),
    FOREIGN KEY (destino_id) REFERENCES accounts(account_id),
    FOREIGN KEY (tipo_id) REFERENCES tipos_transaccion(tipo_id)
);

########################## PREGUNTAS ANALÍTICAS Y CÁLCULO DE KPI ##########################

-- 1. Calcular la media diaria de la cuantía de las transacciones.
SELECT
	MONTH(hora_transaccion) AS month, 
    DAY(hora_transaccion) AS day,
	AVG(cuantia) AS avg_cuantia
FROM transacciones
GROUP BY  MONTH(hora_transaccion), DAY(hora_transaccion);

-- 2. Calcular la cuantía total de las transacciones.
SELECT
	SUM(cuantia) AS cuantia_total
FROM transacciones;

-- 3. ¿Qué días del mes se han producido más transacciones y cuántas?
SELECT
	MONTH(hora_transaccion) AS month, 
    DAY(hora_transaccion) AS day,
	COUNT(*) AS numero_transacciones
FROM transacciones
GROUP BY  MONTH(hora_transaccion), DAY(hora_transaccion)
ORDER BY numero_transacciones DESC
LIMIT 10;

-- 4. ¿A qué horas del día se producen más transacciones y cuántas?
SELECT
	MONTH(hora_transaccion) AS month, 
    DAY(hora_transaccion) AS day,
    HOUR(hora_transaccion) AS hour,
	COUNT(*) AS numero_transacciones
FROM transacciones
GROUP BY  MONTH(hora_transaccion), DAY(hora_transaccion), HOUR(hora_transaccion)
ORDER BY numero_transacciones DESC
LIMIT 10;

-- 5. ¿Cuáles son los 5 clientes que han transferido más dinero y cuánto?
SELECT
	origen_id AS cliente_id,
    SUM(cuantia) AS total_transferido
FROM transacciones
WHERE tipo_id = (SELECT tipo_id FROM tipos_transaccion WHERE nombre_tipo = 'TRANSFER')
GROUP BY origen_id
ORDER BY total_transferido DESC
LIMIT 5;

-- 6. ¿Cuáles son los 5 clientes que han transferido menos dinero y cuánto?
SELECT
	origen_id AS cliente_id,
    SUM(cuantia) AS total_transferido
FROM transacciones
WHERE tipo_id = (SELECT tipo_id FROM tipos_transaccion WHERE nombre_tipo = 'TRANSFER')
GROUP BY origen_id
ORDER BY total_transferido ASC
LIMIT 5;

-- 7. ¿Cuáles son los 10 clientes que han recibido más dinero y cuánto?
SELECT
	destino_id AS cliente_id,
    SUM(cuantia) AS total_recibido
FROM transacciones
WHERE tipo_id = (SELECT tipo_id FROM tipos_transaccion WHERE nombre_tipo = 'TRANSFER')
GROUP BY destino_id
ORDER BY total_recibido DESC
LIMIT 10;

-- 8. ¿Cuáles son los 3 clientes con mejor balance a lo largo del mes (aquellos que al restarle al dinero recibido el dinero enviado se quedan con un mejor resultado) y cuál ha sido su balance?
SELECT
	cliente_id,
    SUM(total_recibido) - SUM(total_enviado) AS balance
FROM(
	# Dinero recibido por cada cliente
	SELECT destino_id AS cliente_id, SUM(cuantia) AS total_recibido, 0 AS total_enviado
    FROM transacciones
    GROUP BY destino_id

    UNION ALL

    # Dinero enviado por cada cliente
    SELECT origen_id AS cliente_id, 0 AS total_recibido, SUM(cuantia) AS total_enviado
    FROM transacciones
    GROUP BY origen_id
) AS balances
GROUP BY cliente_id
ORDER BY balance DESC
LIMIT 3;

-- 9. ¿Cuáles son los 3 clientes con peor balance a lo largo de todo el mes y cuál ha sido?


-- 10. ¿Cuántas transacciones fraudulentas se han producido?


-- 11. Diferenciando entre si las transacciones han producido una alarma de transacción fraudulenta en los sistemas, ¿cuántas han sido realmente fraudulentas y cuántas no?


-- 12. ¿Cuántas transacciones se producen por cada tipo de operación?


-- 13. ¿Cuál es la cuantía total de cada tipo de transacción que realizan los 5 clientes que han transferido más dinero?


-- 14. Para cada transacción, calcular el porcentaje de incremento del balance del destinatario.


-- 15. Suponiendo que si no se dispone de información del balance anterior y posterior de un cliente (ya sea emisor o receptor de la operación) no es cliente de Pontia Bank S.L., ¿cuánto dinero en total ha recibido Pontia Bank S.L. (desde destinatarios externos) y cuánto ha emitido (a destinatarios externos)? 
-- ¿Cuál es la cuantía media y total de las operaciones realizadas entre dos clientes de Pontia Bank S.L.?

########################## PLANTEAMIENTO ANALÍTICO EXTRA Y METRICAS ADICIONALES ##########################


