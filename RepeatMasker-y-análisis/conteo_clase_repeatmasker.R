# =============================================================
# Uso desde terminal:
#   Rscript conteo_clase_repeatmasker.R archivo.out conteo.csv
# =============================================================

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 1) {
  stop("Uso: Rscript conteo_clase_repeatmasker.R archivo.out [conteo.csv]")
}

ruta_entrada  <- args[1]
nombre_salida <- ifelse(length(args) >= 2, args[2], "conteo_clases_cromosoma.csv")

lineas <- readLines(ruta_entrada, warn = FALSE)
lineas <- gsub("\r", "", lineas)

datos <- lineas[grepl("^\\s*[0-9]", lineas)]

partes     <- strsplit(trimws(datos), "\\s+")
cromosomas <- sapply(partes, function(x) ifelse(length(x) >= 5,  x[5],  NA))
clase_fam  <- sapply(partes, function(x) ifelse(length(x) >= 11, x[11], NA))
clases     <- sub("/.*", "", clase_fam)

df     <- data.frame(cromosoma = cromosomas, clase = clases, stringsAsFactors = FALSE)
df     <- df[!is.na(df$cromosoma) & !is.na(df$clase), ]

conteo <- as.data.frame(table(df$cromosoma, df$clase), stringsAsFactors = FALSE)
colnames(conteo) <- c("cromosoma", "clase", "total")
conteo <- conteo[conteo$total > 0, ]
conteo <- conteo[order(conteo$cromosoma, -conteo$total), ]

write.csv(conteo, nombre_salida, row.names = FALSE)

cat("Listo. Conteo guardado en:", nombre_salida, "\n")