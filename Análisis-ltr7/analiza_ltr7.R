# =============================================================
# Uso desde terminal:
#   Rscript analiza_ltr7.R archivo1.bed archivo2.bed [resultado.txt] [tolerancia]
# =============================================================

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Uso: Rscript analiza_ltr7.R archivo1.bed archivo2.bed [resultado.txt] [tolerancia]")
}

ruta_bed1     <- args[1]
ruta_bed2     <- args[2]
nombre_salida <- ifelse(length(args) >= 3, args[3], "comparacion_bed.txt")
tolerancia    <- ifelse(length(args) >= 4, as.numeric(args[4]), 200)


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


# Dos secuencias se consideran coincidentes si se solapan
# teniendo en cuenta la tolerancia en ambos extremos
se_solapa <- function(ini1, fin1, ini2, fin2, tol) {
  (ini1 - tol) <= fin2 & (fin1 + tol) >= ini2
}


df1 <- leer_bed(ruta_bed1)
df2 <- leer_bed(ruta_bed2)

coincidentes_1 <- c()
coincidentes_2 <- c()
solo_en_1      <- c()

for (i in seq_len(nrow(df1))) {
  crom   <- df1$cromosoma[i]
  inicio <- df1$inicio[i]
  fin    <- df1$fin[i]

  idx_crom   <- which(df2$cromosoma == crom)
  candidatos <- df2[idx_crom, ]

  if (nrow(candidatos) == 0) {
    solo_en_1 <- c(solo_en_1, i)
    next
  }

  # Buscar solapamiento con tolerancia
  solapa <- se_solapa(inicio, fin, candidatos$inicio, candidatos$fin, tolerancia)

  if (any(solapa)) {
    # De los que solapan, coger el más cercano
    diffs  <- abs(candidatos$inicio - inicio) + abs(candidatos$fin - fin)
    mejor  <- which(solapa)[which.min(diffs[solapa])]
    coincidentes_1 <- c(coincidentes_1, i)
    coincidentes_2 <- c(coincidentes_2, idx_crom[mejor])
  } else {
    solo_en_1 <- c(solo_en_1, i)
  }
}

solo_en_2 <- setdiff(seq_len(nrow(df2)), coincidentes_2)

# Detectar entradas del archivo 2 usadas más de una vez
tabla_uso <- table(coincidentes_2)
repetidos <- as.integer(names(tabla_uso[tabla_uso > 1]))

sink(nombre_salida)

cat("COMPARACIÓN DE ARCHIVOS BED - LTR7\n")
cat("Tolerancia solapamiento:", tolerancia, "pb\n\n")
cat(strrep("=", 70), "\n\n")

cat("COINCIDENTES:", length(coincidentes_1), "\n")
cat(strrep("-", 70), "\n")
for (k in seq_along(coincidentes_1)) {
  r1  <- df1[coincidentes_1[k], ]
  r2  <- df2[coincidentes_2[k], ]
  rep <- ifelse(coincidentes_2[k] %in% repetidos, "  [USADO VARIAS VECES]", "")
  cat(sprintf("Archivo 1: chr%s  %d-%d  %s\n", r1$cromosoma, r1$inicio, r1$fin, r1$nombre))
  cat(sprintf("Archivo 2: chr%s  %d-%d  %s%s\n\n", r2$cromosoma, r2$inicio, r2$fin, r2$nombre, rep))
}

if (length(repetidos) > 0) {
  cat(strrep("=", 70), "\n\n")
  cat("ENTRADAS DEL ARCHIVO 2 USADAS MÁS DE UNA VEZ:", length(repetidos), "\n")
  cat(strrep("-", 70), "\n")
  for (idx in repetidos) {
    r2       <- df2[idx, ]
    usos     <- which(coincidentes_2 == idx)
    cat(sprintf("\nArchivo 2: chr%s  %d-%d  %s  [usada %d veces]\n",
                r2$cromosoma, r2$inicio, r2$fin, r2$nombre, length(usos)))
    cat("  Relacionada con:\n")
    for (u in usos) {
      r1 <- df1[coincidentes_1[u], ]
      cat(sprintf("    Archivo 1: chr%s  %d-%d  %s\n",
                  r1$cromosoma, r1$inicio, r1$fin, r1$nombre))
    }
  }
}

cat(strrep("=", 70), "\n\n")
cat("ÚNICOS EN ARCHIVO 1:", length(solo_en_1), "\n")
cat(strrep("-", 70), "\n")
for (i in solo_en_1) {
  r <- df1[i, ]
  cat(sprintf("chr%s  %d-%d  %s\n", r$cromosoma, r$inicio, r$fin, r$nombre))
}

cat("\n", strrep("=", 70), "\n\n")
cat("ÚNICOS EN ARCHIVO 2:", length(solo_en_2), "\n")
cat(strrep("-", 70), "\n")
for (i in solo_en_2) {
  r <- df2[i, ]
  cat(sprintf("chr%s  %d-%d  %s\n", r$cromosoma, r$inicio, r$fin, r$nombre))
}

sink()

message("Listo. Resultados guardados en: ", nombre_salida)
message("Coincidentes: ", length(coincidentes_1))
message("Únicos en archivo 1: ", length(solo_en_1))
message("Únicos en archivo 2: ", length(solo_en_2))
