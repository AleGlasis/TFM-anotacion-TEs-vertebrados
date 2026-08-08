# Reanotación y análisis bioinformático de elementos transponibles en genomas de vertebrados

Trabajo de Fin de Máster — Máster Universitario en Biología Molecular Orientado a Empresas Biotecnológicas (Bioenterprise), Universidad de Granada.

Este repositorio contiene el pipeline computacional desarrollado para llevar a cabo una reanotación exhaustiva y un análisis bioinformático actualizado de los elementos transponibles (TEs) en los genomas de cuatro especies de vertebrados: *Danio rerio*, *Xenopus tropicalis*, *Mus musculus* y *Homo sapiens*.

**Autor:** Alejandro Almagro Évora
**Tutora:** Sara Rodríguez Heras
**Mentora:** Pilar Marchante González

## Resumen del proyecto

El objetivo principal es superar las limitaciones de las anotaciones tradicionales de TEs (fragmentación, solapamientos, nomenclatura desactualizada) mediante un pipeline propio que unifica y cura las bases de datos de referencia (Repbase y Dfam), ejecuta RepeatMasker sobre los genomas completos, resuelve la fragmentación de las anotaciones con OneCodeToFindThemAll y compara los resultados frente a las anotaciones tradicionales, con especial atención a las familias ERV1-3 y LTR7.

## Estructura del repositorio

```
├── Obtención-procesamiento-de-la-librería/
│   Filtrado y deduplicación de secuencias consenso (Repbase + Dfam)
│   y estandarización de la nomenclatura de cabeceras FASTA.
│
├── RepeatMasker-y-análisis/
│   Script Slurm de lanzamiento de RepeatMasker en el clúster Picasso,
│   y análisis directo de sus resultados crudos (conteo por clase,
│   repeat landscape / divergencia Kimura).
│
├── Análisis-erv1-3/
│   Extracción, comparación y visualización de las variantes de la
│   superfamilia de retrovirus endógenos ERV1-3 frente a la anotación UCSC.
│
├── Análisis-ltr7/
│   Extracción, comparación y visualización de las variantes de LTR7
│   (promotor de HERV-H) frente a la anotación UCSC, incluyendo
│   divergencia Kimura y diagrama de Sankey de correspondencias.
│
├── .gitignore
├── LICENSE
└── README.md
```

> Cada carpeta incluye su propio `README.md` con el detalle de cada script, su orden de ejecución y su uso.

## Sobre OneCodeToFindThemAll

El post-procesamiento de defragmentación de los resultados de RepeatMasker se realizó con **OneCodeToFindThemAll** (Bailly-Bechet et al., 2014), un software de terceros publicado bajo licencia GPLv3. **No se incluye una copia en este repositorio** para evitar redistribuir código ajeno innecesariamente.

- Publicación: Bailly-Bechet, M., Haudry, A., & Lerat, E. (2014). "One code to find them all": a perl tool to conveniently parse RepeatMasker output files. *Mobile DNA*, 5, 13.

Los scripts `build_dictionary.pl` y `one_code_to_find_them_all.pl` se usaron sin modificaciones, con las siguientes recomendaciones de memoria orientativas según organismo: 32 GB (pez cebra/rana), 48 GB (ratón), 64 GB (humano).

## Requisitos y versiones utilizadas

| Herramienta | Versión |
|---|---|
| R | 4.5.2 |
| bash | 4.4.23(1) |
| RepeatMasker | 4.1.5 |
| RMBlast | 2.14.0 |
| Slurm | 25.05.2 |
| ggplot2 | 4.0.3 |

Paquetes de R adicionales usados a lo largo del pipeline: `data.table`, `dplyr`, `scales`, `gridExtra`, `ggalluvial`.

Gran parte del procesamiento (obtención de librerías, RepeatMasker) se ejecutó de forma remota en el superordenador **Picasso** del Servicio de Supercomputación y Bioinformática (SCBI) de la Universidad de Málaga, mediante scripts Slurm. El resto del análisis y las visualizaciones se realizaron en R y bash.

## Datos no incluidos

Por su tamaño y disponibilidad pública, este repositorio **no incluye**:

- Genomas de referencia: *GRCz11* (Danio rerio), *Xtro10* (Xenopus tropicalis), *GRCm39* (Mus musculus), *GRCh38.p14* (Homo sapiens) — descargables desde NCBI.
- Librerías de secuencias consenso descargadas de Repbase y Dfam.
- Archivos de anotación `.fa.out` generados por RepeatMasker (600–900 MB).
- Anotaciones tradicionales de referencia descargadas de UCSC (formato `.fa.out`, ~2015).

## Licencia

El código propio de este repositorio se distribuye bajo licencia [MIT](LICENSE), salvo `build_dictionary.pl` y `one_code_to_find_them_all.pl`, que no se incluyen (ver apartado anterior) y en caso de añadirse mantendrían su licencia original GPLv3.
