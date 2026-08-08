library(ggplot2)
library(dplyr)
library(scales)
library(data.table)

# ── Argumentos desde línea de comandos ────────────────────────────────────────
# Uso: Rscript plot_kimura.R <archivo.fa.out> <salida.png> <tamanio_genoma>
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 3) {
  stop("Uso: Rscript plot_kimura.R <archivo.fa.out> <salida.png> <tamanio_genoma>")
}

archivo_entrada <- args[1]
archivo_salida  <- args[2]
longitud_genoma <- as.numeric(args[3])

# ── Lectura del archivo .fa.out ───────────────────────────────────────────────
campos_nombres <- c(
  "puntuacion_sw", "perc_div", "perc_del", "perc_ins",
  "secuencia_query", "inicio_query", "fin_query", "izq_query",
  "hebra", "repeticion", "clase_familia",
  "inicio_rep", "fin_rep", "izq_rep", "id",
  "extra"
)

datos_rm <- fread(
  archivo_entrada,
  skip      = 3,
  fill      = TRUE,
  header    = FALSE,
  col.names = campos_nombres,
  nThread   = parallel::detectCores()
)

# ── Conversión de tipos ───────────────────────────────────────────────────────
datos_rm[, perc_div     := as.numeric(perc_div)]
datos_rm[, inicio_query := as.integer(inicio_query)]
datos_rm[, fin_query    := as.integer(fin_query)]

# ── Limpieza ──────────────────────────────────────────────────────────────────
datos_rm[, clase_familia := gsub("\\?", "", clase_familia)]

# ── Filtrado de categorías no informativas ────────────────────────────────────
clases_excluir <- c(
  "Low_complexity",
  "snRNA",
  "tRNA",
  "Simple_repeat",
  "ARTEFACT",
  "Unknown",
  "Unspecified",
  "rRNA",
  "scRNA",
  "srpRNA",
  "repetitive_element",
  "repetitive_sequence",
  "multicopy_gene",
  "transposable_element",
  "repeat_region",
  "interspersed_repeat",
  "Inverted_repeat"
)

datos_rm <- datos_rm[!clase_familia %in% clases_excluir]

# Eliminar Satellite y Satellite/*
datos_rm <- datos_rm[!grepl("^Satellite", clase_familia)]

# ── Normalización de capitalización ───────────────────────────────────────────
datos_rm[, c("sg_tmp", "sf_tmp") :=
           tstrsplit(clase_familia, "/", fixed = TRUE, keep = 1:2)]

datos_rm[
  !is.na(sf_tmp),
  clase_familia := paste0(
    sg_tmp,
    "/",
    sub("^(\\w)", "\\U\\1", tolower(sf_tmp), perl = TRUE)
  )
]

datos_rm[, c("sg_tmp", "sf_tmp") := NULL]

# ── Normalización de supergrupos y subfamilias ────────────────────────────────
datos_rm[, clase_familia := gsub(
  "^DD\\(E-D\\)_Transposons/(.+)$",
  "DNA/\\1",
  clase_familia
)]

datos_rm[, clase_familia := gsub(
  "^DD\\(E-D\\)_Transposons$",
  "DNA",
  clase_familia
)]

datos_rm[, clase_familia := gsub(
  "^Rolling_circle/(.+)$",
  "RC/\\1",
  clase_familia
)]

datos_rm[, clase_familia := gsub(
  "^Rolling_circle$",
  "RC",
  clase_familia
)]

datos_rm[, clase_familia := gsub(
  "^DNA/Hat-.*",
  "DNA/hAT",
  clase_familia
)]

datos_rm[, clase_familia := gsub(
  "^DNA/Hat$",
  "DNA/hAT",
  clase_familia
)]

datos_rm[, clase_familia := gsub(
  "^DNA/Tcmar-.*",
  "DNA/TcMar",
  clase_familia
)]

datos_rm[, clase_familia := gsub(
  "^DNA/Tcmar$",
  "DNA/TcMar",
  clase_familia
)]

datos_rm[, clase_familia := gsub(
  "^LINE/Rte.*",
  "LINE/RTE",
  clase_familia
)]

datos_rm[, clase_familia := gsub(
  "^LINE/L1.*",
  "LINE/L1",
  clase_familia
)]

datos_rm[, clase_familia := gsub(
  "^LINE/I.*",
  "LINE/L1",
  clase_familia
)]

datos_rm[, clase_familia := gsub(
  "^SINE/Sine.*",
  "SINE/SINE1-7SL",
  clase_familia
)]

datos_rm[, clase_familia := gsub(
  "^Non-Ltr/",
  "Non-LTR/",
  clase_familia
)]

# ── Extracción del supergrupo ─────────────────────────────────────────────────
datos_rm[, supergrupo :=
           tstrsplit(clase_familia, "/", fixed = TRUE, keep = 1)[[1]]]

# ── Orden de supergrupos ──────────────────────────────────────────────────────
# Resultado visual (de arriba a abajo):
# DNA → RC → LTR → LINE → Retroposon → SINE

orden_supergrupos <- c(
  "Cryptons",
  "DIRS",
  "Maverick-Polinton",
  "PLE",
  "EnSpm",
  "Non-LTR",
  "Nonautonomous",
  "SINE",
  "Retroposon",
  "LINE",
  "LTR",
  "RC",
  "DNA"
)

otros_grupos <- setdiff(
  unique(datos_rm$supergrupo),
  orden_supergrupos
)

datos_rm$supergrupo <- factor(
  datos_rm$supergrupo,
  levels = c(orden_supergrupos, sort(otros_grupos))
)

# ── Longitud de cada elemento ─────────────────────────────────────────────────
datos_rm[, longitud_te := fin_query - inicio_query + 1]

# ── Conversión a data.frame ───────────────────────────────────────────────────
datos_rm <- as.data.frame(datos_rm)

# ── Paleta de colores por supergrupo ──────────────────────────────────────────
colores_supergrupos <- c(
  "DNA"               = "#c0392b",
  "RC"                = "#7f8c8d",
  "LTR"               = "#27ae60",
  "SINE"              = "#8e44ad",
  "LINE"              = "#2980b9",
  "Non-LTR"           = "#16a085",
  "Retroposon"        = "#2c3e50",
  "Cryptons"          = "#6c3483",
  "DIRS"              = "#a04000",
  "PLE"               = "#cb4335",
  "Maverick-Polinton" = "#1e8449",
  "EnSpm"             = "#7b3f00",
  "Nonautonomous"     = "#555555"
)

supergrupos_presentes <- levels(datos_rm$supergrupo)
supergrupos_presentes <- supergrupos_presentes[
  supergrupos_presentes %in%
    unique(as.character(datos_rm$supergrupo))
]

colores_personalizados <- c()

for (sg in supergrupos_presentes) {

  familias <- sort(
    unique(datos_rm$clase_familia[
      as.character(datos_rm$supergrupo) == sg
    ])
  )

  if (sg %in% names(colores_supergrupos)) {

    color_base <- colores_supergrupos[[sg]]

    color_claro <- colorRampPalette(
      c(color_base, "#ffffff")
    )(10)[4]

    colores <- colorRampPalette(
      c(color_base, color_claro)
    )(length(familias))

  } else {

    colores <- colorRampPalette(
      c("#888888", "#dddddd")
    )(length(familias))

  }

  colores_personalizados <- c(
    colores_personalizados,
    stats::setNames(colores, familias)
  )
}

# ── Orden de las familias ─────────────────────────────────────────────────────
datos_rm$clase_familia <- factor(
  datos_rm$clase_familia,
  levels = names(colores_personalizados)
)

# ── Gráfica ───────────────────────────────────────────────────────────────────
grafica <- ggplot(
  datos_rm,
  aes(
    x      = perc_div,
    weight = longitud_te / longitud_genoma,
    fill   = clase_familia
  )
) +
  geom_histogram(
    binwidth  = 1,
    position  = "stack",
    color     = "white",
    linewidth = 0.2
  ) +
  scale_x_continuous(
    breaks = seq(0, 40, by = 5),
    limits = c(0, 40),
    expand = c(0, 0),
    name   = "Kimura substitution level"
  ) +
  scale_y_continuous(
    labels = percent_format(accuracy = 0.1),
    expand = expansion(mult = c(0.005, 0.02)),
    name   = "percent of genome"
  ) +
  scale_fill_manual(
    values = colores_personalizados,
    name   = "Repeat class/family",
    drop   = TRUE,
  ) +
  labs(title = "Interspersed Repeat Landscape") +
  theme_bw(base_size = 13) +
  theme(
    plot.title       = element_text(face = "bold", hjust = 0.5, size = 14),
    axis.title.x     = element_text(face = "italic"),
    axis.title.y     = element_text(face = "italic", angle = 90, vjust = 2),
    panel.grid.major = element_line(colour = "#f0f0f0"),
    panel.grid.minor = element_blank(),
    panel.border     = element_blank(),
    axis.line        = element_line(colour = "black"),
    legend.position  = "right",
    legend.key.size  = unit(0.4, "cm"),
    legend.text      = element_text(size = 9),
    legend.title     = element_text(face = "bold", size = 10)
  )

# ── Guardado ──────────────────────────────────────────────────────────────────
ggsave(
  filename = archivo_salida,
  plot     = grafica,
  width    = 13,
  height   = 7,
  units    = "in",
  dpi      = 300
)

message("Gráfica guardada en: ", archivo_salida)