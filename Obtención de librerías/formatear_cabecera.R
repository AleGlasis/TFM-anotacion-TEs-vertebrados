# =============================================================
# formatear_cabecera: Reformatea las cabeceras del FASTA al
#                     formato id#clase/familia
# =============================================================
# Antes: >(A)n simple_repeat
# Después: >(A)n#simple_repeat
#
# Antes: >Academ-1_DR DD(E/D)_Transposons/academ
# Después: >Academ-1_DR#DD(E/D)_Transposons/academ
# =============================================================
# Uso:
#   setwd("ruta/a/tu/carpeta")
#   formatear_cabecera("library.fasta", "library_formateada.fasta")
# =============================================================


formatear_cabecera <- function(ruta_fasta, ruta_salida) {

  lineas <- readLines(ruta_fasta, warn = FALSE)
  lineas <- gsub("\r", "", lineas)

  for (i in seq_along(lineas)) {

    if (!startsWith(lineas[i], ">")) next

    cabecera <- sub("^>", "", lineas[i])
    partes   <- strsplit(cabecera, " ")[[1]]

    if (length(partes) < 2) next

    id   <- partes[1]
    tipo <- paste(partes[-1], collapse = " ")

    # Reconstruir con "#" entre id y tipo
    lineas[i] <- paste0(">", id, "#", tipo)
  }

  writeLines(lineas, ruta_salida)
  message("Listo. FASTA guardado en: ", ruta_salida)
}
