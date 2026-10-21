# ==============================================================================
# TP2 Exploración de Datos - Licenciatura en Ciencia de Datos (UCA, 2026)
# Autor: Tomás Velles Aguirre
# Script: R/01_importar_y_diagnosticar.R
# Propósito: Paso 1 y Paso 2 - Importar archivos originales sin modificaciones y
#            ejecutar el diagnóstico cuantitativo de calidad inicial.
# ==============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(jsonlite)
  library(dplyr)
  library(stringr)
})

importar_originales <- function(ruta_base = ".") {
  ruta_csv  <- file.path(ruta_base, "datos/original/steamspy_catalogo_bruto.csv")
  ruta_json <- file.path(ruta_base, "datos/original/steamspy_lotes_extraccion.json")
  
  stopifnot("No se encontró el archivo CSV original" = file.exists(ruta_csv))
  stopifnot("No se encontró el archivo JSON de lotes" = file.exists(ruta_json))
  
  catalogo_bruto <- read_csv(ruta_csv, col_types = cols(.default = col_character()), show_col_types = FALSE) %>%
    mutate(
      ranking_origen = as.integer(ranking_origen)
    )
  
  lotes_meta <- fromJSON(ruta_json, flatten = TRUE) %>% as_tibble()
  
  list(catalogo_bruto = catalogo_bruto, lotes_meta = lotes_meta)
}

diagnosticar_calidad_inicial <- function(df_bruto) {
  total_filas <- nrow(df_bruto)
  titulos_unicos <- n_distinct(str_to_lower(str_squish(df_bruto$game_title_raw)))
  
  resumen_calidad <- tibble(
    dimension_analizada = c(
      "Filas totales importadas (listados brutos)",
      "Títulos únicos (por nombre normalizado)",
      "Apariciones repetidas inter-género (duplicados de listado)",
      "Precios con código 'Free' (gratuitos válidos = $0.00)",
      "Precios con código 'N/A' (faltantes sin precio directo)",
      "Fechas con cadena 'Coming soon' (no lanzados)",
      "Fechas corruptas anteriores a Steam (< 1998: 1969, 1987, 1990)",
      "Fechas futuras (año 2026 fuera de ventana 1998-2025)",
      "Registros sin Metascore en score_rank_raw ('N/A')",
      "Registros con publisher_raw == 'N/A'"
    ),
    cantidad = c(
      total_filas,
      titulos_unicos,
      total_filas - titulos_unicos,
      sum(df_bruto$price_raw == "Free", na.rm = TRUE),
      sum(df_bruto$price_raw == "N/A" | is.na(df_bruto$price_raw)),
      sum(df_bruto$release_date_raw == "Coming soon", na.rm = TRUE),
      sum(str_detect(df_bruto$release_date_raw, "1969|1987|1990"), na.rm = TRUE),
      sum(str_detect(df_bruto$release_date_raw, "2026"), na.rm = TRUE),
      sum(str_detect(df_bruto$score_rank_raw, "\\(N/A\\)"), na.rm = TRUE),
      sum(df_bruto$publisher_raw == "N/A" | is.na(df_bruto$publisher_raw))
    )
  ) %>%
    mutate(proporcion_pct = round(100 * cantidad / total_filas, 2))
  
  return(resumen_calidad)
}
