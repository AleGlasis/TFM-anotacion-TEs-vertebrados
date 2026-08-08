#!/usr/bin/env Rscript

# =============================================================
# Uso desde terminal:
#   Rscript calcular_div_media_ltr7.R archivo.csv archivo.fa.out [salida.csv]
# =============================================================

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Uso: Rscript calcular_div_media_ltr7.R archivo.csv archivo.fa.out [salida.csv]")
}

ruta_csv      <- args[1]
ruta_faout    <- args[2]
nombre_salida <- ifelse(length(args) >= 3, args[3], "ltr7_con_div.csv")

# ── Leer el CSV existente ─────────────────────────────────────────────────────
message("Leyendo CSV...")
datos_csv <- read.csv(ruta_csv, stringsAsFactors = FALSE)

# ── Leer el .fa.out y calcular divergencia media por variante ─────────────────
message("Leyendo .fa.out...")

lineas_raw <- readLines(ruta_faout, warn = FALSE)
lineas_raw <- lineas_raw[4:length(lineas_raw)]
lineas_raw <- lineas_raw[nzchar(trimws(lineas_raw))]

message("Parseando filas...")

lista_filas <- lapply(lineas_raw, function(linea) {
  campos <- strsplit(trimws(linea), "\\s+")[[1]]
  if (length(campos) > 16) campos <- campos[1:16]
  if (length(campos) < 16) campos <- c(campos, rep(NA, 16 - length(campos)))
  campos[c(2, 10)]  # solo perc_div y repeticion
})

datos_rm <- as.data.frame(do.call(rbind, lista_filas), stringsAsFactors = FALSE)
colnames(datos_rm) <- c("perc_div", "repeticion")
datos_rm$perc_div  <- as.numeric(datos_rm$perc_div)
datos_rm           <- datos_rm[!is.na(datos_rm$perc_div), ]

# ── Calcular divergencia media por variante ───────────────────────────────────
message("Calculando divergencias medias...")

div_media <- tapply(datos_rm$perc_div, datos_rm$repeticion, mean, na.rm = TRUE)

div_df <- data.frame(
  id_repeat = names(div_media),
  div_media = round(as.numeric(div_media), 4),
  stringsAsFactors = FALSE
)

# ── Unir al CSV original ──────────────────────────────────────────────────────
# Se asume que la columna de nombres de variante en el CSV se llama "id_repeat"
# o "name" — se detecta automáticamente
col_nombre <- intersect(c("id_repeat", "name", "Name", "nombre"), colnames(datos_csv))

if (length(col_nombre) == 0) {
  stop("No se encontró columna de nombre de variante en el CSV. ",
       "Se esperaba una de: id_repeat, name, Name, nombre. ",
       "Columnas disponibles: ", paste(colnames(datos_csv), collapse = ", "))
}

col_nombre <- col_nombre[1]
message("Columna de variante detectada: ", col_nombre)

datos_unidos <- merge(
  datos_csv,
  div_df,
  by.x = col_nombre,
  by.y = "id_repeat",
  all.x = TRUE
)

n_sin_div <- sum(is.na(datos_unidos$div_media))
if (n_sin_div > 0) {
  message("Variantes sin divergencia en el .fa.out (quedan NA): ", n_sin_div)
}

# ── Guardar ───────────────────────────────────────────────────────────────────
write.csv(datos_unidos, nombre_salida, row.names = FALSE)

message("Listo. CSV guardado en: ", nombre_salida)
message("Filas totales: ", nrow(datos_unidos))
