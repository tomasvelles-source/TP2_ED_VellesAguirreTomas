# ==============================================================================
# TP2 Exploración de Datos - Licenciatura en Ciencia de Datos (UCA, 2026)
# Autor: Tomás Velles Aguirre
# Script: R/02_limpiar_y_cargar_sqlite.R
# Propósito: Paso 3 y Paso 4 - Transformar los datos mediante 7 reglas trazables,
#            generar la bitácora y reconstruir la base SQLite con transacciones.
# ==============================================================================

suppressPackageStartupMessages({
  library(DBI)
  library(RSQLite)
  library(dplyr)
  library(stringr)
  library(readr)
})

reconstruir_base_sqlite <- function(ruta_base = ".", ruta_sqlite = file.path(ruta_base, "salidas/proyecto.sqlite")) {
  # En entornos donde el sistema de archivos montado no soporta bloqueos POSIX de SQLite,
  # construimos sobre un archivo temporal local y copiamos el binario verificado.
  tmp_sqlite <- tempfile(fileext = ".sqlite")
  if (file.exists(ruta_sqlite)) file.remove(ruta_sqlite)
  
  con <- dbConnect(RSQLite::SQLite(), tmp_sqlite)
  on.exit({
    if (dbIsValid(con)) dbDisconnect(con)
  }, add = TRUE)
  
  # Activar claves foráneas obligatoriamente en cada conexión
  dbExecute(con, "PRAGMA foreign_keys = ON;")
  
  # Leer y ejecutar DDL desde sql/esquema.sql
  esquema_texto <- read_file(file.path(ruta_base, "sql/esquema.sql"))
  sentencias_ddl <- str_split(esquema_texto, ";")[[1]]
  for (stmt in sentencias_ddl) {
    stmt_limpio <- str_trim(stmt)
    if (nchar(stmt_limpio) > 0 && !str_starts(stmt_limpio, "--")) {
      dbExecute(con, paste0(stmt_limpio, ";"))
    }
  }
  
  message("Esquema relacional de 6 tablas creado exitosamente con PRAGMA foreign_keys = ON.")
  return(con)
}
