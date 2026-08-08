# Análisis de LTR7

Scripts de R para extraer, comparar y visualizar las anotaciones de las variantes de LTR7 (secuencia reguladora del promotor de *HERV-H*) entre la nueva reanotación y la anotación tradicional de referencia (UCSC).

## Contenido

1. **`busca_ltr7.R`**
   Extrae de un archivo BED las entradas correspondientes a cualquier variante de LTR7.

   - **Variantes buscadas:** `LTR7` y sus 19 subvariantes (`LTR7A`, `LTR7B`, `LTR7C`, `LTR7Y`, `LTR7a1`, `LTR7up2`, `LTR7a2`, `LTR7B0`, `LTR7B2`, `LTR7B3`, `LTR7D3`, `LTR7u1`, `LTR7YY`, `LTR7up3`, `LTR7BC`, `LTR7d1`, `LTR7d2`, `LTR7u2`, `LTR7up1`).
   - **Entrada:** archivo BED.
   - **Salida:** BED filtrado solo con entradas LTR7 (`ltr7.bed` por defecto).
   - **Uso:**
     ```bash
     Rscript busca_ltr7.R archivo.bed ltr7.bed
     ```

2. **`analiza_ltr7.R`**
   Compara dos archivos BED de LTR7 (nueva anotación vs. tradicional) y clasifica cada entrada como coincidente (con solapamiento dentro de una tolerancia) o única de cada archivo.

   - **Entrada:** dos archivos BED, tolerancia de solapamiento en pb (por defecto 200).
   - **Salida:** archivo de texto con las coincidencias, entradas del archivo 2 usadas más de una vez, y las entradas únicas de cada archivo.
   - **Uso:**
     ```bash
     Rscript analiza_ltr7.R archivo1.bed archivo2.bed comparacion_bed.txt 200
     ```

3. **`buscar_vecino_ltr7.R`**
   Para cada entrada única detectada por `analiza_ltr7.R`, busca su vecino más cercano (por posición) en el archivo BED opuesto.

   - **Entrada:** archivo de comparación generado por `analiza_ltr7.R`, y los dos BED originales.
   - **Salida:** archivo de texto con cada secuencia única y su vecino más cercano (indicando si está en otro cromosoma).
   - **Uso:**
     ```bash
     Rscript buscar_vecino_ltr7.R comparacion_bed.txt archivo1.bed archivo2.bed vecinos_unicos.txt
     ```

4. **`plot_ltr7.R`**
   Grafica la proporción de vecinos más cercanos encontrados por `buscar_vecino_ltr7.R`.

   - **Entrada:** archivo de texto generado por `buscar_vecino_ltr7.R`, umbral mínimo de proporción a mostrar (por defecto 1%).
   - **Salida:** gráfica de barras horizontales en PNG.
   - **Uso:**
     ```bash
     Rscript plot_ltr7.R vecinos_unicos.txt vecinos_archivo2.png 1
     ```

5. **`calcular_div_media_ltr7.R`**
   Calcula la divergencia Kimura media por variante de LTR7 a partir del `.fa.out` de RepeatMasker y la añade como columna `div_media` a un CSV existente.

   - **Entrada:** CSV con una columna de nombre de variante (`id_repeat`, `name`, `Name` o `nombre`, detectada automáticamente), y el archivo `.fa.out`.
   - **Salida:** el mismo CSV con la columna `div_media` añadida (`ltr7_con_div.csv` por defecto).
   - **Uso:**
     ```bash
     Rscript calcular_div_media_ltr7.R archivo.csv archivo.fa.out ltr7_con_div.csv
     ```

6. **`comparar_ltr7.R`**
   Genera la gráfica final comparando el número de elementos de cada variante de LTR7 por cromosoma entre la nueva anotación y la anotación UCSC, con gradiente de color rojo (más viejo) → azul (más joven) según la divergencia Kimura media.

   - **Entrada:** dos CSV con columnas `name, chrom, chromStart, chromEnd, score, strand, div_media` (salida de `calcular_div_media_ltr7.R`), nombre del organismo.
   - **Salida:** gráfica de barras apiladas facetada por cromosoma, en PNG.
   - **Uso:**
     ```bash
     Rscript comparar_ltr7.R muestra.csv control.csv "Homo sapiens" comparacion_ltr7.png
     ```

7. **`sankey_ltr7.R`**
   Genera un diagrama de Sankey/alluvial que muestra la correspondencia entre variantes de LTR7 de la muestra y del control, usando los pares coincidentes de `analiza_ltr7.R`.

   - **Entrada:** archivo de comparación generado por `analiza_ltr7.R` (sección de coincidencias).
   - **Salida:** diagrama de Sankey en PNG, coloreado según la paleta fija de 20 variantes de LTR7.
   - **Uso:**
     ```bash
     Rscript sankey_ltr7.R comparacion_bed.txt sankey_ltr7.png
     ```
   - Instala automáticamente `ggalluvial` si no está disponible.

## Flujo de trabajo

```
archivo.bed (nueva anotación)         archivo.bed (anotación UCSC)
      │                                       │
      ▼                                       ▼
busca_ltr7.R ──► ltr7.bed              busca_ltr7.R ──► ltr7.bed
      │                                       │
      └───────────────┬───────────────────────┘
                       ▼
              analiza_ltr7.R ──► comparacion_bed.txt
                       │
         ┌─────────────┼─────────────────────┐
         ▼                                    ▼
buscar_vecino_ltr7.R                   sankey_ltr7.R ──► gráfica Sankey
         │
         ▼
   plot_ltr7.R ──► gráfica de vecinos

  (en paralelo, para la gráfica de divergencia por cromosoma)

CSV de conteo + archivo.fa.out
         │
         ▼
calcular_div_media_ltr7.R ──► CSV con div_media
         │
         ▼
  comparar_ltr7.R ──► gráfica final por cromosoma
```

## Dependencias

- R (≥ 4.x): `ggplot2`, `scales`, `ggalluvial`

## Notas

- La lista de sufijos de variantes de LTR7 (`sufijos_ltr7`) está duplicada de forma idéntica en `busca_ltr7.R`, `comparar_ltr7.R` y `sankey_ltr7.R`. Si en algún momento aparece una nueva subvariante, hay que actualizarla en los tres sitios — sería buen candidato para mover a una función/constante común en una carpeta `utils/`.
- `comparar_ltr7.R` espera el CSV ya procesado por `calcular_div_media_ltr7.R` (con columna `div_media`); a diferencia de la carpeta de ERV1-3, aquí sí tienes el script que genera esa columna.
- `plot_ltr7.R` reutiliza por defecto el mismo nombre de salida (`vecinos_archivo2.png`) que su equivalente de la carpeta ERV1-3 — si generas ambas gráficas en el mismo directorio de trabajo, una sobrescribirá a la otra a menos que especifiques rutas de salida distintas.
- Los scripts `busca_ltr7.R`, `analiza_ltr7.R`, `buscar_vecino_ltr7.R` y `plot_ltr7.R` son prácticamente idénticos en estructura a sus equivalentes de la carpeta ERV1-3 (mismo enfoque de comparación BED con tolerancia y búsqueda de vecino más cercano), adaptados a las variantes de LTR7.
