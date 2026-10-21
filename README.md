# Trabajo Práctico 2 – Exploración de Datos (Individual)
## Selección de una fuente de datos, exploración y limpieza con una base relacional en RSQLite

- **Autor:** Tomás Velles Aguirre (`tomasvelles@gmail.com`)
- **Asignatura:** Exploración de Datos – Licenciatura en Ciencia de Datos (UCA, 2026)
- **Modalidad:** Individual
- **Entorno:** R (`DBI`, `RSQLite`, `dplyr`, `tidyr`, `readr`, `stringr`, `jsonlite`, `ggplot2`), Google Colab, Visual Studio Code y GitHub.

---

## 1. Problema, contexto, objetivo, alcance y preguntas exploratorias

### Problema y contexto
El mercado digital de videojuegos en PC a través de **Steam** (operado por Valve Corporation) concentra miles de lanzamientos anuales con una fuerte asimetría comercial: mientras una fracción reducida de títulos supera el medio millón o el millón de copias, la mayoría enfrenta una intensa competencia por visibilidad y precio. Quienes toman decisiones en **estudios independientes (indies), editoriales (publishers) y equipos de inteligencia comercial** necesitan comprender cómo se relacionan el posicionamiento de precios, la recepción crítica, la modalidad editorial (autopublicación vs. editor externo) y el género con el alcance comercial alcanzado.

### Objetivo y alcance
Construir un flujo reproducible desde R y SQLite que capture, diagnostique, limpie y estructure en un modelo relacional normalizado de **6 tablas** una muestra representativa de **2,410 registros de listados de SteamSpy** (correspondientes a **1,638 videojuegos únicos** lanzados entre **1998 y 2025**), para responder mediante consultas SQL y visualizaciones en `ggplot2` tres preguntas exploratorias concretas.

### Tres preguntas exploratorias
1. **Pregunta 1 (Posicionamiento por género y modelo tarifario):** ¿Cómo varían la estructura de precios de lista (USD), la proporción de títulos gratuitos (*Free-to-Play*) y la recepción crítica (*Metascore*) entre los principales géneros del catálogo (`Action`, `Adventure`, `Indie`, `Sports`, `Massively`) y qué relación guardan con la proporción de éxitos masivos ($\ge 1	ext{M}$ de propietarios)?
2. **Pregunta 2 (Modalidad editorial y escala del estudio):** ¿En qué medida la modalidad de publicación (**Autopublicado** vs. **Editor Externo**) y la escala del estudio desarrollador (monotítulo, mediano de 2 títulos o consolidado de 3+ títulos en muestra) se asocian con el precio de lista promedio, la recepción crítica y la probabilidad de superar los $500,000$ propietarios?
3. **Pregunta 3 (Evolución por cohortes de lanzamiento 1998–2025):** ¿Cómo evolucionan el precio nominal vigente, la cobertura de prensa especializada (*Metascore*) y la acumulación de propietarios a través de las seis etapas históricas de Steam (`1998–2012`, `2013–2016 Greenlight`, `2017–2020 Steam Direct`, `2021–2023`, `2024` y `2025`), y cómo influye el tiempo de exposición en tienda sobre el volumen acumulado?

---

## 2. Fuente de datos, procedencia, condiciones de uso y filtros

- **Fuente:** **SteamSpy** ([https://steamspy.com](https://steamspy.com)) y su documentación metodológica ([https://steamspy.com/about](https://steamspy.com/about)), desarrollado por **Sergey Galyonkin**, que agrega datos públicos de la **Steam Web API de Valve Corporation** y puntuaciones de **Metacritic**.
- **Fecha de acceso y captura:** 21 de octubre de 2026 (`2026-10-21`).
- **Licencia y condiciones de uso:** Datos de acceso público bajo atribución a `steamspy.com` ([https://steamspy.com/about](https://steamspy.com/about)). No requiere compartir tokens privados, contraseñas ni datos personales sensibles.
- **Muestra y filtros aplicados:** Se capturaron **6 lotes temáticos y temporales** documentados en `datos/original/steamspy_lotes_extraccion.json` y conservados intactos en `datos/original/steamspy_catalogo_bruto.csv` (**2,410 registros brutos**):
  1. `Indie` ([https://steamspy.com/genre/Indie](https://steamspy.com/genre/Indie)): 500 registros.
  2. `Action` ([https://steamspy.com/genre/Action](https://steamspy.com/genre/Action)): 500 registros.
  3. `Adventure` ([https://steamspy.com/genre/Adventure](https://steamspy.com/genre/Adventure)): 500 registros.
  4. `Sports` ([https://steamspy.com/genre/Sports](https://steamspy.com/genre/Sports)): 450 registros.
  5. `Cohorte 2025` ([https://steamspy.com/year/2025](https://steamspy.com/year/2025)): 450 registros.
  6. `Massively (MMO)` ([https://steamspy.com/genre/Massively](https://steamspy.com/genre/Massively)): 10 registros principales.
- **Qué datos quedan fuera:** Quedan fuera del alcance analítico los títulos aún no publicados (`"Coming soon"`, 3 filas), los lanzamientos futuros de 2026 (88 filas), los registros con marcas de tiempo corruptas previas a la existencia de Steam en 1998 (`Dec 31, 1969`, `Oct 1, 1987`, `Jan 1, 1990`, 6 filas), y los títulos fuera del corte de los listados seleccionados.

---

## 3. Estructura original, dataframes y esquema relacional (6 tablas en SQLite)

### Distinción entre configuración propia, metadatos y observaciones (Apéndice A.2)
1. **Catálogos y configuraciones definidos en el código R (`df_generos`):** Tabla de referencia con los 6 géneros/listados, su clasificación analítica (`grupo_analitico`) y el tipo de recorte (`Genero` vs. `Cohorte Anual`).
2. **Metadatos de procedencia (`df_lotes` desde `steamspy_lotes_extraccion.json`):** Registra cada lote de extracción (`lote_id`), su URL exacta, fecha de extracción y cantidad de registros brutos capturados.
3. **Dataframes construidos a partir de los valores observados (`df_estudios`, `df_juegos`, `df_metricas`, `df_juego_genero`):** Derivados de `steamspy_catalogo_bruto.csv` tras aplicar las 7 reglas de limpieza y normalización.

### Diagrama Entidad-Relación y unidad de análisis por tabla

```text
+----------------------+       1:N       +-----------------------+       1:1       +------------------------+
|  lotes_extraccion    |---------------->|        juegos         |<--------------->|   metricas_steamspy    |
+----------------------+                 +-----------------------+                 +------------------------+
| PK lote_id           |                 | PK juego_id           |                 | PK,FK juego_id         |
|    codigo_lote       |                 | UQ clave_titulo       |                 |       userscore_pct    |
|    url_origen        |                 |    titulo             |                 |       metascore_pct    |
|    fecha_extraccion  |                 | FK estudio_id --------+---+             |       tiene_metascore  |
|    registros_brutos  |                 |    modalidad_publicac.|   |             |       propietarios_min |
+----------------------+                 |    anio_lanzamiento   |   |             |       propietarios_max |
                                         |    estado_precio      |   |             |       propietarios_med |
+----------------------+                 |    precio_usd         |   |             +------------------------+
|       generos        |                 | FK lote_origen_id     |   |
+----------------------+                 +-----------------------+   | N:1         +------------------------+
| PK genero_id         |                             |               +------------>|        estudios        |
| UQ nombre_genero     |                             | 1:N                         +------------------------+
|    grupo_analitico   |                             v                             | PK estudio_id          |
|    tipo_lista        |                 +-----------------------+                 | UQ nombre_estudio      |
+----------------------+                 |     juego_genero      |                 |    titulos_en_muestra  |
           |                             +-----------------------+                 |    modalidad_habitual  |
           +---------------------------->| PK,FK juego_id        |                 |    perfil_escala       |
                        1:N              | PK,FK genero_id       |                 +------------------------+
                                         |       ranking_en_lista|
                                         | FK    lote_id         |
                                         +-----------------------+
```

- **`lotes_extraccion` (6 filas):** Unidad de análisis = lote de captura desde SteamSpy (`PK: lote_id`).
- **`generos` (6 filas):** Unidad de análisis = género o listado analítico (`PK: genero_id`).
- **`estudios` (1,280 filas):** Unidad de análisis = estudio desarrollador único normalizado (`PK: estudio_id`).
- **`juegos` (1,638 filas):** Unidad de análisis = videojuego único en Steam lanzado entre 1998 y 2025 (`PK: juego_id`, `FK: estudio_id`, `FK: lote_origen_id`).
- **`metricas_steamspy` (1,638 filas):** Unidad de análisis = perfil cuantitativo de recepción y propietarios de cada videojuego único (`PK, FK: juego_id`, relación `1:1` con `juegos`).
- **`juego_genero` (2,313 filas):** Unidad de análisis = pertenencia y posición (`ranking_en_lista`) de un videojuego dentro de un género/listado (`PK compuesta: juego_id, genero_id`). Separa la granularidad de listado de la entidad juego para evitar duplicar precios o propietarios.

---

## 4. Reglas de preparación y trazabilidad (`salidas/bitacora_limpieza.csv`)

| ID | Campo(s) | Condición detectada | Decisión aplicada | Filas antes | Afectadas | Filas después |
|:---|:---|:---|:---|---:|---:|---:|
| **R1** | `release_date_raw` | `"Coming soon"` (3), fechas corruptas `<1998` (6: 1969, 1987, 1990) o futuras `2026` (88) | Parsear a ISO `YYYY-MM-DD` y excluir las 97 filas fuera de la ventana `1998–2025` | 2,410 | 97 | 2,313 |
| **R2** | `price_raw` | Símbolo `$`, `"Free"` (179 juegos únicos) y `"N/A"` (178 juegos únicos) | Convertir `"Free"` a `0.00` (`Gratuito`) y `"N/A"` a `NULL` (`Sin precio vigente`) sin confundir faltantes con ceros | 2,313 | 2,313 | 2,313 |
| **R3** | `owners_raw` | Intervalos en texto `"1,000,000 .. 2,000,000"` | Extraer `propietarios_min`, `propietarios_max` y marca de clase `propietarios_med` conservando extremos reales | 2,313 | 2,313 | 2,313 |
| **R4** | `score_rank_raw` | Puntajes anidados `"97% (96%)"` o `"N/A (N/A)"` (596 juegos únicos sin Metascore) | Extraer `userscore_pct`, `metascore_pct` (`NULL` si ausente) e indicador `tiene_metascore` (`0/1`) | 2,313 | 763 | 2,313 |
| **R5** | `developer_raw`, `publisher_raw` | `publisher_raw = "N/A"` (85 juegos únicos) y espacios irregulares | Normalizar nombres de los 1,280 estudios y clasificar `modalidad_publicacion` (`Autopublicado` vs `Editor Externo`) | 2,313 | 85 | 2,313 |
| **R6** | `title`, `genre_or_list` | 675 apariciones repetidas de un mismo título en múltiples géneros | Deduplicar en **1,638 juegos únicos** en `juegos`/`metricas_steamspy` y conservar las **2,313 relaciones** en `juego_genero` | 2,313 | 675 | 1,638 |
| **R7** | Integridad FK | Control de orfandad en claves foráneas antes del `COMMIT` | Regla preventiva con `PRAGMA foreign_keys = ON`; 0 huérfanos detectados en la muestra limpia y verificada con lote de prueba separado | 2,313 | 0 | 2,313 |

---

## 5. Consultas SQL, resultados principales y limitaciones

El archivo `sql/consultas.sql` implementa **6 consultas SQL documentadas** sobre SQLite:
- **Consulta 1 (JOIN de 4 tablas: `generos`, `juego_genero`, `juegos`, `metricas_steamspy`):** Compara precios pagos, porcentaje *Free-to-Play*, *Metascore* medio y porcentaje de éxitos $\ge 1	ext{M}$ por género. Muestra que `Action` ($20.43 USD, Metascore 85.9%, 45.4% con $\ge 1	ext{M}$ prop.) y `Adventure` ($19.61 USD, Metascore 84.9%) lideran en recepción y precio, mientras que `Sports` exhibe un 33.6% de títulos gratuitos y menor recepción crítica media (73.8%).
- **Consulta 2 (JOIN de 3 tablas: `estudios`, `juegos`, `metricas_steamspy`):** Cruza modalidad editorial y escala del estudio. En estudios monotítulo, publicar con un **Editor Externo** casi duplica la probabilidad de superar los $500	ext{k}$ propietarios (**35.5%** vs. **20.6%** en autopublicados) y se asocia con un precio medio mayor ($17.36 vs. $11.63 USD). En estudios consolidados (3+ títulos), la brecha comercial se reduce (62.0% vs. 57.9%).
- **Consulta 3 (JOIN de 3 tablas: `juegos`, `metricas_steamspy`, `lotes_extraccion`):** Analiza la evolución por cohortes (`1998–2025`). Evidencia el efecto de maduración comercial: el 70.6% de los títulos de la etapa clásica (`1998–2012`) en la muestra supera hoy los $500	ext{k}$ propietarios frente al 33.7% en `2024` y 5.8% en `2025`, mientras que el precio nominal medio alcanza su máximo en `2021–2023` ($22.33 USD) y `2024` ($24.27 USD).
- **Consulta 4 (JOIN de 5 tablas + subconsulta correlacionada):** Identifica los 15 estudios con $\ge 4$ títulos en la muestra ordenados por propietarios acumulados sin duplicar títulos multietiqueta (liderados por *Valve Corporation*, *Rockstar Games*, *Capcom* y *Larian Studios*).
- **Consulta 5 (JOIN de 2 tablas por tramo tarifario):** Evalúa el desempeño comercial según 6 escalones de precios.
- **Consulta 6 (Control de calidad sobre las 6 tablas):** Demuestra cuantitativamente que sumar propietarios directamente sobre un `JOIN` con `juego_genero` sin deduplicar infla el total acumulado de **2,318.67 millones** a **3,497.31 millones** (+50.8% de sobreestimación artificial).

### Limitaciones conocidas
1. **Estimaciones por intervalos:** Los propietarios en SteamSpy representan intervalos muestrales de perfiles públicos y no ventas facturadas exactas ni ingresos netos.
2. **Precios nominales vigentes:** El campo `precio_usd` refleja el precio de lista vigente al momento de la extracción (`2026-10-21`), sujeto a depreciación comercial en cohortes antiguas.
3. **Sesgo de exposición temporal y selección:** Los listados por género priorizan títulos con tracción o actividad reciente, y la cohorte `2025` cuenta con menor tiempo acumulado en el mercado.

---

## 6. Estructura de carpetas y ejecución reproducible (Colab, VS Code y GitHub)

```text
TP2_ED_VellesAguirreTomas/
|-- TP2_ED_VellesAguirreTomas.ipynb
|-- README.md
|-- paquetes_R.txt
|-- presentacion.pdf
|-- datos/
|   |-- original/
|   |   |-- steamspy_catalogo_bruto.csv
|   |   `-- steamspy_lotes_extraccion.json
|   `-- diccionario.csv
|-- sql/
|   |-- esquema.sql
|   `-- consultas.sql
|-- R/
|   |-- 01_importar_y_diagnosticar.R
|   |-- 02_limpiar_y_cargar_sqlite.R
|   |-- 03_consultas_y_graficos.R
|   `-- 04_verificaciones.R
`-- salidas/
    |-- proyecto.sqlite
    |-- bitacora_limpieza.csv
    `-- resultados/
        |-- comparacion_antes_despues.csv
        |-- consulta_1_resultado.csv ... consulta_6_resultado.csv
        |-- grafico_1_generos_precios_recepcion.png
        |-- grafico_2_modalidad_editorial_alcance.png
        `-- grafico_3_evolucion_cohortes_propietarios.png
```

### Cómo ejecutar de principio a fin en Google Colab (Kernel R)
1. Subir la carpeta `TP2_ED_VellesAguirreTomas/` a Google Drive o clonar el repositorio desde GitHub, o bien abrir directamente `TP2_ED_VellesAguirreTomas.ipynb` en **Google Colab** verificando en `Entorno de ejecución -> Cambiar tipo de entorno de ejecución -> R`.
2. Ejecutar `Entorno de ejecución -> Ejecutar todas` (`Ctrl+F9`). El bloque inicial instala automáticamente cualquier paquete faltante (`RSQLite`, `DBI`, etc.), localiza los archivos originales en `datos/original/` (o los descarga desde el repositorio público de respaldo si se ejecuta el notebook suelto), reconstruye `salidas/proyecto.sqlite` desde cero mediante una transacción con `PRAGMA foreign_keys = ON`, ejecuta las 6 consultas SQL, regenera los 3 gráficos y corre las 4 suites de verificación con `stopifnot()`, cerrando todas las conexiones con `dbDisconnect()`.
