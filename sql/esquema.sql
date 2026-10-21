-- ============================================================================
-- TP2 Exploración de Datos - Licenciatura en Ciencia de Datos (UCA, 2026)
-- Autor: Tomás Velles Aguirre
-- Archivo: sql/esquema.sql
-- Descripción: Esquema relacional normalizado en SQLite (6 tablas relacionadas)
-- ============================================================================

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS juego_genero;
DROP TABLE IF EXISTS metricas_steamspy;
DROP TABLE IF EXISTS juegos;
DROP TABLE IF EXISTS estudios;
DROP TABLE IF EXISTS generos;
DROP TABLE IF EXISTS lotes_extraccion;

-- 1. Tabla de metadatos de procedencia y lotes de extracción
CREATE TABLE lotes_extraccion (
    lote_id TEXT PRIMARY KEY,
    nombre_lote TEXT NOT NULL UNIQUE,
    fuente_responsable TEXT NOT NULL,
    url_origen TEXT NOT NULL,
    fecha_extraccion TEXT NOT NULL CHECK (length(fecha_extraccion) = 10),
    licencia TEXT NOT NULL,
    registros_brutos INTEGER NOT NULL CHECK (registros_brutos > 0)
);

-- 2. Catálogo de géneros y cortes analíticos de SteamSpy
CREATE TABLE generos (
    genero_id TEXT PRIMARY KEY,
    codigo_steamspy TEXT NOT NULL UNIQUE,
    nombre_genero TEXT NOT NULL UNIQUE,
    grupo_analitico TEXT NOT NULL,
    descripcion TEXT NOT NULL,
    url_referencia TEXT NOT NULL
);

-- 3. Catálogo de estudios desarrolladores normalizados
CREATE TABLE estudios (
    estudio_id INTEGER PRIMARY KEY,
    nombre_estudio TEXT NOT NULL UNIQUE,
    es_colaborativo INTEGER NOT NULL CHECK (es_colaborativo IN (0, 1)),
    modalidad_habitual TEXT NOT NULL CHECK (modalidad_habitual IN ('Autopublicado', 'Editor Externo')),
    perfil_escala TEXT NOT NULL,
    total_titulos_muestra INTEGER NOT NULL CHECK (total_titulos_muestra >= 1)
);

-- 4. Entidad principal de videojuegos únicos analizados
CREATE TABLE juegos (
    juego_id INTEGER PRIMARY KEY,
    titulo TEXT NOT NULL,
    titulo_normalizado TEXT NOT NULL UNIQUE,
    fecha_lanzamiento TEXT NOT NULL CHECK (length(fecha_lanzamiento) = 10),
    anio_lanzamiento INTEGER NOT NULL CHECK (anio_lanzamiento BETWEEN 1998 AND 2025),
    estudio_id INTEGER NOT NULL,
    editor_principal TEXT NOT NULL,
    modalidad_publicacion TEXT NOT NULL CHECK (modalidad_publicacion IN ('Autopublicado', 'Editor Externo')),
    precio_usd REAL CHECK (precio_usd IS NULL OR (precio_usd >= 0 AND precio_usd <= 500)),
    es_gratuito INTEGER NOT NULL CHECK (es_gratuito IN (0, 1)),
    estado_precio TEXT NOT NULL CHECK (estado_precio IN ('Pago', 'Gratuito', 'Sin precio vigente')),
    lote_origen_id TEXT NOT NULL,
    FOREIGN KEY (estudio_id) REFERENCES estudios(estudio_id) ON DELETE RESTRICT,
    FOREIGN KEY (lote_origen_id) REFERENCES lotes_extraccion(lote_id) ON DELETE RESTRICT
);

-- 5. Tabla de métricas cuantitativas de recepción crítica y propietarios (relación 1:1 con juegos)
CREATE TABLE metricas_steamspy (
    metrica_id INTEGER PRIMARY KEY,
    juego_id INTEGER NOT NULL UNIQUE,
    metascore_pct INTEGER CHECK (metascore_pct IS NULL OR (metascore_pct BETWEEN 1 AND 100)),
    tiene_metascore INTEGER NOT NULL CHECK (tiene_metascore IN (0, 1)),
    rango_propietarios_texto TEXT NOT NULL,
    propietarios_min INTEGER NOT NULL CHECK (propietarios_min >= 0),
    propietarios_max INTEGER NOT NULL CHECK (propietarios_max >= propietarios_min AND propietarios_max > 0),
    propietarios_med REAL NOT NULL CHECK (propietarios_med > 0),
    segmento_propietarios TEXT NOT NULL,
    lote_id TEXT NOT NULL,
    FOREIGN KEY (juego_id) REFERENCES juegos(juego_id) ON DELETE CASCADE,
    FOREIGN KEY (lote_id) REFERENCES lotes_extraccion(lote_id) ON DELETE RESTRICT
);

-- 6. Tabla puente N:M entre videojuegos y géneros/cohortes
CREATE TABLE juego_genero (
    juego_id INTEGER NOT NULL,
    genero_id TEXT NOT NULL,
    ranking_en_listado INTEGER NOT NULL CHECK (ranking_en_listado >= 1),
    es_genero_primario INTEGER NOT NULL CHECK (es_genero_primario IN (0, 1)),
    lote_id TEXT NOT NULL,
    PRIMARY KEY (juego_id, genero_id),
    FOREIGN KEY (juego_id) REFERENCES juegos(juego_id) ON DELETE CASCADE,
    FOREIGN KEY (genero_id) REFERENCES generos(genero_id) ON DELETE RESTRICT,
    FOREIGN KEY (lote_id) REFERENCES lotes_extraccion(lote_id) ON DELETE RESTRICT
);
