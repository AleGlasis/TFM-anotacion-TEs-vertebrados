# =============================================================
# buscar_vecino_unico: Para cada secuencia única del archivo de
#                      comparación, busca la más parecida en
#                      su archivo BED original
# =============================================================
# Uso:
#   Rscript buscar_vecino_ltr7.R comparacion.txt bed1.bed bed2.bed [salida.txt]
# =============================================================

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 3) {
  stop("Uso: Rscript buscar_vecino_ltr7.R comparacion.txt bed1.bed bed2.bed [salida.txt]")
}

ruta_comp     <- args[1]
ruta_bed1     <- args[2]
ruta_bed2     <- args[3]
nombre_salida <- ifelse(length(args) >= 4, args[4], "vecinos_unicos.txt")


# ----- FUNCIÓN AUXILIAR: leer BED -----

leer_bed <- function(ruta) {
  lineas <- readLines(ruta, warn = FALSE)
  lineas <- gsub("\r", "", lineas)
  lineas <- lineas[nchar(trimws(lineas)) > 0]
  partes <- strsplit(lineas, "\t")
  df <- data.frame(
    cromosoma = trimws(gsub("^chr", "", sapply(partes, `[`, 1))),
    inicio    = as.numeric(trimws(sapply(partes, `[`, 2))),
    fin       = as.numeric(trimws(sapply(partes, `[`, 3))),
    nombre    = trimws(sapply(partes, `[`, 4)),
    stringsAsFactors = FALSE
  )
  return(df[!is.na(df$inicio), ])
}


# ----- FUNCIÓN AUXILIAR: parsear únicos del archivo de comparación -----

parsear_unicos <- function(ruta) {
  lineas  <- readLines(ruta, warn = FALSE)
  lineas  <- gsub("\r", "", lineas)

  unicos1 <- c()
  unicos2 <- c()
  seccion <- ""

  for (linea in lineas) {
    if (grepl("^ÚNICOS EN ARCHIVO 1:", linea)) { seccion <- "uni1"; next }
    if (grepl("^ÚNICOS EN ARCHIVO 2:", linea)) { seccion <- "uni2"; next }
    if (grepl("^=+|^-+", trimws(linea)))       next

    if (seccion == "uni1" && nchar(trimws(linea)) > 0) unicos1 <- c(unicos1, trimws(linea))
    if (seccion == "uni2" && nchar(trimws(linea)) > 0) unicos2 <- c(unicos2, trimws(linea))
  }

  return(list(unicos1 = unicos1, unicos2 = unicos2))
}


# ----- FUNCIÓN AUXILIAR: parsear una línea de único -----

parsear_linea <- function(linea) {
  # Formato: chr1  34345504-34345642  LTR7A
  partes    <- strsplit(trimws(linea), "\\s+")[[1]]
  crom      <- gsub("^chr", "", partes[1])
  posiciones <- strsplit(partes[2], "-")[[1]]
  inicio    <- as.numeric(posiciones[1])
  fin       <- as.numeric(posiciones[2])
  nombre    <- partes[3]
  return(list(cromosoma = crom, inicio = inicio, fin = fin, nombre = nombre))
}


# ----- FUNCIÓN AUXILIAR: buscar vecino más cercano en un BED -----

buscar_vecino <- function(crom, inicio, fin, df_bed) {
  # Primero buscar en el mismo cromosoma
  mismo_crom <- df_bed[df_bed$cromosoma == crom, ]

  if (nrow(mismo_crom) > 0) {
    diffs <- abs(mismo_crom$inicio - inicio) + abs(mismo_crom$fin - fin)
    mejor <- which.min(diffs)
    return(list(
      cromosoma  = mismo_crom$cromosoma[mejor],
      inicio     = mismo_crom$inicio[mejor],
      fin        = mismo_crom$fin[mejor],
      nombre     = mismo_crom$nombre[mejor],
      diff       = diffs[mejor],
      mismo_crom = TRUE
    ))
  } else {
    # Si no hay entradas en ese cromosoma, buscar en todo el archivo
    diffs <- abs(df_bed$inicio - inicio) + abs(df_bed$fin - fin)
    mejor <- which.min(diffs)
    return(list(
      cromosoma  = df_bed$cromosoma[mejor],
      inicio     = df_bed$inicio[mejor],
      fin        = df_bed$fin[mejor],
      nombre     = df_bed$nombre[mejor],
      diff       = diffs[mejor],
      mismo_crom = FALSE
    ))
  }
}


# ----- Ejecutar -----

bed1   <- leer_bed(ruta_bed1)
bed2   <- leer_bed(ruta_bed2)
unicos <- parsear_unicos(ruta_comp)

sink(nombre_salida)

cat("VECINOS MÁS CERCANOS DE LAS SECUENCIAS ÚNICAS\n\n")

cat(strrep("=", 70), "\n")
cat("ÚNICOS DE ARCHIVO 1 Y SU VECINO MÁS CERCANO EN EL ARCHIVO 2\n")
cat(strrep("-", 70), "\n\n")

for (linea in unicos$unicos1) {
  s      <- parsear_linea(linea)
  vecino <- buscar_vecino(s$cromosoma, s$inicio, s$fin, bed2)
  aviso  <- ifelse(!vecino$mismo_crom, "  [distinto cromosoma]", "")
  cat(sprintf("Única:   chr%s  %d-%d  %s\n", s$cromosoma, s$inicio, s$fin, s$nombre))
  cat(sprintf("Vecino:  chr%s  %d-%d  %s  [dif: %d pb]%s\n\n",
              vecino$cromosoma, vecino$inicio, vecino$fin, vecino$nombre,
              vecino$diff, aviso))
}

cat(strrep("=", 70), "\n")
cat("ÚNICOS DE ARCHIVO 2 Y SU VECINO MÁS CERCANO EN EL ARCHIVO 1\n")
cat(strrep("-", 70), "\n\n")

for (linea in unicos$unicos2) {
  s      <- parsear_linea(linea)
  vecino <- buscar_vecino(s$cromosoma, s$inicio, s$fin, bed1)
  aviso  <- ifelse(!vecino$mismo_crom, "  [distinto cromosoma]", "")
  cat(sprintf("Única:   chr%s  %d-%d  %s\n", s$cromosoma, s$inicio, s$fin, s$nombre))
  cat(sprintf("Vecino:  chr%s  %d-%d  %s  [dif: %d pb]%s\n\n",
              vecino$cromosoma, vecino$inicio, vecino$fin, vecino$nombre,
              vecino$diff, aviso))
}

sink()

message("Listo. Resultados guardados en: ", nombre_salida)
