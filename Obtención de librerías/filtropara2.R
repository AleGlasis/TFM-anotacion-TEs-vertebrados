# =============================================================
# filtropara2: Filtra duplicados de ID y secuencia entre dos
#              archivos FASTA y genera una librería única
# =============================================================
# - archivo 1: ID es la primera parte después del ">"
# - archivo 2: ID es la segunda parte después del ">"
#              excepto entradas DF/DR: ID es la tercera parte
# =============================================================
# Uso:
#   filtropara2("archivo1.fasta", "archivo2.fasta")
# =============================================================

library(ggplot2)
library(gridExtra)


filtropara2 <- function(ruta_fasta1, ruta_fasta2) {


  # ----- FUNCIÓN AUXILIAR: leer un archivo FASTA -----

  leer_fasta <- function(ruta) {
    lineas    <- readLines(ruta, warn = FALSE)
    lineas    <- gsub("\r", "", lineas)
    cabeceras <- grep("^>", lineas)
    ids       <- sub("^>", "", lineas[cabeceras])

    secuencias <- sapply(seq_along(cabeceras), function(i) {
      inicio <- cabeceras[i] + 1
      fin    <- ifelse(i < length(cabeceras), cabeceras[i + 1] - 1, length(lineas))
      paste(lineas[inicio:fin], collapse = "")
    })

    data.frame(id_completo = ids, secuencia = secuencias, stringsAsFactors = FALSE)
  }


  # ----- FUNCIÓN AUXILIAR: extraer ID según el tipo de entrada -----

  extraer_id <- function(id_completo, posicion_defecto) {
    partes <- strsplit(id_completo, "\\s+")[[1]]
    if (startsWith(partes[1], "DF") || startsWith(partes[1], "DR")) {
      return(tail(partes, 1))
    } else {
      return(ifelse(length(partes) >= posicion_defecto, partes[posicion_defecto], partes[1]))
    }
  }


  # ----- FUNCIÓN AUXILIAR: extraer tipo según el tipo de entrada -----

  extraer_tipo <- function(id_completo, posicion_defecto) {
    partes <- strsplit(id_completo, "\\s+")[[1]]
    if (startsWith(partes[1], "DF") || startsWith(partes[1], "DR")) {
      return(paste(partes[2:(length(partes) - 1)], collapse = " "))
    } else {
      otras <- partes[-posicion_defecto]
      return(ifelse(length(otras) > 0, paste(otras, collapse = " "), NA))
    }
  }


  # ----- MÓDULO 1: leer archivos y extraer IDs -----

  datos1      <- leer_fasta(ruta_fasta1)
  datos1$id   <- sapply(datos1$id_completo, extraer_id,   posicion_defecto = 1)
  datos1$tipo <- sapply(datos1$id_completo, extraer_tipo, posicion_defecto = 1)

  datos2      <- leer_fasta(ruta_fasta2)
  datos2$id   <- sapply(datos2$id_completo, extraer_id,   posicion_defecto = 2)
  datos2$tipo <- sapply(datos2$id_completo, extraer_tipo, posicion_defecto = 2)

  sink("ids_total.txt")
  cat("ARCHIVO 1 - IDs extraídos\n")
  cat(paste(datos1$id, collapse = "\n"), "\n\n")
  cat("ARCHIVO 2 - IDs extraídos\n")
  cat(paste(datos2$id, collapse = "\n"), "\n")
  sink()

  message("Modulo 1 listo.")


  # ----- MÓDULO 2: detectar IDs duplicados -----

  ids_dup_internos1 <- datos1[duplicated(datos1$id) | duplicated(datos1$id, fromLast = TRUE), ]
  ids_dup_internos2 <- datos2[duplicated(datos2$id) | duplicated(datos2$id, fromLast = TRUE), ]

  datos1 <- datos1[!duplicated(datos1$id), ]
  datos2 <- datos2[!duplicated(datos2$id), ]

  ids_duplicados  <- datos2[datos2$id %in% datos1$id, ]
  datos2_id_unico <- datos2[!datos2$id %in% datos1$id, ]

  sink("ids_unicos_dfam.txt")
  cat("IDs ÚNICOS EN ARCHIVO 2:", nrow(datos2_id_unico), "\n\n")
  cat(paste(datos2_id_unico$id, collapse = "\n"), "\n")
  sink()

  sink("duplicados_ids.txt")
  cat("IDs DUPLICADOS INTERNOS ARCHIVO 1:", nrow(ids_dup_internos1), "\n")
  for (i in seq_len(nrow(ids_dup_internos1))) {
    cat(sprintf("ID: %-30s | Tipo: %s\n", ids_dup_internos1$id[i], ids_dup_internos1$tipo[i]))
  }
  cat("\nIDs DUPLICADOS INTERNOS ARCHIVO 2:", nrow(ids_dup_internos2), "\n")
  for (i in seq_len(nrow(ids_dup_internos2))) {
    cat(sprintf("ID: %-30s | Tipo: %s\n", ids_dup_internos2$id[i], ids_dup_internos2$tipo[i]))
  }
  cat("\nIDs DUPLICADOS ENTRE ARCHIVOS:", nrow(ids_duplicados), "\n")
  for (i in seq_len(nrow(ids_duplicados))) {
    cat(sprintf("ID: %-30s | Tipo: %s\n", ids_duplicados$id[i], ids_duplicados$tipo[i]))
  }
  sink()

  message("Modulo 2 listo.")


  # ----- MÓDULO 3: detectar secuencias duplicadas -----

  seqs_dup_internos1 <- datos1[duplicated(datos1$secuencia) | duplicated(datos1$secuencia, fromLast = TRUE), ]
  seqs_dup_internos2 <- datos2[duplicated(datos2$secuencia) | duplicated(datos2$secuencia, fromLast = TRUE), ]

  datos1 <- datos1[!duplicated(datos1$secuencia), ]
  datos2 <- datos2[!duplicated(datos2$secuencia), ]

  n_arch1_limpio <- nrow(datos1)
  n_arch2_limpio <- nrow(datos2)

  seqs_duplicadas  <- datos2_id_unico[datos2_id_unico$secuencia %in% datos1$secuencia, ]
  datos2_seq_unica <- datos2_id_unico[!datos2_id_unico$secuencia %in% datos1$secuencia, ]

  sink("duplicados_seq.txt")
  cat("SECUENCIAS DUPLICADAS INTERNAS ARCHIVO 1:", nrow(seqs_dup_internos1), "\n\n")
  for (i in seq_len(nrow(seqs_dup_internos1))) {
    cat("ID:", seqs_dup_internos1$id[i], "\n")
    cat("SECUENCIA:", seqs_dup_internos1$secuencia[i], "\n\n")
  }

  cat("SECUENCIAS DUPLICADAS INTERNAS ARCHIVO 2:", nrow(seqs_dup_internos2), "\n\n")
  for (i in seq_len(nrow(seqs_dup_internos2))) {
    cat("ID:", seqs_dup_internos2$id[i], "\n")
    cat("SECUENCIA:", seqs_dup_internos2$secuencia[i], "\n\n")
  }

  cat("SECUENCIAS DUPLICADAS ENTRE ARCHIVOS:", nrow(seqs_duplicadas), "\n\n")
  for (i in seq_len(nrow(seqs_duplicadas))) {
    id_archivo1 <- datos1$id[datos1$secuencia == seqs_duplicadas$secuencia[i]]
    cat("ID archivo 2:", seqs_duplicadas$id[i], "\n")
    cat("ID archivo 1:", id_archivo1, "\n")
    cat("SECUENCIA:   ", seqs_duplicadas$secuencia[i], "\n\n")
  }
  sink()

  message("Modulo 3 listo.")


  # ----- MÓDULO 4: generar librería final -----

  library_dr <- rbind(
    datos1[, c("id_completo", "secuencia")],
    datos2_seq_unica[, c("id_completo", "secuencia")]
  )

  sink("library.fasta")
  for (i in seq_len(nrow(library_dr))) {
    cat(">", library_dr$id_completo[i], "\n", sep = "")
    cat(library_dr$secuencia[i], "\n", sep = "")
  }
  sink()

  message("Modulo 4 listo.")


  # ----- MÓDULO 5: gráficas -----

  # Límites fijos globales para comparabilidad entre organismos
  X_MAX_GLOBAL <- 16000
  Y_MAX_GLOBAL <- 2200

  n_arch1       <- n_arch1_limpio
  n_arch2       <- n_arch2_limpio
  n_dup_id      <- nrow(ids_duplicados)
  n_dup_seq     <- nrow(seqs_duplicadas)
  n_final       <- nrow(library_dr)
  n_arch2_unico <- nrow(datos2_seq_unica)

  g1 <- ggplot(data.frame(origen = c("Archivo 1", "Archivo 2"),
                           total  = c(n_arch1, n_arch2_unico)),
               aes(x = origen, y = total, fill = origen)) +
    geom_bar(stat = "identity", width = 0.5) +
    geom_text(aes(label = total), vjust = -1, size = 3.5) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
    labs(title = "Composición de la librería final",
         x = "Origen", y = "Número de secuencias") +
    theme_minimal() +
    theme(legend.position = "none", plot.margin = margin(10, 15, 10, 15))

  df_filtrado       <- data.frame(
    etapa = c("Archivo 1", "Archivo 2", "Dup. ID", "Dup. Seq.", "Lib. final"),
    total = c(n_arch1, n_arch2, n_dup_id, n_dup_seq, n_final)
  )
  df_filtrado$etapa <- factor(df_filtrado$etapa, levels = df_filtrado$etapa)

  g2 <- ggplot(df_filtrado, aes(x = etapa, y = total, fill = etapa)) +
    geom_bar(stat = "identity", width = 0.6) +
    geom_text(aes(label = total), vjust = -1, size = 3.5) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
    labs(title = "Resumen del filtrado",
         x = "Etapa", y = "Número de secuencias") +
    theme_minimal() +
    theme(legend.position = "none", axis.text.x = element_text(size = 8),
          plot.margin = margin(10, 15, 10, 15))

  longitudes_g3 <- nchar(library_dr$secuencia)

  g3 <- ggplot(data.frame(longitud = longitudes_g3), aes(x = longitud)) +
    geom_histogram(bins = 50, fill = "steelblue", color = "white") +
    scale_x_continuous(
      expand = expansion(mult = c(0.01, 0.05)),
      limits = c(0, X_MAX_GLOBAL),
      breaks = seq(0, X_MAX_GLOBAL, by = 4000)
    ) +
    scale_y_continuous(
      expand = expansion(mult = c(0, 0.05)),
      limits = c(0, Y_MAX_GLOBAL),
      breaks = seq(0, Y_MAX_GLOBAL, by = 500)
    ) +
    labs(title = "Distribución de longitudes de secuencia",
         x = "Longitud (bp)", y = "Número de secuencias") +
    theme_minimal() +
    theme(plot.margin = margin(10, 15, 10, 15))

  df_prop <- data.frame(
    categoria = c("Únicos archivo 1", "Únicos archivo 2", "Dup. por ID", "Dup. por secuencia"),
    total     = c(n_arch1, n_arch2_unico, n_dup_id, n_dup_seq)
  )

  g4 <- ggplot(df_prop, aes(x = "", y = total, fill = categoria)) +
    geom_bar(stat = "identity", width = 1) +
    coord_polar("y") +
    geom_text(aes(label = paste0(round(total / sum(total) * 100, 1), "%")),
              position = position_stack(vjust = 0.5), size = 3.5) +
    labs(title = "Proporción de duplicados", fill = "Categoría") +
    theme_void() +
    theme(plot.title = element_text(hjust = 0.5), plot.margin = margin(10, 15, 10, 15))

  png("graficas_filtrado.png", width = 1600, height = 1400, res = 150)
  grid.arrange(g1, g2, g3, g4, ncol = 2, top = "Resumen filtropara2")
  dev.off()

  message("Modulo 5 listo. Graficas guardadas en: graficas_filtrado.png")
}