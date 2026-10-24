# Trabajo Práctico 2 – Exploración de Datos (Individual)
## Selección de una fuente de datos, exploración y limpieza con una base relacional en RSQLite

- **Autor:** Tomás Velles Aguirre (`tomasvelles@gmail.com`)
- **Asignatura:** Exploración de Datos – Licenciatura en Ciencia de Datos (UCA, 2026)
- **Modalidad:** Individual
- **Entorno:** R (`DBI`, `RSQLite`, `dplyr`, `tidyr`, `readr`, `stringr`, `jsonlite`, `ggplot2`), Google Colab, Visual Studio Code y GitHub.

## Problema y preguntas

En Steam salen miles de juegos por año, pero la mayoría no llega a tener un alcance grande de jugadores. El objetivo de este trabajo es armar una base relacional en SQLite desde R con datos del catálogo de Steam (entre 1998 y 2025) para analizar cómo se relacionan el precio, el género, las notas y la forma de publicación con la cantidad de propietarios.

**Preguntas exploratorias:**
1. ¿Cómo varían los precios, el porcentaje de juegos gratuitos y las calificaciones (*Metascore*) según el género, y qué relación tienen con los juegos que superan el millón de propietarios?
2. ¿Qué diferencias de alcance (superar los 500 mil propietarios), precio y calificación hay entre los juegos autopublicados y los que salen con un editor externo, teniendo en cuenta el tamaño del estudio?
3. ¿Cómo cambian el precio actual, la cobertura de calificaciones y la cantidad acumulada de propietarios según la etapa o año de lanzamiento del juego (1998–2025)?

## Fuente, licencia, muestra y filtros

- **Fuente:** [SteamSpy](https://steamspy.com) (documentación en [steamspy.com/about](https://steamspy.com/about)), administrado por Sergey Galyonkin. Toma datos públicos de la API de Steam (Valve) y de Metacritic. Fecha de consulta: 21/10/2026.
- **Condiciones de uso:** Datos públicos de uso libre citando a `steamspy.com`. No usa claves privadas ni datos personales.
- **Muestra:** 2.410 registros descargados en 6 lotes: cinco géneros (`Indie`, `Action`, `Adventure`, `Sports` y `Massively`) y el listado de lanzamientos de `2025`.
- **Filtros:** Se conservan los juegos publicados entre 1998 y 2025. Quedan afuera 97 filas: juegos no lanzados (`"Coming soon"`), lanzamientos de 2026 y filas con fechas erróneas previas a 1998 (`1969`, `1987` y `1990`).

## Estructura original, dataframes y esquema relacional

En `datos/original/` se guardan dos archivos sin modificar:
- `steamspy_catalogo_bruto.csv`: tabla cruda con las 2.410 filas descargadas (cada fila es la aparición de un juego en el ranking de un listado).
- `steamspy_lotes_extraccion.json`: metadatos de los 6 lotes (URL, fecha y cantidad de filas).

En R se arman 6 dataframes que separan configuración propia, metadatos y observaciones limpias, y se cargan en `salidas/proyecto.sqlite` (`sql/esquema.sql`):
1. `lotes_extraccion` (6 filas, PK `lote_id`): metadatos de cada descarga desde el JSON.
2. `generos` (6 filas, PK `genero_id`): catálogo definido en el código con los 5 géneros y la cohorte 2025.
3. `estudios` (1.280 filas, PK `estudio_id`): estudios desarrolladores únicos normalizados.
4. `juegos` (1.638 filas, PK `juego_id`, FK a `estudios` y `lotes_extraccion`): un registro por cada videojuego único con su fecha, precio y modalidad (`Autopublicado` o `Editor Externo`).
5. `metricas_steamspy` (1.638 filas, PK `metrica_id`, FK única a `juegos`): calificación y rango de propietarios de cada juego.
6. `juego_genero` (2.313 filas, PK compuesta `juego_id, genero_id`): tabla puente que vincula cada juego con sus géneros y su puesto en el ranking sin duplicar el juego en la tabla principal.

## Reglas de preparación

El detalle de filas antes y después de cada regla se genera en `salidas/bitacora_limpieza.csv`:
- **R1 (Fechas):** Pasa las fechas a formato `YYYY-MM-DD` y filtra el rango 1998–2025 (descarta 97 filas inválidas o futuras).
- **R2 (Precios):** Quita el signo `$`, asigna `0.00` a los juegos gratuitos (`"Free"`) y `NULL` a los que no tienen precio directo (`"N/A"`), para no distorsionar los promedios con ceros falsos.
- **R3 (Propietarios):** Separa el texto del intervalo (`"min .. max"`) en tres columnas numéricas (mínimo, máximo y punto medio), manteniendo los extremos reales.
- **R4 (Calificaciones):** Extrae el número de porcentaje desde el texto anidado (`score_rank_raw`) y deja `NULL` cuando figura `"N/A"`.
- **R5 (Estudios y editores):** Unifica variantes de nombres de empresas y clasifica si el juego es autopublicado (`developer == publisher` o editor `"N/A"`) o si tiene editor externo.
- **R6 (Deduplicación):** Separa los 1.638 juegos únicos de las 2.313 apariciones por género (675 repeticiones entre listados).
- **R7 (Integridad):** Controla que se cumplan las restricciones `CHECK` y las claves foráneas antes de cerrar la transacción en SQLite.

## Consultas, resultados esperados y limitaciones

En `sql/consultas.sql` están las 6 consultas sobre la base SQLite:
- **Consulta 1:** Cruza `generos`, `juego_genero`, `juegos` y `metricas_steamspy` para calcular precio promedio pago, porcentaje de gratuitos, nota media y porcentaje de juegos con más de 1M de dueños por género.
- **Consulta 2:** Cruza `estudios`, `juegos` y `metricas_steamspy` para comparar alcance comercial, precio y notas entre autopublicados y editores externos según la cantidad de juegos del estudio.
- **Consulta 3:** Agrupa por etapas de lanzamiento (1998–2025) para ver cambios en precios, cobertura de notas y propietarios acumulados.
- **Consulta 4:** Lista los 15 estudios con 4 o más juegos ordenados por propietarios acumulados usando una subconsulta para no duplicar juegos que están en varios géneros.
- **Consulta 5:** Agrupa los juegos por tramos de precio en dólares.
- **Consulta 6:** Control de calidad que compara la suma de propietarios sobre juegos únicos contra una suma directa con `JOIN` a `juego_genero`, mostrando cómo se inflaría el total (+50,8%) si no se separaran las tablas.

**Resultados esperados:** Al correr el proyecto se genera la base `salidas/proyecto.sqlite`, la bitácora `salidas/bitacora_limpieza.csv`, las tablas CSV de las consultas y los 3 gráficos principales en `salidas/resultados/`, además de pasar los 4 controles con `stopifnot()` (caso conocido, prueba de error con `dbRollback()`, integridad referencial con `PRAGMA foreign_key_check` y conteo de filas).

**Limitaciones:**
- La cantidad de propietarios en SteamSpy es una estimación por rangos basada en perfiles públicos, no ventas exactas ni ingresos.
- Los precios corresponden al valor de lista actual en la tienda y no al precio histórico de salida ni a ofertas.
- Los juegos más viejos tienen más propietarios acumulados por llevar más años en venta que los lanzados en 2025.

## Ejecución

1. Abrir `TP2_ED_VellesAguirreTomas.ipynb` en Google Colab (verificando que el entorno de ejecución esté en **R**) o localmente en VS Code desde la raíz del proyecto.
2. Ejecutar todas las celdas en orden (`Ejecutar todas` / `Run All`).
3. La primera celda instala los paquetes que falten (`paquetes_R.txt`) y verifica los archivos de entrada; las siguientes limpian los datos, reconstruyen `salidas/proyecto.sqlite` desde cero mediante una transacción, corren las consultas SQL, guardan los gráficos y cierran la conexión con `dbDisconnect()`.