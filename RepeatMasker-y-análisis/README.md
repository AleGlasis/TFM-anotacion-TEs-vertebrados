# Lanzamiento de RepeatMasker y análisis de resultados

Script Slurm para lanzar RepeatMasker sobre el genoma de cada organismo en el clúster Picasso, y scripts de R para analizar y visualizar directamente los archivos `.out` que genera.

## Contenido

1. **`RepeatMasker.sh`**
   Script Slurm que lanza RepeatMasker sobre el genoma completo de un organismo usando la librería de secuencias consenso curada.

   - **Configuración de recursos:** nodo único, 16 CPUs, 8 GB de RAM por CPU (128 GB totales), tiempo máximo de 120 h.
   - **Parámetros de RepeatMasker:** motor `ncbi`, 4 procesos paralelos (`-pa 4`), enmascaramiento sensible (`-s`).
   - **Entrada:** librería FASTA curada (`$LIBRERIA`) y genoma de referencia (`$GENOMA`).
   - **Salida:** archivos de anotación en `$DIRECTORIO_SALIDA`, incluyendo el `.out` con las coordenadas de cada elemento repetitivo detectado.
   - **Uso:**
     ```bash
     sbatch RepeatMasker.sh
     ```

2. **`conteo_clase_repeatmasker.r`**
   Cuenta el número de elementos por clase de TE y por cromosoma a partir del archivo `.out` de RepeatMasker.

   - **Entrada:** archivo `.out` de RepeatMasker.
   - **Salida:** CSV con el conteo por cromosoma y clase (`conteo_clases_cromosoma.csv` por defecto).
   - **Uso:**
     ```bash
     Rscript conteo_clase_repeatmasker.R archivo.out conteo.csv
     ```

3. **`plot_clases_repeatmasker.r`**
   Genera una gráfica de barras apiladas con la distribución de clases de TEs por cromosoma, a partir del CSV generado por el script anterior.

   - **Entrada:** CSV de conteo por cromosoma y clase.
   - **Salida:** gráfica de barras apiladas en PNG (`plot_clases_cromosoma.png` por defecto). Filtra por defecto solo cromosomas canónicos.
   - **Uso:**
     ```bash
     Rscript plot_clases_repeatmasker.R conteo.csv plot_clases_cromosoma.png
     ```

4. **`plot_kimura_divergence.R`**
   Genera el *repeat landscape* (histograma apilado de divergencia de Kimura ponderado por proporción del genoma) directamente a partir del `.out` de RepeatMasker, con limpieza y normalización de nomenclatura de clases/familias.

   - **Entrada:** archivo `.out` de RepeatMasker y tamaño del genoma en pb.
   - **Salida:** gráfica PNG con el paisaje de divergencia por clase/familia.
   - **Uso:**
     ```bash
     Rscript plot_kimura_divergence.R archivo.fa.out salida.png tamanio_genoma
     ```

## Flujo de trabajo

```
RepeatMasker.sh
      │
      ▼
  archivo.out ──────────────┬─────────────────────────┐
      │                     │                          │
      ▼                     ▼                          ▼
conteo_clase_repeatmasker.r │              plot_kimura_divergence.R
      │                     │
      ▼                     │
plot_clases_repeatmasker.r ◄┘
```

## Dependencias

- RepeatMasker (v. 4.1.5) con motor de búsqueda RMBlast (v. 2.14.0), disponibles como módulo en Picasso
- Slurm (v. 25.05.2)
- R (≥ 4.x): `ggplot2`, `dplyr`, `scales`, `data.table`, `parallel`

## Notas

- Las rutas de `RepeatMasker.sh` (librería, genoma, directorio de salida) están hardcodeadas para el organismo con el que se ejecutó por última vez; hay que editarlas manualmente para cada organismo antes de lanzar el job.
- Aunque en `RepeatMasker.sh` se reservan 16 CPUs en Slurm, solo se pasan 4 a RepeatMasker (`-pa 4`), ya que RMBlast lanza varios subprocesos internos por cada proceso paralelo solicitado y necesita ese margen para no saturar el nodo.
- `plot_kimura_divergence.R` excluye categorías no informativas (Low_complexity, Simple_repeat, Satellite, etc.) y normaliza variantes de nomenclatura (p. ej. `DD(E-D)_Transposons` → `DNA`, `Rolling_circle` → `RC`) antes de graficar.
