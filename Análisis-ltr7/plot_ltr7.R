#!/usr/bin/env Rscript

# ==============================================================================
# Uso desde bash:
#   Rscript plot_ltr7.R <ruta_archivo> [ruta_salida.png] [umbral_%]
#
# Ejemplos:
#   Rscript plot_ltr7.R vecinos_ltr7.txt
#   Rscript plot_ltr7.R vecinos_ltr7.txt mi_grafica.png 1
#   Rscript plot_ltr7.R vecinos_ltr7.txt mi_grafica.png 2.5
# ==============================================================================

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 1) {
  stop("Uso: Rscript plot_ltr7.R <ruta_archivo> [ruta_salida.png] [umbral_%]")
}

ruta_archivo <- args[1]
ruta_salida  <- ifelse(length(args) >= 2, args[2], "vecinos_archivo2.png")
umbral_pct   <- ifelse(length(args) >= 3, as.numeric(args[3]), 1)  # por defecto 1%

# --- 1. Leer todas las líneas del archivo ---
lineas <- readLines(ruta_archivo)

# --- 2. Localizar la sección de interés ---
inicio <- which(grepl("ÚNICOS DE ARCHIVO 2 Y SU VECINO MÁS CERCANO EN EL ARCHIVO 1", lineas))

if (length(inicio) == 0) {
  stop("No se encontró la sección 'ÚNICOS DE ARCHIVO 2 Y SU VECINO MÁS CERCANO EN EL ARCHIVO 1'")
}

lineas_seccion <- lineas[inicio:length(lineas)]

# --- 3. Extraer el 4º elemento de las líneas "Vecino:" ---
lineas_vecino <- lineas_seccion[grepl("^Vecino:", lineas_seccion)]

nombres_vecino <- sapply(lineas_vecino, function(linea) {
  partes <- strsplit(trimws(linea), "\\s+")[[1]]
  if (length(partes) >= 4) partes[4] else NA_character_
}, USE.NAMES = FALSE)

nombres_vecino <- nombres_vecino[!is.na(nombres_vecino)]

# --- 4. Contar frecuencias y calcular proporciones ---
conteos <- as.data.frame(table(nombres_vecino), stringsAsFactors = FALSE)
colnames(conteos) <- c("nombre", "n")
conteos <- conteos[order(conteos$n, decreasing = TRUE), ]
conteos$proporcion <- conteos$n / sum(conteos$n)

# --- 5. Aplicar umbral ---
total_antes   <- nrow(conteos)
conteos       <- conteos[conteos$proporcion * 100 >= umbral_pct, ]
total_despues <- nrow(conteos)

message(sprintf(
  "Umbral: >= %.1f%% | Categorías mostradas: %d / %d",
  umbral_pct, total_despues, total_antes
))

if (nrow(conteos) == 0) {
  stop("Ninguna categoría supera el umbral del ", umbral_pct, "%. Prueba con un valor menor.")
}

# --- 6. Graficar ---
library(ggplot2)
library(scales)

conteos$nombre <- factor(conteos$nombre, levels = rev(conteos$nombre))

subtitulo <- sprintf(
  "Secuencias únicas del archivo 2  |  umbral: ≥ %.1f%%  (%d de %d categorías)",
  umbral_pct, total_despues, total_antes
)

grafica <- ggplot2::ggplot(
  data    = conteos,
  mapping = ggplot2::aes(x = nombre, y = proporcion)
) +
  ggplot2::geom_bar(
    stat  = "identity",
    fill  = "#2E86AB",
    color = "white",
    width = 0.7
  ) +
  ggplot2::geom_text(
    mapping = ggplot2::aes(label = paste0(round(proporcion * 100, 1), "%")),
    hjust = -0.1,
    size  = 3
  ) +
  ggplot2::scale_y_continuous(
    labels = scales::percent_format(accuracy = 1),
    expand = ggplot2::expansion(mult = c(0, 0.15))
  ) +
  ggplot2::coord_flip() +
  ggplot2::labs(
    title    = "Vecinos más cercanos en archivo 1 (LTR7)",
    subtitle = subtitulo,
    x = NULL,
    y = "Proporción"
  ) +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(
    plot.title         = ggplot2::element_text(face = "bold", size = 13),
    plot.subtitle      = ggplot2::element_text(color = "gray40", size = 9),
    panel.grid.major.y = ggplot2::element_blank(),
    axis.text.y        = ggplot2::element_text(size = 9)
  )

# --- 7. Guardar ---
ggplot2::ggsave(
  filename = ruta_salida,
  plot     = grafica,
  width    = 10,
  height   = max(4, nrow(conteos) * 0.35),
  dpi      = 150
)

message("Gráfica guardada en: ", ruta_salida)
