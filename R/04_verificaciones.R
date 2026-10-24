# ==============================================================================
# TP2 Exploración de Datos - Licenciatura en Ciencia de Datos (UCA, 2026)
# Autor: Tomás Velles Aguirre
# Script: R/04_verificaciones.R
# Propósito: Paso 6 - Comprobaciones ejecutables con stopifnot() para caso conocido,
#            caso inválido/límite con rollback, integridad referencial y conservación.
# ==============================================================================

suppressPackageStartupMessages({
  library(DBI)
  library(RSQLite)
})

ejecutar_verificaciones_tp2 <- function(con) {
  dbExecute(con, "PRAGMA foreign_keys = ON;")
  
  # 1. Caso conocido: Counter-Strike 2 (gratuito $0.00, Metascore 83, propietarios_min >= 100M)
  cs2 <- dbGetQuery(con, "
    SELECT j.titulo, j.precio_usd, j.estado_precio, m.metascore_pct, m.propietarios_min
    FROM juegos j
    INNER JOIN metricas_steamspy m ON j.juego_id = m.juego_id
    WHERE j.titulo = 'Counter-Strike 2';
  ")
  stopifnot(nrow(cs2) == 1)
  stopifnot(cs2$precio_usd == 0.0)
  stopifnot(cs2$estado_precio == "Gratuito")
  stopifnot(cs2$metascore_pct == 83)
  stopifnot(cs2$propietarios_min == 100000000)
  
  # 2. Caso inválido / límite en transacción aislada con ROLLBACK
  conteo_previo <- dbGetQuery(con, "SELECT COUNT(*) AS n FROM juegos;")$n
  error_capturado <- FALSE
  tryCatch({
    dbBegin(con)
    # Intento de insertar un juego con año 1985 (viola CHECK anio_lanzamiento BETWEEN 1998 AND 2025)
    dbExecute(con, "
      INSERT INTO juegos (juego_id, titulo, titulo_normalizado, fecha_lanzamiento, anio_lanzamiento, estudio_id, editor_principal, modalidad_publicacion, precio_usd, es_gratuito, estado_precio, lote_origen_id)
      VALUES (99999, 'Juego Inválido 1985', 'juego_invalido_test', '1985-01-01', 1985, 1, 'Test', 'Autopublicado', 19.99, 0, 'Pago', 'LOTE_INDIE');
    ")
    dbCommit(con)
  }, error = function(e) {
    error_capturado <<- TRUE
    dbRollback(con)
  })
  conteo_posterior <- dbGetQuery(con, "SELECT COUNT(*) AS n FROM juegos;")$n
  stopifnot("La restricción CHECK debió rechazar el año 1985" = error_capturado)
  stopifnot("El ROLLBACK no debe dejar carga parcial" = conteo_previo == conteo_posterior)
  
  # 3. Integridad referencial y unicidad de claves
  fk_issues <- dbGetQuery(con, "PRAGMA foreign_key_check;")
  stopifnot("Se detectaron claves foráneas huérfanas" = nrow(fk_issues) == 0)
  
  # 4. Conservación y reconciliación con bitácora (2410 brutas - 97 excluidas = 2313 en juego_genero)
  n_jg <- dbGetQuery(con, "SELECT COUNT(*) AS n FROM juego_genero;")$n
  stopifnot("Reconciliación exacta 2410 - 97 = 2313 filas" = (2410 - 97) == n_jg)
  stopifnot("Cantidad de juegos únicos debe ser 1638" = conteo_posterior == 1638)
  
  return(TRUE)
}
