# =============================================================
# plot_clases_cromosoma: Genera una gráfica de barras apiladas
#                        con las clases por cromosoma
# =============================================================

library(ggplot2)


plot_clases_cromosoma <- function(ruta_csv, nombre_png = "plot_clases_cromosoma.png",
                                   solo_canonicos = TRUE) {

  conteo <- read.csv(ruta_csv, stringsAsFactors = FALSE)

  # Filtrar solo cromosomas canónicos (números, con o sin prefijo chr)
  if (solo_canonicos) {
    conteo <- conteo[grepl("^(chr)?[0-9]+$|^(chr)?X$|^(chr)?Y$", conteo$cromosoma), ]
  }

  # Quitar prefijo chr para ordenar numéricamente
  conteo$cromosoma_num <- gsub("^chr", "", conteo$cromosoma)

  # Ordenar cromosomas numéricamente
  cromosomas_orden <- unique(conteo$cromosoma)
  orden_idx        <- order(suppressWarnings(as.numeric(gsub("^chr", "", cromosomas_orden))),
                             na.last = TRUE)
  cromosomas_orden <- cromosomas_orden[orden_idx]
  conteo$cromosoma <- factor(conteo$cromosoma, levels = cromosomas_orden)

  # Tratar DD(E-D)_Transposons como DNA
  conteo$clase[conteo$clase == "DD(E-D)_Transposons"] <- "DNA"
  conteo <- aggregate(total ~ cromosoma + clase, data = conteo, sum)
  conteo$cromosoma <- factor(conteo$cromosoma, levels = cromosomas_orden)

  # Paleta de colores fija por clase
  colores_fijos <- c(
    "DNA"                   = "#E41A1C",
    "LINE"                  = "#FF7F00",
    "LTR"                   = "#4DAF4A",
    "SINE"                  = "#984EA3",
    "Simple_repeat"         = "#6A8DC9",
    "simple_repeat"         = "#6A8DC9",
    "Satellite"             = "#00CED1",
    "RC"                    = "#A65628",
    "Low_complexity"        = "#8B8B00",
    "Unknown"               = "#999999",
    "Non-LTR"               = "#59A14F",
    "DIRS"                  = "#B07AA1",
    "Rolling_circle"        = "#76B7B2",
    "Cryptons"              = "#FF9DA7",
    "snRNA"                 = "#9C755F",
    "transposable_element"  = "#BAB0AC",
    "tRNA"                  = "#EDC948",
    "rRNA"                  = "#D37295",
    "scRNA"                 = "#499894",
    "PLE"                   = "#1B7837",
    "Maverick-Polinton"     = "#762A83",
    "repeat_region"         = "#C7EAE5",
    "EnSpm"                 = "#DFC27D",
    "interspersed_repeat"   = "#80CDC1",
    "Inverted_repeat"       = "#F6E8C3",
    "ARTEFACT"              = "#000000",
    "DNA?"                  = "#FF6666",
    "Satellite?"            = "#66FFFF"
  )

  g <- ggplot(conteo, aes(x = cromosoma, y = total, fill = clase)) +
    geom_bar(stat = "identity") +
    scale_fill_manual(values = colores_fijos) +
    labs(title = "Distribución de clases por cromosoma",
         x = "Cromosoma", y = "Número de elementos", fill = "Clase") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
          plot.margin = margin(10, 15, 10, 15))

  ggsave(nombre_png, plot = g, width = 14, height = 6)

  message("Listo. Gráfica guardada en: ", nombre_png)
}


# ----- Llamada desde terminal -----

args       <- commandArgs(trailingOnly = TRUE)
ruta_csv   <- ifelse(length(args) >= 1, args[1], "conteo_clases_cromosoma.csv")
nombre_png <- ifelse(length(args) >= 2, args[2], "plot_clases_cromosoma.png")

plot_clases_cromosoma(ruta_csv, nombre_png)