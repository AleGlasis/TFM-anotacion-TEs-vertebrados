# =============================================================
# Uso desde terminal:
#   Rscript comparar_ltr7.R muestra.csv control.csv organismo [comparacion.png]
#
# Formato CSV esperado:
#   name, chrom, chromStart, chromEnd, score, strand, div_media
# =============================================================

library(ggplot2)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 3) {
  stop("Uso: Rscript comparar_ltr7.R muestra.csv control.csv organismo [comparacion.png]")
}

ruta_muestra  <- args[1]
ruta_control  <- args[2]
organismo     <- args[3]
nombre_png    <- ifelse(length(args) >= 4, args[4], "comparacion_ltr7.png")

# ── Variantes LTR7 ────────────────────────────────────────────────────────────
sufijos_ltr7   <- c("", "A", "B", "C", "Y", "a1", "up2", "a2",
                    "B0", "B2", "B3", "D3", "u1", "YY", "up3",
                    "BC", "d1", "d2", "u2", "up1")
variantes_ltr7 <- paste0("LTR7", sufijos_ltr7)

# ── Lectura CSV ───────────────────────────────────────────────────────────────
leer_csv <- function(ruta, condicion) {
  df           <- read.csv(ruta, stringsAsFactors = FALSE)
  colnames(df) <- c("id_repeat", "cromosoma", "inicio", "fin",
                    "score", "strand", "div_media")
  df$cromosoma <- gsub("^chr", "", df$cromosoma)
  df           <- df[grepl("^[0-9]+$|^X$|^Y$", df$cromosoma), ]
  conteo       <- as.data.frame(table(df$cromosoma, df$id_repeat),
                                stringsAsFactors = FALSE)
  colnames(conteo) <- c("cromosoma", "id_repeat", "total")
  conteo           <- conteo[conteo$total > 0, ]
  # Añadir div_media: un valor único por variante
  div_ref          <- unique(df[, c("id_repeat", "div_media")])
  conteo           <- merge(conteo, div_ref, by = "id_repeat", all.x = TRUE)
  conteo$condicion <- condicion
  return(conteo)
}

df_muestra <- leer_csv(ruta_muestra, "New annotation")
df_control <- leer_csv(ruta_control, "USCS")
datos      <- rbind(df_muestra, df_control)

# ── Ordenar cromosomas numéricamente ──────────────────────────────────────────
todos_crom      <- unique(datos$cromosoma)
todos_crom      <- todos_crom[order(suppressWarnings(as.numeric(todos_crom)), na.last = TRUE)]
datos$cromosoma <- factor(datos$cromosoma, levels = todos_crom)
datos$condicion <- factor(datos$condicion, levels = c("New annotation", "USCS"))

# ── Gradiente rojo → azul por divergencia media ───────────────────────────────
variantes_presentes <- intersect(variantes_ltr7, unique(datos$id_repeat))

# Tabla de divergencia media única por variante (una sola fila por variante)
# Se usa tapply para evitar duplicados cuando muestra y control tienen el mismo valor
div_sub       <- datos[datos$id_repeat %in% variantes_presentes & !is.na(datos$div_media), ]
div_media_vec <- tapply(div_sub$div_media, div_sub$id_repeat, mean, na.rm = TRUE)
div_tabla     <- data.frame(
  id_repeat = names(div_media_vec),
  div_media = as.numeric(div_media_vec),
  stringsAsFactors = FALSE
)

div_min  <- min(div_tabla$div_media)
div_max  <- max(div_tabla$div_media)
div_norm <- (div_tabla$div_media - div_min) / (div_max - div_min)

# rojo = más viejo (divergencia alta), azul = más joven (divergencia baja)
paleta          <- colorRampPalette(c("#2C7BB6", "#F46D43", "#8B0000"))
colores_gradiente <- paleta(1000)
indices         <- round(div_norm * 999) + 1

colores_uso <- stats::setNames(colores_gradiente[indices], div_tabla$id_repeat)

# Variantes sin div_media → gris
sin_div <- setdiff(variantes_presentes, names(colores_uso))
if (length(sin_div) > 0) {
  colores_uso[sin_div] <- "#AAAAAA"
}

# Ordenar variantes de más vieja (rojo) a más joven (azul)
ord_variantes <- div_tabla$id_repeat[order(div_tabla$div_media, decreasing = TRUE)]
ord_variantes <- c(ord_variantes, sin_div)

datos$id_repeat <- factor(datos$id_repeat, levels = ord_variantes)

# ── Gráfica ───────────────────────────────────────────────────────────────────
n_crom <- length(todos_crom)

g <- ggplot2::ggplot(
  datos,
  ggplot2::aes(x = condicion, y = total, fill = id_repeat)
) +
  ggplot2::geom_bar(stat = "identity", position = "stack", width = 0.7) +
  ggplot2::facet_wrap(~ cromosoma, nrow = 1) +
  ggplot2::scale_fill_manual(values = colores_uso, name = "Variante LTR7") +
  ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.12))) +
  ggplot2::labs(
    title    = paste("Comparación LTR7 por cromosoma -", organismo),
    subtitle = "Color: rojo = más viejo  |  azul = más joven  (divergencia Kimura media)",
    x        = NULL,
    y        = "Número de elementos"
  ) +
  ggplot2::theme_minimal(base_size = 9) +
  ggplot2::theme(
    axis.text.x      = ggplot2::element_text(angle = 45, hjust = 1, size = 7),
    strip.text       = ggplot2::element_text(face = "bold", size = 9),
    strip.background = ggplot2::element_rect(fill = "gray92", color = NA),
    legend.key.size  = ggplot2::unit(0.4, "cm"),
    legend.text      = ggplot2::element_text(size = 8),
    plot.margin      = ggplot2::margin(10, 15, 10, 15),
    panel.spacing    = ggplot2::unit(0.3, "cm"),
    plot.subtitle    = ggplot2::element_text(color = "gray40", size = 8)
  )

ggplot2::ggsave(nombre_png, plot = g,
                width  = max(14, n_crom * 1.2),
                height = 6,
                dpi    = 150)

message("Listo. Gráfica guardada en: ", nombre_png)