#!/bin/bash
#####################################################
#               SBATCH CONFIGURATION                #
#####################################################
#SBATCH --job-name=RepeatMasker
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --mem-per-cpu=8000
#SBATCH --cpus-per-task=16
#SBATCH --time=120:00:00

#####################################################
#               RUTAS Y PARÁMETROS                  #
#####################################################

LIBRERIA=/mnt/home/users/cts_1147_genyo/aalmagro/experiments/Conseqxorganism/Dr/library_perfecta6.fasta
DIRECTORIO_SALIDA=/mnt/home/users/cts_1147_genyo/aalmagro/experiments/Conseqxorganism/Dr/Búsqueda/RepeatMasker_sensible
GENOMA=/mnt/home/users/cts_1147_genyo/aalmagro/fscratch/Genomas/Dr/dr_genome.fa
CPUS=4

#####################################################
#               EJECUCIÓN                           #
#####################################################

module load repeatmasker

RepeatMasker \
  -e ncbi \
  -lib  $LIBRERIA \
  -pa   $CPUS \
  -dir  $DIRECTORIO_SALIDA \
  -s \
  $GENOMA