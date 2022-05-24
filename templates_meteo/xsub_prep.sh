
#PBS -S /bin/bash
#PBS -o ./prep_IC21h.out
#PBS -e ./prep_IC21h.out
#PBS -j oe
#PBS -l walltime=00:30:00
#PBS -lselect=1:ncpus=40
#PBS -V
#PBS -S /bin/bash
#PBS -N BRAMSprep_IC21h
#PBS -q pesq

umask 022
#
ulimit -s unlimited
ulimit -c unlimited

set -x

cd /lustre_xc50/denis_eiras/ioper_brams5.6
aprun -n 1 -N 1 ./EXEC/prep_1.0 > prep.log
set +x  
