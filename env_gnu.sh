#!/bin/bash

# env gnu
module purge; module load gnu9/9.4.0;module load ucx/1.11.2;module load openmpi4/4.1.1;module load netcdf/4.7.4;module load netcdf-fortran/4.5.3;module load phdf5/1.10.8;module load hwloc;module load libfabric/1.13.0;export PATH=/mnt/beegfs/denis.eiras/libraries/bin:$PATH;export LD_LIBRARY_PATH=/opt/ohpc/pub/libs/gnu9/impi/netcdf-fortran/4.5.3/lib:/opt/ohpc/pub/libs/gnu9/impi/netcdf/4.7.4/lib:/mnt/beegfs/denis.eiras/libraries/lib:$LD_LIBRARY_PATH; rm /mnt/beegfs/denis.eiras/libraries/bin;rm /mnt/beegfs/denis.eiras/libraries/lib;rm /mnt/beegfs/denis.eiras/libraries/include; ln -s /mnt/beegfs/denis.eiras/libraries/bin_gnu /mnt/beegfs/denis.eiras/libraries/bin;ln -s /mnt/beegfs/denis.eiras/libraries/lib_gnu /mnt/beegfs/denis.eiras/libraries/lib;ln -s /mnt/beegfs/denis.eiras/libraries/include_gnu /mnt/beegfs/denis.eiras/libraries/include

echo "Lista de módulos carregados: "
module list

