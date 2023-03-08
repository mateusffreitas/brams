#!/bin/bash
# Script for processing makevfile phase in parallel by dividing the RAMSIN_BASIC
# TIMMAX into 24 hours per file.
# Slurm Example:
#  sbatch --export="RAMSIN=RAMSIN_BASIC,EXE=./brams-intel" -W -p pesq0 -n 10 parallel_makevfile.bash 
# Local example:
#  RAMSIN=RAMSIN_BASIC EXE=./brams-intel ./parallel_makevfile.bash 
# Change the below paths according to your environment
source /home/public/CEMPA/intel-2023.0.0/setvars.sh
PREREQ_DIR=/home/public/CEMPA/opt-intel-2023.0.0
export PATH=${PREREQ_DIR}/bin:$PATH
export LD_LIBRARY_PATH=${PREREQ_DIR}/lib:$LD_LIBRARY_PATH

###
EXE=${EXE:-./brams-6.0}
RAMSIN=${RAMSIN:-RAMSIN_BASIC}

./split_makevfile.py ${RAMSIN} 

COUNT=$(grep "${RAMSIN}" -c "${RAMSIN}"_patched_list)

if [[ -z $SLURM_NTASKS ]]
then
    NTASKS=${NTASKS:-$COUNT}
else
    NTASKS=${SLURM_NTASKS}
fi

xargs -I{} -P ${NTASKS} bash -c "${EXE} -f {} &> {}.out" < ${RAMSIN}_patched_list 

# GNU Parallel
#parallel -j ${NTASKS} --joblog makevjobs --results {}.out ${EXE} -f {} < ${RAMSIN}_patched_list

FINISHED_COUNT=$(grep "Time integration" "${RAMSIN}"_*.out | wc -l)
IVAR_COUNT=$(ls -1 $(grep -i VARFPFX "${RAMSIN}" | cut -d "'" -f 2)* | wc -l)
EXPECTED_IVAR_COUNT=$(cat "${RAMSIN}"_ivar_count)

if [[ $FINISHED_COUNT -eq $COUNT && $IVAR_COUNT -eq $EXPECTED_IVAR_COUNT ]]
then
    echo Success 
else
    echo Fail
    exit -1
fi
