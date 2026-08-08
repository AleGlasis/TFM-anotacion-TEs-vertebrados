#!/usr/bin/env Rscript

# =============================================================
# Uso desde terminal:
#   Rscript calcular_div_media_erv1_3.R archivo.csv archivo.fa.out [salida.csv]
# =============================================================

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Uso: Rscript calcular_div_media_erv1_3.R archivo.csv archivo.fa.out [salida.csv]")
}

ruta_csv      <- args[1]
ruta_faout    <- args[2]
nombre_salida <- ifelse(length(args) >= 3, args[3], "erv1_3_con_div.csv")

# Variantes ERV1-3 a buscar
variantes_erv <- c("ERV1-12_DR-LTR", "ERV1-3-LTR_DR", "ERV1-3B_DR-LTR", "ERV1-3C_DR-LTR")

# ── Leer el CSV existente ─────────────────────────────────────────────────────
message("Leyendo CSV...")
datos_csv <- read.csv(ruta_csv, stringsAsFactors = FALSE)

# ── Leer el .fa.out ───────────────────────────────────────────────────────────
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

# ── Calcular divergencia media por variante ERV1-3 ────────────────────────────
message("Calculando divergencias medias...")

datos_erv <- datos_rm[datos_rm$repeticion %in% variantes_erv, ]

if (nrow(datos_erv) == 0) {
  stop("No se encontraron variantes ERV1-3 en el archivo .fa.out.")
}

div_media_vec <- tapply(datos_erv$perc_div, datos_erv$repeticion, mean, na.rm = TRUE)

div_df <- data.frame(
  id_repeat = names(div_media_vec),
  div_media = round(as.numeric(div_media_vec), 4),
  stringsAsFactors = FALSE
)

message("Divergencias calculadas:")
print(div_df)

# ── Unir al CSV original ──────────────────────────────────────────────────────
datos_unidos <- merge(
  datos_csv,
  div_df,
  by = "id_repeat",
  all.x = TRUE
)

n_sin_div <- sum(is.na(datos_unidos$div_media))
if (n_sin_div > 0) {
  message("Filas sin divergencia (quedan NA): ", n_sin_div)
}

# ── Guardar ───────────────────────────────────────────────────────────────────
write.csv(datos_unidos, nombre_salida, row.names = FALSE)

message("Listo. CSV guardado en: ", nombre_salida)
message("Filas totales: ", nrow(datos_unidos))
