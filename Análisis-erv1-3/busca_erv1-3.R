# =============================================================
# Uso desde terminal:
#   Rscript busca_erv1_3_v2.R archivo.out erv1_3.csv
# =============================================================

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 1) {
  stop("Uso: Rscript busca_erv1_3_v2.R archivo.out [erv1_3.csv]")
}

ruta_entrada  <- args[1]
nombre_salida <- ifelse(length(args) >= 2, args[2], "erv1_3.csv")

# Elementos ERV a buscar (sin ERV1-3-I_DR)
erv_objetivo <- c("ERV1-12_DR-LTR", "ERV1-3-LTR_DR", "ERV1-3B_DR-LTR", "ERV1-3C_DR-LTR")

cat("Leyendo archivo...\n")

lineas <- readLines(ruta_entrada, warn = FALSE)
lineas <- gsub("\r", "", lineas)

datos  <- lineas[grepl("^\\s*[0-9]", lineas)]
partes <- strsplit(trimws(datos), "\\s+")

cromosoma <- sapply(partes, function(x) ifelse(length(x) >= 5,  gsub("^chr", "", x[5]),  NA))
id_repeat <- sapply(partes, function(x) ifelse(length(x) >= 10, x[10], NA))

df <- data.frame(cromosoma = cromosoma, id_repeat = id_repeat,
                 stringsAsFactors = FALSE)
df <- df[!is.na(df$cromosoma), ]

# Filtrar solo los ERV objetivo (coincidencia exacta)
df_erv <- df[df$id_repeat %in% erv_objetivo, ]

if (nrow(df_erv) == 0) {
  cat("No se encontraron entradas ERV.\n")
  quit(status = 0)
}

# Contar por cromosoma y tipo de ERV
conteo <- as.data.frame(table(df_erv$cromosoma, df_erv$id_repeat),
                         stringsAsFactors = FALSE)
colnames(conteo) <- c("cromosoma", "id_repeat", "total")
conteo <- conteo[conteo$total > 0, ]
conteo <- conteo[grepl("^[0-9]+$|^X$|^Y$", conteo$cromosoma), ]
conteo <- conteo[order(suppressWarnings(as.numeric(conteo$cromosoma)),
                        conteo$id_repeat, na.last = TRUE), ]

# Añadir fila TOTAL por cada tipo de ERV
totales_tipo <- aggregate(total ~ id_repeat, data = conteo, sum)
totales_tipo$cromosoma <- "TOTAL"
totales_tipo <- totales_tipo[, c("cromosoma", "id_repeat", "total")]

conteo_final <- rbind(conteo, totales_tipo)

write.csv(conteo_final, nombre_salida, row.names = FALSE)

cat("Listo. CSV guardado en:", nombre_salida, "\n")
cat("Total entradas ERV encontradas:", nrow(df_erv), "\n")