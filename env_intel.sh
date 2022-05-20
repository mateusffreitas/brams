#!/bin/bash

# env intel
module purge; module load intel;module load impi;module load phdf5;module load netcdf;module load netcdf-cxx;module load netcdf-fortran;module load hwloc;export PATH=/mnt/beegfs/denis.eiras/libraries/bin:$PATH;export LD_LIBRARY_PATH=/mnt/beegfs/denis.eiras/libraries/lib:$LD_LIBRARY_PATH; rm /mnt/beegfs/denis.eiras/libraries/bin;rm /mnt/beegfs/denis.eiras/libraries/lib;rm /mnt/beegfs/denis.eiras/libraries/include; ln -s /mnt/beegfs/denis.eiras/libraries/bin_intel /mnt/beegfs/denis.eiras/libraries/bin;ln -s /mnt/beegfs/denis.eiras/libraries/lib_intel /mnt/beegfs/denis.eiras/libraries/lib;ln -s /mnt/beegfs/denis.eiras/libraries/include_intel /mnt/beegfs/denis.eiras/libraries/include

echo "Lista de módulos carregados: "
module list