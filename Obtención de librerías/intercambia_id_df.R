# =============================================================
# intercambiar_id_df: Sustituye el identificador DF.../DR...
#                     por el ID real en las cabeceras del FASTA
# =============================================================
# Antes: >DF000000016.4 SINE/alu 7SLRNA
# Después: >7SLRNA SINE/alu
# =============================================================
# Uso:
#   setwd("C:/Users/ALEJANDRO/ruta/a/tu/carpeta")
#   intercambiar_id_df("library_rellena_clean.fasta", "library_final.fasta")
# =============================================================


intercambiar_id_df <- function(ruta_fasta, ruta_salida) {

  lineas <- readLines(ruta_fasta, warn = FALSE)
  lineas <- gsub("\r", "", lineas)

  for (i in seq_along(lineas)) {

    if (!startsWith(lineas[i], ">")) next

    cabecera <- sub("^>", "", lineas[i])
    partes   <- strsplit(cabecera, " ")[[1]]

    if (!startsWith(partes[1], "DF") && !startsWith(partes[1], "DR")) next
    if (length(partes) < 3) next

    # id_real es la última palabra, tipo es todo lo que hay en medio
    id_real   <- tail(partes, 1)
    tipo      <- paste(partes[2:(length(partes) - 1)], collapse = " ")

    lineas[i] <- paste0(">", id_real, " ", tipo, " ", partes[1])
  }

  writeLines(lineas, ruta_salida)
  message("Listo. FASTA guardado en: ", ruta_salida)
}
