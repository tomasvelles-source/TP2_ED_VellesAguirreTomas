# ==============================================================================
# TP2 Exploración de Datos - Licenciatura en Ciencia de Datos (UCA, 2026)
# Autor: Tomás Velles Aguirre
# Script: R/03_consultas_y_graficos.R
# Propósito: Paso 5 - Ejecutar las 6 consultas SQL documentadas sobre SQLite y
#            generar los 3 gráficos principales de resultados con ggplot2.
# ==============================================================================

suppressPackageStartupMessages({
  library(DBI)
  library(RSQLite)
  library(dplyr)
  library(ggplot2)
  library(scales)
})

ejecutar_consultas_tp2 <- function(con) {
  dbExecute(con, "PRAGMA foreign_keys = ON;")
  
  q1 <- dbGetQuery(con, "
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
  ")
  
  list(consulta_1 = q1)
}
