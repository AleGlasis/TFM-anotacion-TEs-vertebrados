# Análisis de ERV1-3

Scripts de R para extraer, comparar y visualizar las anotaciones de las variantes de ERV1-3 (*ERV1-3, ERV1-3B, ERV1-3C, ERV1-12*) entre la nueva reanotación y la anotación tradicional de referencia (UCSC).

## Contenido

1. **`busca_erv1-3.r`**
   Extrae del archivo `.out` de RepeatMasker las entradas correspondientes a las variantes de ERV1-3 y genera un conteo por cromosoma, con una fila `TOTAL` por variante.

   - **Variantes buscadas:** `ERV1-12_DR-LTR`, `ERV1-3-LTR_DR`, `ERV1-3B_DR-LTR`, `ERV1-3C_DR-LTR`.
   - **Entrada:** archivo `.out` de RepeatMasker.
   - **Salida:** CSV con columnas `cromosoma`, `id_repeat`, `total`.
   - **Uso:**
     ```bash
     Rscript busca_erv1_3.R archivo.out erv1_3.csv
     ```

2. **`analiza_erv1_3.r`**
   Compara dos archivos BED (por ejemplo, nueva anotación vs. anotación tradicional) y clasifica cada entrada como coincidente (con solapamiento dentro de una tolerancia) o única de cada archivo.

   - **Entrada:** dos archivos BED, tolerancia de solapamiento en pb (por defecto 200).
   - **Salida:** archivo de texto con las coincidencias, entradas del archivo 2 usadas más de una vez, y las entradas únicas de cada archivo.
   - **Uso:**
     ```bash
     Rscript analiza_erv1_3.R archivo1.bed archivo2.bed comparacion_bed.txt 200
     ```

3. **`buscar_vecino_erv1_3.r`**
   Para cada entrada única detectada por `analiza_erv1_3.r`, busca su vecino más cercano (por posición) en el archivo BED opuesto.

   - **Entrada:** archivo de comparación generado por `analiza_erv1_3.r`, y los dos BED originales.
   - **Salida:** archivo de texto con cada secuencia única y su vecino más cercano (indicando si está en otro cromosoma).
   - **Uso:**
     ```bash
     Rscript buscar_vecino_erv1_3.R comparacion_bed.txt archivo1.bed archivo2.bed vecinos_unicos.txt
     ```

4. **`plot_erv1-3.r`**
   Grafica la proporción de vecinos más cercanos encontrados por `buscar_vecino_erv1_3.r`, para ver a qué elementos del archivo 1 se asocian mayoritariamente las secuencias únicas del archivo 2.

   - **Entrada:** archivo de texto generado por `buscar_vecino_erv1_3.r`, umbral mínimo de proporción a mostrar (por defecto 1%).
   - **Salida:** gráfica de barras horizontales en PNG.
   - **Uso:**
     ```bash
     Rscript plot_erv1_3.R vecinos_unicos.txt vecinos_archivo2.png 1
     ```

5. **`comparar_erv1_3.r`**
   Genera la gráfica final comparando el número de elementos de cada variante de ERV1-3 por cromosoma entre la nueva anotación y la anotación UCSC, con colores fijos según el árbol filogenético (ERV1-3C, ERV1-3B, ERV1-3) y gradiente por divergencia Kimura para ERV1-12.

   - **Entrada:** dos CSV con columnas `id_repeat, cromosoma, total, div_media` (uno para la muestra, otro para el control), nombre del organismo.
   - **Salida:** gráfica de barras apiladas facetada por cromosoma, en PNG.
   - **Uso:**
     ```bash
     Rscript comparar_erv1_3.R muestra.csv control.csv "Danio rerio" comparacion_erv1_3.png
     ```
   - **⚠️ Dependencia externa:** este script espera un CSV con una columna `div_media` (divergencia Kimura media por variante), que no genera ninguno de los scripts de esta carpeta — falta el script `calcular_div_media_erv1_3.R` referenciado en la cabecera. Hay que añadirlo a esta carpeta o generar esa columna antes de poder usar este script.

## Flujo de trabajo

```
archivo.out (nueva anotación)          archivo.out (anotación UCSC)
      │                                        │
      ▼                                        ▼
busca_erv1-3.r ──────────► CSV conteo    busca_erv1-3.r ──────────► CSV conteo
      │                                        │
      └──────────────┬─────────────────────────┘
                      ▼
         [ falta: calcular_div_media_erv1_3.R ]
                      │
                      ▼
              comparar_erv1_3.r  ──────────► gráfica final por cromosoma

  (en paralelo, a nivel de coordenadas BED)

archivo1.bed  ──┐
                ├──► analiza_erv1_3.r ──► comparacion_bed.txt
archivo2.bed  ──┘                              │
                                                ▼
                                  buscar_vecino_erv1_3.r ──► vecinos_unicos.txt
                                                │
                                                ▼
                                        plot_erv1-3.r ──► gráfica de vecinos
```

## Dependencias

- R (≥ 4.x): `ggplot2`, `scales`

## Notas

- Los nombres de archivo mezclan mayúsculas/minúsculas y guiones/guiones bajos (`busca_erv1-3.r`, `plot_erv1-3.r` vs. `analiza_erv1_3.r`, `comparar_erv1_3.r`) — conviene unificar la convención antes de subir (recomendado: todo en minúscula con `_`, extensión `.R`).
- `analiza_erv1_3.r` y `buscar_vecino_erv1_3.r` trabajan sobre coordenadas BED, mientras que `busca_erv1-3.r` y `comparar_erv1_3.r` trabajan sobre conteos agregados por cromosoma — son dos análisis complementarios pero independientes dentro de esta misma carpeta.
- Los nombres de las variantes de ERV1-3 (`ERV1-3-LTR_DR`, `ERV1-3B_DR-LTR`, `ERV1-3C_DR-LTR`, `ERV1-12_DR-LTR`) están hardcodeados en varios scripts; si cambian en la librería curada, hay que actualizarlos aquí también.
