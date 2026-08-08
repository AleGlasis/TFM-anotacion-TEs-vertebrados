# =============================================================
# Uso desde terminal:
#   Rscript sankey_ltr7.R comparacion_ltr7.txt [sankey_ltr7.png]
# =============================================================

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 1) {
  stop("Uso: Rscript sankey_ltr7.R comparacion_ltr7.txt [sankey_ltr7.png]")
}

ruta_entrada  <- args[1]
nombre_png    <- ifelse(length(args) >= 2, args[2], "sankey_ltr7.png")

# --- Instalar paquetes si no están disponibles ---
paquetes <- c("ggplot2", "ggalluvial")
for (pkg in paquetes) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org",
                     lib = .libPaths()[1])
  }
}

library(ggplot2)
library(ggalluvial)

# --- Parsear pares coincidentes ---
lineas  <- readLines(ruta_entrada, warn = FALSE)
lineas  <- gsub("\r", "", lineas)

idx_arch1 <- grep("^Archivo 1:", lineas)
idx_arch2 <- grep("^Archivo 2:", lineas)

# Solo los pares dentro de la sección COINCIDENTES
fin_coinc <- grep("^={3,}", lineas)
fin_coinc <- fin_coinc[fin_coinc > grep("^COINCIDENTES:", lineas)[1]][1]

idx_arch1 <- idx_arch1[idx_arch1 < fin_coinc]
idx_arch2 <- idx_arch2[idx_arch2 < fin_coinc]

extraer_nombre <- function(linea) {
  partes <- strsplit(trimws(linea), "\\s+")[[1]]
  return(partes[length(partes)])
}

muestra <- sapply(lineas[idx_arch1], extraer_nombre, USE.NAMES = FALSE)
control <- sapply(lineas[idx_arch2], extraer_nombre, USE.NAMES = FALSE)

pares <- data.frame(muestra = muestra, control = control,
                    stringsAsFactors = FALSE)

# --- Agregar frecuencias ---
conteo <- as.data.frame(table(pares$muestra, pares$control),
                         stringsAsFactors = FALSE)
colnames(conteo) <- c("muestra", "control", "freq")
conteo <- conteo[conteo$freq > 0, ]

# Ordenar variantes por frecuencia total
ord_muestra <- names(sort(tapply(conteo$freq, conteo$muestra, sum), decreasing = TRUE))
ord_control <- names(sort(tapply(conteo$freq, conteo$control, sum), decreasing = TRUE))

conteo$muestra <- factor(conteo$muestra, levels = ord_muestra)
conteo$control <- factor(conteo$control, levels = ord_control)

# --- Colores por variante (paleta LTR7 establecida) ---
sufijos_ltr7   <- c("", "A", "B", "C", "Y", "a1", "up2", "a2",
                    "B0", "B2", "B3", "D3", "u1", "YY", "up3",
                    "BC", "d1", "d2", "u2", "up1")
variantes_ltr7 <- paste0("LTR7", sufijos_ltr7)

colores_ltr7 <- c(
  "LTR7"    = "#1B9E77", "LTR7A"   = "#D95F02", "LTR7B"   = "#7570B3",
  "LTR7C"   = "#E7298A", "LTR7Y"   = "#66A61E", "LTR7a1"  = "#E6AB02",
  "LTR7up2" = "#A6761D", "LTR7a2"  = "#666666", "LTR7B0"  = "#E41A1C",
  "LTR7B2"  = "#377EB8", "LTR7B3"  = "#4DAF4A", "LTR7D3"  = "#984EA3",
  "LTR7u1"  = "#FF7F00", "LTR7YY"  = "#A65628", "LTR7up3" = "#F781BF",
  "LTR7BC"  = "#999999", "LTR7d1"  = "#8DD3C7", "LTR7d2"  = "#FFFFB3",
  "LTR7u2"  = "#BEBADA", "LTR7up1" = "#FB8072"
)

# Colorear por variante del archivo muestra (lado izquierdo)
variantes_presentes <- intersect(variantes_ltr7, unique(conteo$muestra))
colores_uso         <- colores_ltr7[variantes_presentes]

# --- Gráfica Sankey ---
g <- ggplot2::ggplot(
  conteo,
  ggplot2::aes(
    axis1 = muestra,
    axis2 = control,
    y     = freq
  )
) +
  ggalluvial::geom_alluvium(
    ggplot2::aes(fill = muestra),
    width = 0.3, alpha = 0.75, curve_type = "sigmoid"
  ) +
  ggalluvial::geom_stratum(width = 0.3, fill = "gray95", color = "gray50") +
  ggplot2::geom_text(
    stat = ggalluvial::StatStratum,
    ggplot2::aes(label = ggplot2::after_stat(stratum)),
    size = 3
  ) +
  ggplot2::scale_fill_manual(values = colores_uso, guide = "none") +
  ggplot2::scale_x_discrete(
    limits = c("muestra", "control"),
    labels = c("Muestra", "Control"),
    expand = ggplot2::expansion(mult = c(0.1, 0.1))
  ) +
  ggplot2::labs(
    title = "Correspondencia de variantes LTR7 entre Muestra y Control",
    y     = "Número de elementos"
  ) +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(
    axis.text.x  = ggplot2::element_text(face = "bold", size = 12),
    panel.grid   = ggplot2::element_blank(),
    plot.title   = ggplot2::element_text(face = "bold", size = 13)
  )

ggplot2::ggsave(nombre_png, plot = g, width = 10, height = 12, dpi = 150)

message("Listo. Sankey guardado en: ", nombre_png)
