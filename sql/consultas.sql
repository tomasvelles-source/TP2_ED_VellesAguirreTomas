-- ============================================================================
-- TP2 Exploración de Datos - Licenciatura en Ciencia de Datos (UCA, 2026)
-- Autor: Tomás Velles Aguirre
-- Archivo: sql/consultas.sql
-- Descripción: Seis consultas SQL documentadas (analíticas y de control de calidad)
--              sobre el modelo relacional de 6 tablas en SQLite.
-- ============================================================================

-- [CONSULTA_1]
-- Pregunta 1: Posicionamiento de precios, recepción crítica y alcance por género/listado.
-- Unidad de análisis de la fila resultante: Un género/listado del catálogo de SteamSpy.
-- Tablas utilizadas (4 tablas con JOIN): generos, juego_genero, juegos, metricas_steamspy.
SELECT
    g.nombre_genero AS genero,
    g.grupo_analitico AS categoria_analitica,
    COUNT(DISTINCT j.juego_id) AS total_juegos,
    SUM(CASE WHEN j.es_gratuito = 1 THEN 1 ELSE 0 END) AS juegos_gratuitos,
    ROUND(100.0 * SUM(CASE WHEN j.es_gratuito = 1 THEN 1 ELSE 0 END) / COUNT(DISTINCT j.juego_id), 1) AS pct_gratuitos,
    COUNT(CASE WHEN j.estado_precio = 'Pago' THEN 1 END) AS juegos_pagos_con_precio,
    ROUND(AVG(CASE WHEN j.estado_precio = 'Pago' THEN j.precio_usd END), 2) AS precio_medio_pagos_usd,
    ROUND(AVG(m.metascore_pct), 1) AS metascore_promedio_pct,
    ROUND(AVG(m.propietarios_med) / 1000.0, 1) AS propietarios_medios_miles,
    ROUND(100.0 * SUM(CASE WHEN m.propietarios_max >= 1000000 THEN 1 ELSE 0 END) / COUNT(DISTINCT j.juego_id), 1) AS pct_exitos_1m_mas
FROM generos g
INNER JOIN juego_genero jg ON g.genero_id = jg.genero_id
INNER JOIN juegos j ON jg.juego_id = j.juego_id
INNER JOIN metricas_steamspy m ON j.juego_id = m.juego_id
GROUP BY g.genero_id, g.nombre_genero, g.grupo_analitico
ORDER BY propietarios_medios_miles DESC;

-- [CONSULTA_2]
-- Pregunta 2: Desempeño comercial y recepción crítica según modalidad editorial y escala del estudio.
-- Unidad de análisis de la fila resultante: Combinación (modalidad_publicacion x perfil_escala del estudio).
-- Tablas utilizadas (3 tablas con JOIN): estudios, juegos, metricas_steamspy.
SELECT
    j.modalidad_publicacion,
    e.perfil_escala,
    COUNT(DISTINCT e.estudio_id) AS cantidad_estudios,
    COUNT(j.juego_id) AS total_titulos,
    ROUND(AVG(CASE WHEN j.estado_precio = 'Pago' THEN j.precio_usd END), 2) AS precio_medio_pagos_usd,
    ROUND(AVG(m.metascore_pct), 1) AS metascore_medio_pct,
    ROUND(AVG(m.propietarios_med) / 1000.0, 1) AS propietarios_medios_miles,
    ROUND(100.0 * SUM(CASE WHEN m.propietarios_max >= 500000 THEN 1 ELSE 0 END) / COUNT(j.juego_id), 1) AS pct_supera_500k_prop
FROM juegos j
INNER JOIN estudios e ON j.estudio_id = e.estudio_id
INNER JOIN metricas_steamspy m ON j.juego_id = m.juego_id
GROUP BY j.modalidad_publicacion, e.perfil_escala
ORDER BY j.modalidad_publicacion ASC, total_titulos DESC;

-- [CONSULTA_3]
-- Pregunta 3: Evolución histórica por cohorte de lanzamiento en Steam (1998-2025).
-- Unidad de análisis de la fila resultante: Cohorte plurianual/anual de lanzamiento en Steam.
-- Tablas utilizadas (3 tablas con JOIN): juegos, metricas_steamspy, lotes_extraccion.
SELECT
    CASE
        WHEN j.anio_lanzamiento BETWEEN 1998 AND 2012 THEN '1. Etapa Clásica (1998-2012)'
        WHEN j.anio_lanzamiento BETWEEN 2013 AND 2016 THEN '2. Expansión Greenlight (2013-2016)'
        WHEN j.anio_lanzamiento BETWEEN 2017 AND 2020 THEN '3. Etapa Steam Direct (2017-2020)'
        WHEN j.anio_lanzamiento BETWEEN 2021 AND 2023 THEN '4. Madurez Post-2020 (2021-2023)'
        WHEN j.anio_lanzamiento = 2024 THEN '5. Lanzamientos Recientes (2024)'
        ELSE '6. Cohorte Nueva (2025)'
    END AS cohorte_lanzamiento,
    COUNT(j.juego_id) AS cantidad_juegos,
    SUM(m.tiene_metascore) AS juegos_con_metascore,
    ROUND(100.0 * SUM(m.tiene_metascore) / COUNT(j.juego_id), 1) AS pct_cobertura_metascore,
    ROUND(AVG(CASE WHEN j.estado_precio = 'Pago' THEN j.precio_usd END), 2) AS precio_medio_pagos_usd,
    ROUND(AVG(m.metascore_pct), 1) AS metascore_medio_pct,
    ROUND(AVG(m.propietarios_med) / 1000.0, 1) AS propietarios_medios_miles,
    ROUND(100.0 * SUM(CASE WHEN m.propietarios_max >= 500000 THEN 1 ELSE 0 END) / COUNT(j.juego_id), 1) AS pct_supera_500k_prop
FROM juegos j
INNER JOIN metricas_steamspy m ON j.juego_id = m.juego_id
INNER JOIN lotes_extraccion l ON j.lote_origen_id = l.lote_id
GROUP BY cohorte_lanzamiento
ORDER BY cohorte_lanzamiento ASC;

-- [CONSULTA_4]
-- Consulta analítica 4: Top 15 estudios con al menos 4 títulos en la muestra, sin duplicar métricas por géneros.
-- Unidad de análisis de la fila resultante: Un estudio desarrollador consolidado.
-- Tablas utilizadas (5 tablas con subconsulta + JOIN): estudios, juegos, metricas_steamspy, juego_genero, generos.
SELECT
    e.nombre_estudio,
    e.modalidad_habitual,
    COUNT(DISTINCT j.juego_id) AS titulos_unicos,
    COUNT(DISTINCT jg.genero_id) AS generos_distintos,
    ROUND(AVG(m.metascore_pct), 1) AS metascore_promedio,
    ROUND(AVG(CASE WHEN j.estado_precio = 'Pago' THEN j.precio_usd END), 2) AS precio_medio_usd,
    ROUND(
        (SELECT SUM(m2.propietarios_med)
         FROM juegos j2
         INNER JOIN metricas_steamspy m2 ON j2.juego_id = m2.juego_id
         WHERE j2.estudio_id = e.estudio_id) / 1000000.0, 2
    ) AS propietarios_acumulados_millones
FROM estudios e
INNER JOIN juegos j ON e.estudio_id = j.estudio_id
INNER JOIN metricas_steamspy m ON j.juego_id = m.juego_id
INNER JOIN juego_genero jg ON j.juego_id = jg.juego_id
INNER JOIN generos g ON jg.genero_id = g.genero_id
GROUP BY e.estudio_id, e.nombre_estudio, e.modalidad_habitual
HAVING COUNT(DISTINCT j.juego_id) >= 4
ORDER BY propietarios_acumulados_millones DESC, metascore_promedio DESC
LIMIT 15;

-- [CONSULTA_5]
-- Consulta analítica 5: Desempeño según tramo tarifario (estructura de precios en USD).
-- Unidad de análisis de la fila resultante: Un tramo tarifario o estado de precio en Steam.
-- Tablas utilizadas (2 tablas con JOIN): juegos, metricas_steamspy.
SELECT
    CASE
        WHEN j.estado_precio = 'Gratuito' THEN '1. Free-to-Play ($0.00)'
        WHEN j.estado_precio = 'Sin precio vigente' THEN '6. Sin precio directo (N/A)'
        WHEN j.precio_usd < 10.0 THEN '2. Económico ($0.01 - $9.99)'
        WHEN j.precio_usd < 20.0 THEN '3. Estándar Indie ($10.00 - $19.99)'
        WHEN j.precio_usd < 40.0 THEN '4. Intermedio AA ($20.00 - $39.99)'
        ELSE '5. Premium / AAA ($40.00+)'
    END AS tramo_precio,
    COUNT(j.juego_id) AS cantidad_juegos,
    ROUND(100.0 * COUNT(j.juego_id) / (SELECT COUNT(*) FROM juegos), 1) AS pct_catalogo,
    ROUND(AVG(j.precio_usd), 2) AS precio_promedio_tramo_usd,
    ROUND(AVG(m.metascore_pct), 1) AS metascore_promedio_pct,
    ROUND(AVG(m.propietarios_med) / 1000.0, 1) AS propietarios_medios_miles,
    ROUND(100.0 * SUM(CASE WHEN m.propietarios_max >= 500000 THEN 1 ELSE 0 END) / COUNT(j.juego_id), 1) AS pct_supera_500k
FROM juegos j
INNER JOIN metricas_steamspy m ON j.juego_id = m.juego_id
GROUP BY tramo_precio
ORDER BY tramo_precio ASC;

-- [CONSULTA_6]
-- Consulta de control de calidad 6: Auditoría de integridad de agregación ante JOIN N:M y trazabilidad por lote.
-- Verifica cuánto se inflaría erróneamente la suma de propietarios si se sumara sobre juego_genero sin deduplicar.
-- Tablas utilizadas (6 tablas del modelo): lotes_extraccion, juegos, metricas_steamspy, estudios, juego_genero, generos.
SELECT
    '1. Suma correcta sobre entidad única (juegos JOIN metricas_steamspy)' AS metodo_calculo,
    COUNT(j.juego_id) AS filas_evaluadas,
    COUNT(DISTINCT j.juego_id) AS juegos_unicos,
    ROUND(SUM(m.propietarios_med) / 1000000.0, 2) AS suma_propietarios_millones
FROM juegos j
INNER JOIN metricas_steamspy m ON j.juego_id = m.juego_id
INNER JOIN estudios e ON j.estudio_id = e.estudio_id
INNER JOIN lotes_extraccion l ON j.lote_origen_id = l.lote_id
UNION ALL
SELECT
    '2. Suma ingenua con JOIN N:M sin deduplicar (juegos JOIN juego_genero)' AS metodo_calculo,
    COUNT(jg.juego_id) AS filas_evaluadas,
    COUNT(DISTINCT j.juego_id) AS juegos_unicos,
    ROUND(SUM(m.propietarios_med) / 1000000.0, 2) AS suma_propietarios_millones
FROM juegos j
INNER JOIN metricas_steamspy m ON j.juego_id = m.juego_id
INNER JOIN juego_genero jg ON j.juego_id = jg.juego_id
INNER JOIN generos g ON jg.genero_id = g.genero_id;
