# =============================================================
# Uso desde terminal:
#   Rscript comparar_erv1_3_v2.R muestra.csv control.csv organismo [comparacion.png]
#
# Formato CSV esperado (generado por calcular_div_media_erv1_3.R):
#   id_repeat, cromosoma, total, div_media
# =============================================================

library(ggplot2)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 3) {
  stop("Uso: Rscript comparar_erv1_3_v2.R muestra.csv control.csv organismo [comparacion.png]")
}

ruta_muestra  <- args[1]
ruta_control  <- args[2]
organismo     <- args[3]
nombre_png    <- ifelse(length(args) >= 4, args[4], "comparacion_erv1_3_v2.png")

# ── Variantes ERV1-3 ──────────────────────────────────────────────────────────
variantes_erv <- c("ERV1-12_DR-LTR", "ERV1-3-LTR_DR", "ERV1-3B_DR-LTR", "ERV1-3C_DR-LTR")

# ── Colores fijos según árbol filogenético ────────────────────────────────────
# ERV1-3C_DR-LTR  → teal/cyan   (clade superior del árbol)
# ERV1-3B_DR-LTR  → verde oliva (clade medio del árbol)
# ERV1-3-LTR_DR   → morado      (clade inferior/basal del árbol)
# ERV1-12_DR-LTR  → gradiente por divergencia Kimura (no aparece en el árbol)
colores_fijos <- c(
  "ERV1-3C_DR-LTR" = "#2ABEBE",   # teal
  "ERV1-3B_DR-LTR" = "#8DB83A",   # verde oliva
  "ERV1-3-LTR_DR"  = "#7B52A6"    # morado
)

# ── Lectura CSV ───────────────────────────────────────────────────────────────
leer_csv <- function(ruta, condicion) {
  df <- read.csv(ruta, stringsAsFactors = FALSE)
  # El CSV ya tiene cabecera; nos aseguramos de que los nombres sean los esperados
  names(df)[1:4] <- c("id_repeat", "cromosoma", "total", "div_media")
  df <- df[df$cromosoma != "TOTAL", ]
  df           <- df[grepl("^[0-9]+$|^X$|^Y$", df$cromosoma), ]
  df$condicion <- condicion
  return(df)
}

df_muestra <- leer_csv(ruta_muestra, "New annotation")
df_control <- leer_csv(ruta_control, "USCS")
datos      <- rbind(df_muestra, df_control)

# ── Ordenar cromosomas numéricamente ──────────────────────────────────────────
todos_crom      <- unique(datos$cromosoma)
todos_crom      <- todos_crom[order(suppressWarnings(as.numeric(todos_crom)), na.last = TRUE)]
datos$cromosoma <- factor(datos$cromosoma, levels = todos_crom)
datos$condicion <- factor(datos$condicion, levels = c("New annotation", "USCS"))

# ── Color para ERV1-12: gradiente por divergencia Kimura ──────────────────────
variantes_presentes <- intersect(variantes_erv, unique(datos$id_repeat))
variantes_gradiente <- intersect("ERV1-12_DR-LTR", variantes_presentes)

colores_uso <- colores_fijos  # partir de los colores fijos

if (length(variantes_gradiente) > 0) {
  div_sub       <- datos[datos$id_repeat %in% variantes_gradiente & !is.na(datos$div_media), ]
  div_media_vec <- tapply(div_sub$div_media, div_sub$id_repeat, mean, na.rm = TRUE)

  if (length(div_media_vec) == 0 || all(is.na(div_media_vec))) {
    # Sin dato de divergencia → gris neutro
    colores_uso["ERV1-12_DR-LTR"] <- "#AAAAAA"
  } else {
    # Con un único valor, colocar en el centro de la paleta
    paleta <- colorRampPalette(c("#2C7BB6", "#66BD33", "#FEE08B", "#D73027"))
    colores_gradiente <- paleta(1000)
    # Solo hay una variante de gradiente: posición central (0.5)
    colores_uso["ERV1-12_DR-LTR"] <- colores_gradiente[500]
  }
}

# Variantes presentes pero sin color asignado → gris
sin_color <- setdiff(variantes_presentes, names(colores_uso))
if (length(sin_color) > 0) {
  colores_uso[sin_color] <- "#AAAAAA"
}

# ── Ordenar leyenda: ERV1-3C (teal) → ERV1-3B (verde) → ERV1-3 (morado) → ERV1-12 ──
orden_leyenda <- c("ERV1-3C_DR-LTR", "ERV1-3B_DR-LTR", "ERV1-3-LTR_DR", "ERV1-12_DR-LTR")
orden_leyenda <- intersect(orden_leyenda, variantes_presentes)
datos$id_repeat <- factor(datos$id_repeat, levels = orden_leyenda)

# ── Gráfica ───────────────────────────────────────────────────────────────────
n_crom <- length(todos_crom)

g <- ggplot2::ggplot(
  datos,
  ggplot2::aes(x = condicion, y = total, fill = id_repeat)
) +
  ggplot2::geom_bar(stat = "identity", position = "stack", width = 0.7) +
  ggplot2::facet_wrap(~ cromosoma, nrow = 1) +
  ggplot2::scale_fill_manual(values = colores_uso, name = "Variante ERV1-3") +
  ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.12))) +
  ggplot2::labs(
    title    = paste("Comparación ERV1-3 por cromosoma -", organismo),
    subtitle = "Colores según árbol filogenético  |  ERV1-12: gradiente por divergencia Kimura",
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