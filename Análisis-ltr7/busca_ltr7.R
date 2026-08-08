# =============================================================
# Uso desde terminal:
#   Rscript busca_ltr7_bed.R archivo.bed [ltr7.bed]
# =============================================================

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 1) {
  stop("Uso: Rscript busca_ltr7_bed.R archivo.bed [ltr7.bed]")
}

ruta_entrada  <- args[1]
nombre_salida <- ifelse(length(args) >= 2, args[2], "ltr7.bed")

# Variantes de LTR7 a buscar
sufijos_ltr7  <- c("", "A", "B", "C", "Y", "a1", "up2", "a2",
                   "B0", "B2", "B3", "D3", "u1", "YY", "up3",
                   "BC", "d1", "d2", "u2", "up1")
ltr7_objetivo <- paste0("LTR7", sufijos_ltr7)

lineas <- readLines(ruta_entrada, warn = FALSE)
lineas <- gsub("\r", "", lineas)

nombre <- sapply(strsplit(lineas, "\t"), function(x) ifelse(length(x) >= 4, x[4], NA))

bed <- lineas[!is.na(nombre) & nombre %in% ltr7_objetivo]

if (length(bed) == 0) {
  message("No se encontraron entradas LTR7.")
  quit(status = 0)
}

writeLines(bed, nombre_salida)

message("Listo. BED guardado en: ", nombre_salida)
message("Total entradas LTR7 encontradas: ", length(bed))