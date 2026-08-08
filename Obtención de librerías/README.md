# Obtención y curación de librerías de secuencias consenso

Scripts de R encargados de generar la librería de secuencias consenso final para cada organismo, a partir de las descargas crudas de Repbase y Dfam: eliminan duplicados entre ambas bases de datos y estandarizan el formato de las cabeceras FASTA para que sean compatibles con RepeatMasker.

## Orden de ejecución

1. **`filtropara2.R`**
   Filtra duplicados de ID y de secuencia entre los dos archivos FASTA descargados (Repbase y Dfam) y genera una única librería combinada sin redundancias.

   - **Entrada:** dos archivos FASTA (`archivo1.fasta`, `archivo2.fasta`), con prioridad para las secuencias del primero.
   - **Salida:** `library.fasta` (librería combinada), `ids_total.txt`, `ids_unicos_dfam.txt`, `duplicados_ids.txt`, `duplicados_seq.txt`, y `graficas_filtrado.png` con el resumen visual del proceso de filtrado (composición final, resumen por etapa, distribución de longitudes y proporción de duplicados).
   - **Uso:**
```r
     filtropara2("archivo1.fasta", "archivo2.fasta")
```

2. **`formatear_cabecera.R`**
   Reformatea las cabeceras del FASTA resultante al formato `id#clase/familia` que requiere RepeatMasker.

   - **Entrada:** FASTA con cabeceras en formato `>id clase/familia`.
   - **Salida:** FASTA con cabeceras en formato `>id#clase/familia`.
   - **Uso:**
```r
     formatear_cabecera("library.fasta", "library_formateada.fasta")
```

3. **`intercambia_id_df.R`**
   Sustituye los identificadores genéricos `DF.../DR...` de Dfam por el ID real de la secuencia en las cabeceras del FASTA.

   - **Entrada:** FASTA con cabeceras tipo `>DF000000016.4 SINE/alu 7SLRNA`.
   - **Salida:** FASTA con cabeceras tipo `>7SLRNA SINE/alu`.
   - **Uso:**
```r
     intercambiar_id_df("library_rellena_clean.fasta", "library_final.fasta")
```

## Dependencias

- R (≥ 4.x)
- `ggplot2`
- `gridExtra`

## Notas

- `filtropara2` asume que en el archivo 2 el ID ocupa la segunda posición de la cabecera, salvo en entradas `DF`/`DR`, donde ocupa la última.
- Las funciones escriben directamente en el directorio de trabajo (`sink()`, `png()`, `writeLines()` sin ruta), por lo que conviene fijar el directorio de trabajo a la carpeta de salida deseada antes de ejecutarlas.
