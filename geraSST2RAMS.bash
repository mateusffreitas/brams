#!/bin/bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Script para gerar o SST semanalmente usando o programa sst2RAMS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author: Denis Eiras - denis.eiras@inpe.br
#
# $ geraSST2RAMS.bash YYYYMMDD00
#

function copy_sst_files() {
  semana=$1
  external=$2
  ncep_dirs="${semana}00/dataout/NCEP"
  sst_week_dir="./data/BRAMS/SST_WEEK"

  mkdir -p "${sst_week_dir}"
  cp -vf "${external}/${ncep_dirs}/oisst.${semana}.gz" "${sst_week_dir}"
  gzip -df "${sst_week_dir}/oisst.${semana}.gz"

  cp ./EXEC/sst2RAMS.x "${sst_week_dir}"
  actual_dir=$(pwd)
  cd "${sst_week_dir}"
  dest_file="./oisst.${semana}"
  echo "Executing ./sst2RAMS.x "${dest_file}" ${semana} in ${sst_week_dir} directory"
  ./sst2RAMS.x "${dest_file}" ${semana} > "${dest_file}.log"
  rm ./sst2RAMS.x
  cd ${actual_dir}
}

   edate=$1
   external=$2 
   
   sst_week_dir="./data/BRAMS/SST_WEEK"

   sem_edate=$(date -u "+%w" -d "${edate:8:2}:00 ${edate:0:8}")
   dif_sem=$(echo "$sem_edate-3" | bc) #3=quarta-feira
   if [ $(echo "$dif_sem<=5" | bc) -eq 1 ]; then
      dif_sem=$(($dif_sem+7))
   fi
   antipenultima_sem=$(date -u "+%Y%m%d" -d "${edate:8:2}:00 ${edate:0:8} $(($dif_sem+7)) days ago")
   penultima_sem=$(date -u "+%Y%m%d" -d "${edate:8:2}:00 ${edate:0:8} $dif_sem days ago") #"

   copy_sst_files $antipenultima_sem $external
   copy_sst_files $penultima_sem $external

   #--- escevendo o header ---
   file_wheader="${sst_week_dir}/WHEADER"
   echo "  180  181  -90 -180 -0.500000 -0.500000" > ${file_wheader}
   echo "     2" >> ${file_wheader}
   echo "${antipenultima_sem} 0000   ${antipenultima_sem:4:2}   ${antipenultima_sem:6:2}   00" >> ${file_wheader}
   echo "$penultima_sem 0000   ${penultima_sem:4:2}   ${penultima_sem:6:2}   00" >> ${file_wheader}
   echo  >> ${file_wheader}
   echo "(bksz   NO  lat  lon   iofflat   iofflon)"  >> ${file_wheader}
   echo "(ntimes)"  >> ${file_wheader}
   echo "(fpfx year  mon date hour)"   >> ${file_wheader}
