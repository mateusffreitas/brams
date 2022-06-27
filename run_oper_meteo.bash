#!/bin/bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Script para executar o BRAMS meteorológico pré-operacional
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# $ run_oper_meteo.bash yyyy mm dd TIPO
#
# onde TIPO: 
# - PREPARAR_AMBIENTE: criar os diretórios, namelists, arquivos de submissão".
#
# - MAKESFC: Executar o MAKESFC para a data informada
#
# - MAKEVFL: Extrai os dados de umidade do Solo do GFS; Executa o PRE do BRAMS usando os arquivo do GFS do dia da linha de comando informada, 
#        gerando as condições iniciais das0h do dia atual até 7 dias pra frente (171h no total). Em seguida, executa a fase MAKEVFILE,
#        utilizando os arquivos gerados pelo PRE.
#
# - INITIAL: Executa a fase INITIAL com IAU=0, por 171 horas, utilizando os demais arquivos gerados pela fase MAKEVFL.
#

# set -x
# ~~~~~~~~~~~~~~~ Início do script ~~~~~~~~~~~~~~~

export comp_env="intel"
source ./env_${comp_env}.sh
rm -f *.ctl *.inv *.blow *.gra DumpMemory* ts*.out *.done

_fase=$4
_dia=$3
_mes=$2
_ano=$1

echo
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Iniciando execução da fase ${_fase} ... "
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

_NOVA_DATA="-1"
_NOVA_DATA=`echo $_NOVA_DATA | tr "-" " "`
ontem=`date +%Y%m%d --date="$_ano-$_mes-$_dia $_HORA $_NOVA_DATA day ago"`

hoje=${_ano}${_mes}${_dia}00

# Parâmetros do RAMSIN
expnme=BRAMS-8km

# 7 dias
timmax=168

timmax_vfl=${timmax}
timmax_pre=$((${timmax}+3))
imonth1=${_mes}
idate1=${_dia}
iyear1=${_ano}
itime1=00

nnxp=1017
nnyp=993
nnzp=45
deltax=8000.
deltay=8000.
dtlong=40.
polelat=-19.0
polelon=-56.0
centlat=-19.0
centlon=-56.0
chem_timestep=320.
chem_assim=0
aer_assim=0
srcmapfn="'NONE'"
recycle_tracers=0
applyiau=0
frqanl=10800.
hfilout="'.\/${hoje}\/dataout\/ANL\/HOPQUE'"
afilout="'.\/${hoje}\/dataout\/ANL\/OPQUE'"
pastfn=".\/$ontem\/dataout\/ANL\/OPQUE-A-$1-$2-$3-000000-head.txt"
topfiles="'.\/${hoje}\/dataout\/sfc\/top_oq3g'"
sfcfiles="'.\/${hoje}\/dataout\/sfc\/sfc_oq3g'"
sstfpfx="'.\/${hoje}\/dataout\/sfc\/sst_oq3g'"
ndvifpfx="'.\/${hoje}\/sfc\/ndv_oq3g'"
usdata_in="'.\/my_external\/"${hoje}"\/dataout\/umid_solo\/GFS.SOIL:UMID_TEMP.'"
usmodel_in="'.\/${hoje}\/dataout\/UMD\/gl_sm_gpnr.'"
icdir=".\/${hoje}\/datain\/GRADS\/"
icprefix="'${icdir}ic'"
# icgradsprefix="'.\/${hoje}\/dataout\/ic\/icgrads'"
gprefix="'.\/${hoje}\/dataout\/post\/chem'"

# outros parâmetros
inc_hour=3
inc_hour_double=6

idate2_pre=`date +%d --date="${iyear1}-${imonth1}-${idate1} ${itime1} $timmax_pre hour"`
imonth2_pre=`date +%m --date="${iyear1}-${imonth1}-${idate1} ${itime1} $timmax_pre hour"`
iyear2_pre=`date +%Y --date="${iyear1}-${imonth1}-${idate1} ${itime1} $timmax_pre hour"`
itime2_pre=`date +%H --date="${iyear1}-${imonth1}-${idate1} ${itime1} $timmax_pre hour"`
yyyymmdd2_pre=${iyear2_pre}${imonth2_pre}${idate2_pre}

# diretórios
dir_local=`pwd`
dirbase_escaped="\/mnt\/beegfs\/denis.eiras\/ioper_brams6.0"

# my_atmos_idir="${dir_local}/my_external/${hoje}/dataout/GFS_0p25/"
cams="$dirbase_escaped\/datafix\/CAMS\/"
atmos_idir_prefix_escaped="${dirbase_escaped}\/data\/external"
external_dir="${dir_local}/data/external"
my_external_dir="${dir_local}/my_external"
atmos_idir="${external_dir}/${hoje}/dataout/GFS_0p25/"
umid_solo_dir="${my_external_dir}/${hoje}/dataout/umid_solo"


# outros params
queue="PESQ2"
xsub_ini_iau0_name="xsub_ini_iau0_${hoje}.sh"


if [ ${_fase} == "PREPARAR_AMBIENTE" ]; then
  rm -rf ${my_external_dir}

  echo
  echo "Criando diretórios ..."
  mkdir -p "./${hoje}"
  mkdir -p "./${hoje}/datain"
  mkdir -p "./${hoje}/dataout"
  mkdir -p "./${hoje}/dataout/ANL"
  mkdir -p "./${hoje}/dataout/HIS"
  mkdir -p "./${hoje}/dataout/IVAR"
  mkdir -p "./${hoje}/dataout/IC"
  mkdir -p "./${hoje}/dataout/POST"
  mkdir -p "./${hoje}/dataout/LOG"
  mkdir -p "./${hoje}/dataout/SFC"
  mkdir -p "./${hoje}/dataout/UMD"
  mkdir -p "./${hoje}/datain/GRADS"
  mkdir -p "./${hoje}/datain/QUEIMA"

  mkdir -p "./${hoje}/dataout/IAU_tendencies"  # TODO precisa ?
  mkdir -p ${umid_solo_dir}


  # ~~~~~~~~~~~~~~~ Criação de RAMSINS ~~~~~~~~~~~~~~~
  echo
  echo "Criando RAMSINS ..."

  cat < ./templates_meteo/RAMSIN_TEMPLATE_BASIC \
    | sed "s/{DATE}/${hoje}/g" \
    | sed "s/{USMODEL_IN}/${usmodel_in}/g" \
    | sed "s/{USDATA_IN}/${usdata_in}/g" \
    | sed "s/{NNXP}/${nnxp}/g"   \
    | sed "s/{NNYP}/${nnyp}/g"   \
    | sed "s/{NNZP}/${nnzp}/g"   \
    | sed "s/{DELTAX}/${deltax}/g"                  \
    | sed "s/{DELTAY}/${deltay}/g"                  \
    | sed "s/{DTLONG}/${dtlong}/g"                  \
    | sed "s/{POLELAT}/${polelat}/g"                \
    | sed "s/{POLELON}/${polelon}/g"                \
    | sed "s/{CENTLAT}/${centlat}/g"                \
    | sed "s/{CENTLON}/${centlon}/g"                \
    | sed "s/{CHEM_TIMESTEP}/${chem_timestep}/g"    \
    | sed "s/{CHEM_ASSIM}/${chem_assim}/g"          \
    | sed "s/{SRCMAPFN}/${srcmapfn}/g" \
    | sed "s/{AER_ASSIM}/${aer_assim}/g"            \
    | sed "s/{FRQANL}/${frqanl}/g"                  \
    | sed "s/{HFILOUT}/${hfilout}/g"                 \
    | sed "s/{AFILOUT}/${afilout}/g"                 \
    | sed "s/{USDATA_IN}/${usdata_in}/g"            \
    | sed "s/{USMODEL_IN}/${usmodel_in}/g"          \
    | sed "s/{ICPREFIX}/${icprefix}/g"  > RAMSIN_TEMPLATE_BASIC_TMP

  cat < ./templates_meteo/RAMSIN_TEMPLATE_ADVANCED  \
    | sed "s/{DATE}/${hoje}/g"                      \
    | sed "s/{RECYCLE_TRACERS}/${recycle_tracers}/g"\
    | sed "s/{PASTFN}/${pastfn}/g"                  \
    | sed "s/{APPLYIAU}/${applyiau}/g"              \
    | sed "s/{IMONTH1}/${imonth1}/g"                \
    | sed "s/{IDATE1}/${idate1}/g"                  \
    | sed "s/{IYEAR1}/${iyear1}/g"                  \
    | sed "s/{ITIME1}/${itime1}/g"                  \
    | sed "s/{GPREFIX}/${gprefix}/g" > RAMSIN_TEMPLATE_ADVANCED_TMP


  # para makesfc e makevfile 
  ipos=0
  expnme=$expnme-IAU${applyiau}

  # MAKESFC
  cat < RAMSIN_TEMPLATE_BASIC_TMP    \
    | sed "s/{RUNTYPE}/MAKESFC/g"    \
    | sed "s/{EXPNME}/${expnme}/g"   \
    | sed "s/{IPOS}/${ipos}/g"       \
    | sed "s/{IYEAR1}/${iyear1}/g"   \
    | sed "s/{IMONTH1}/${imonth1}/g" \
    | sed "s/{IDATE1}/${idate1}/g"   \
    | sed "s/{ITIME1}/${itime1}/g"   \
    | sed "s/{TIMMAX}/${timmax}/g" > RAMSIN_BASIC_MAKESFC_${hoje}
  cp RAMSIN_TEMPLATE_ADVANCED_TMP RAMSIN_ADVANCED_MAKESFC_${hoje}

  # MAKEVFILE
  tstart=${hoje}
  curr_hour=0
  while [ $curr_hour -le $timmax_vfl ]; do
    x_ano=${tstart:0:4}
    x_mes=${tstart:4:2}
    x_dia=${tstart:6:2}
    x_hora=${tstart:8:2}

    cat < RAMSIN_TEMPLATE_BASIC_TMP \
      | sed "s/{RUNTYPE}/MAKEVFILE/g" \
      | sed "s/{EXPNME}/${expnme}/g" \
      | sed "s/{IPOS}/${ipos}/g" \
      | sed "s/{IYEAR1}/${x_ano}/g" \
      | sed "s/{IMONTH1}/${x_mes}/g" \
      | sed "s/{IDATE1}/${x_dia}/g" \
      | sed "s/{ITIME1}/${x_hora}/g" \
      | sed "s/{TIMMAX}/3/g" > RAMSIN_BASIC_MAKEVFILE_$tstart
      cp RAMSIN_TEMPLATE_ADVANCED_TMP RAMSIN_ADVANCED_MAKEVFILE_${tstart}

      curr_hour=$(($curr_hour+$inc_hour))
      # soma de novo caso não esteja no último horário (vfl faz 2 horários por vez)
      if [ $curr_hour -lt $timmax_vfl ]; then
        tstart=`date +%Y%m%d%H --date="$x_ano-$x_mes-$x_dia $x_hora $inc_hour_double hour"`
        curr_hour=$(($curr_hour+$inc_hour))
      else
        tstart=`date +%Y%m%d%H --date="$x_ano-$x_mes-$x_dia $x_hora $inc_hour hour"`
      fi
  done

  # INITIAL IAU=0
  ipos=2
  expnme=$expnme-IAU${applyiau}

  cat < RAMSIN_TEMPLATE_BASIC_TMP \
    | sed "s/{RUNTYPE}/INITIAL/g" \
    | sed "s/{EXPNME}/${expnme}/g" \
    | sed "s/{IPOS}/${ipos}/g" \
    | sed "s/{IYEAR1}/${iyear1}/g"   \
    | sed "s/{IMONTH1}/${imonth1}/g" \
    | sed "s/{IDATE1}/${idate1}/g"   \
    | sed "s/{ITIME1}/${itime1}/g"   \
    | sed "s/{TIMMAX}/${timmax}/g" > RAMSIN_BASIC_INITIAL_${hoje}
  
  cp RAMSIN_TEMPLATE_ADVANCED_TMP RAMSIN_ADVANCED_INITIAL_${hoje}

  rm RAMSIN_TEMPLATE_BASIC_TMP RAMSIN_TEMPLATE_ADVANCED_TMP

  # template do grads
  cat < "./templates_meteo/template_post.ctl" \
    | sed "s/{IYEAR1}/${iyear1}/g"   \
    | sed "s/{month_str}/jan/g"     \
    | sed "s/{IDATE1}/${idate1}/g" > "./${hoje}/dataout/POST/template.ctl"


  # ~~~~~~~~~~~~~~~ Criação de Jobs de Submissão ~~~~~~~~~~~~~~~
  echo
  echo "Criando arquivos de submissão ..."
 
  # exec is a link
  # executable="${dir_local}/EXEC/brams-exec"
  
  xsub_sfc_name="xsub_sfc_${hoje}.sh"
  echo "Criando Submit para o MAKESFC - "${xsub_sfc_name}" ..."
  select=1
  ncpus=1
  mpiprocs=1
  wall="01:00:00"
  jobname="BRS_${hoje}"
  nproc=1
  ramsin="RAMSIN_BASIC_MAKESFC_${hoje}"
  
  # 1 proc
  executable_escaped_1proc="${dirbase_escaped}\/EXEC\/brams_exec_1proc"
  exec_and_ramsin_1proc="${executable_escaped_1proc} -f ${ramsin}"
  
  # + de 1 proc - INTEL 
  executable_escaped="${dirbase_escaped}\/EXEC\/brams_exec"
  exec_and_ramsin="${executable_escaped} -f ${ramsin}"

  cat < ./templates_meteo/SLURM_EGEON_TEMPLATE \
       | sed "s/{QUEUE}/${queue}/g" \
       | sed "s/{SELECT}/${select}/g" \
       | sed "s/{MPIPROCS}/${mpiprocs}/g" \
       | sed "s/{NCPUS}/${ncpus}/g" \
       | sed "s/{WALL}/${wall}/g" \
       | sed "s/{JOBNAME}/${jobname}/g" \
       | sed "s/{DIRBASE}/${dirbase_escaped}/g" \
       | sed "s/{NPROC}/${nproc}/g" \
       | sed "s/{COMP_ENV}/${comp_env}/g" \
       | sed "s/{EXECUTABLE}/${exec_and_ramsin_1proc}/g" > ${xsub_sfc_name}
  chmod +x ${xsub_sfc_name}


  echo "Criando Submit para o MAKEVFILE da primeira hora ${hoje} a ${timmax_vfl} hora ..."
  wall="00:10:00"
  tstart=${hoje}
  curr_hour=0
  while [ $curr_hour -le $timmax_vfl ]; do
    x_ano=${tstart:0:4}
    x_mes=${tstart:4:2}
    x_dia=${tstart:6:2}
    x_hora=${tstart:8:2}

    jobname="BRV_${tstart}"
    ramsin="RAMSIN_BASIC_MAKEVFILE_${tstart}"
    exec_and_ramsin_1proc="${executable_escaped_1proc} -f ${ramsin}"
    xsub_vfl_name="xsub_vfl_${tstart}.sh"
    cat < ./templates_meteo/SLURM_EGEON_TEMPLATE \
       | sed "s/{QUEUE}/${queue}/g" \
       | sed "s/{SELECT}/${select}/g" \
       | sed "s/{MPIPROCS}/${mpiprocs}/g" \
       | sed "s/{NCPUS}/${ncpus}/g" \
       | sed "s/{WALL}/${wall}/g" \
       | sed "s/{JOBNAME}/${jobname}/g" \
       | sed "s/{DIRBASE}/${dirbase_escaped}/g" \
       | sed "s/{NPROC}/${nproc}/g" \
       | sed "s/{COMP_ENV}/${comp_env}/g" \
       | sed "s/{EXECUTABLE}/${exec_and_ramsin_1proc}/g" > ${xsub_vfl_name}
    chmod +x ${xsub_vfl_name}

    curr_hour=$(($curr_hour+$inc_hour))
    # soma de novo caso não esteja no último horário (vfl faz 2 horários por vez)
    if [ $curr_hour -lt $timmax_vfl ]; then
      tstart=`date +%Y%m%d%H --date="$x_ano-$x_mes-$x_dia $x_hora $inc_hour_double hour"`
      curr_hour=$(($curr_hour+$inc_hour))
    else
      tstart=`date +%Y%m%d%H --date="$x_ano-$x_mes-$x_dia $x_hora $inc_hour hour"`
    fi

  done

  echo "Criando Submit para o INITIAL - ${xsub_ini_iau0_name} ..."
  select=8
  ncpus=128
  mpiprocs=1024
  wall="02:00:00"
  jobname="BRI0_${hoje}"
  ramsin="RAMSIN_BASIC_INITIAL_${hoje}"
  exec_and_ramsin="${executable_escaped} -f ${ramsin}"
  cat < ./templates_meteo/SLURM_EGEON_TEMPLATE \
       | sed "s/{QUEUE}/${queue}/g" \
       | sed "s/{SELECT}/${select}/g" \
       | sed "s/{MPIPROCS}/${mpiprocs}/g" \
       | sed "s/{NCPUS}/${ncpus}/g" \
       | sed "s/{WALL}/${wall}/g" \
       | sed "s/{JOBNAME}/${jobname}/g" \
       | sed "s/{DIRBASE}/${dirbase_escaped}/g" \
       | sed "s/{COMP_ENV}/${comp_env}/g" \
       | sed "s/{EXECUTABLE}/${exec_and_ramsin}/g" > ${xsub_ini_iau0_name}
    chmod +x ${xsub_ini_iau0_name}

  echo "Criando namelist para o Prep à partir das 00h do dia atual - pre_${hoje}.nml até ${yyyymmdd2_pre}"

  pre_step="3"  # fix = vfl
  hoje_yyyymmdd=${hoje:0:8}
  echo $hoje_yyyymmdd

  cat < ./templates_meteo/PRE_TEMPLATE \
       | sed "s/{TIME_FILE_GFS}/00/g" \
       | sed "s/{ATMOS_IDIR_PREFIX}/${atmos_idir_prefix_escaped}/g" \
       | sed "s/{PRE_STEP}/${pre_step}/g" \
       | sed "s/{IMONTH1}/${_mes}/g" \
       | sed "s/{IDATE1}/${_dia}/g" \
       | sed "s/{IYEAR1}/${_ano}/g" \
       | sed "s/{ITIME1}/00/g" \
       | sed "s/{IMONTH2}/${imonth2_pre}/g" \
       | sed "s/{IDATE2}/${idate2_pre}/g" \
       | sed "s/{IYEAR2}/${iyear2_pre}/g" \
       | sed "s/{ITIME2}/${itime2_pre}/g" \
       | sed "s/{DATE}/${hoje_yyyymmdd}/g" \
       | sed "s/{PREP_OUT_DIR}/${icdir}/g" \
       | sed "s/{CAMS}/${cams}/g" \
       | sed "s/{DIRBASE}/${dirbase_escaped}/g" \
       > pre_${hoje}.nml


  echo
  echo "Entrando no diretório "${dir_local}
  cd ${dir_local}
  echo "Criando diretório temporário e variável de ambiente TMPDIR ..."
  export TMPDIR="${dir_local}/tmp"
  mkdir -p ${TMPDIR}

  echo
  echo "Extraindo os dados de umidade do GFS ..."

  file_for_smoist="${atmos_idir}/gfs.t00z.pgrb2.0p25.f000.${hoje}.grib2"

  ./wgrib2 ${file_for_smoist} -s | grep 'TSOIL\|SOILW' | ./wgrib2 -i ${file_for_smoist} -netcdf tmp_out.nc
  smoist_file="${umid_solo_dir}/GFS.SOIL:UMID_TEMP.${hoje}"
  grads -lc "run ./auxProgs/gerabin.gs tmp_out.nc ${smoist_file}"
  rm tmp_out.nc

  echo
  echo "Gerando os dados de SST ..."
  ./geraSST2RAMS.bash "${hoje}" ${external_dir}

  fi  # fim fase PREPARAR_AMBIENTE



# ~~~~~~~~~~~~~~~ Submissão de Jobs ~~~~~~~~~~~~~~~

if [ ${_fase} == "MAKESFC" ]; then
  echo
  echo "Submeterndo job xsub_sfc_${hoje}.sh"
  sbatch xsub_sfc_${hoje}.sh
fi


if [ ${_fase} == "MAKEVFL" ]; then
  # caso parar o PRE no meio do processo

  xsub_prep_name='./xsub_prep.sh'
  echo "Criando Submit para o Pre - ${xsub_prep_name} ..."
  select=1
  ncpus=1
  mpiprocs=1
  nproc=1
  wall="00:30:00"
  jobname="BR_PRE_${hoje}"
  pre_exec_escaped='\.\/EXEC\/pre_exec'
  cat < ./templates_meteo/SLURM_EGEON_TEMPLATE \
       | sed "s/{QUEUE}/${queue}/g" \
       | sed "s/{SELECT}/${select}/g" \
       | sed "s/{MPIPROCS}/${mpiprocs}/g" \
       | sed "s/{NCPUS}/${ncpus}/g" \
       | sed "s/{WALL}/${wall}/g" \
       | sed "s/{JOBNAME}/${jobname}/g" \
       | sed "s/{DIRBASE}/${dirbase_escaped}/g" \
       | sed "s/{NPROC}/${nproc}/g" \
       | sed "s/{COMP_ENV}/${comp_env}/g" \
       | sed "s/{EXECUTABLE}/${pre_exec_escaped}/g" > ${xsub_prep_name}
  chmod +x ${xsub_prep_name}

  echo
  echo "Executando prep na data = ${hoje}"
  ln -sf pre_${hoje}.nml pre.nml
  sleep 2 && tail -f ${jobname}.out &
  sbatch -W ${xsub_prep_name}
  
  echo
  echo "Iniiciando submissão dos jobs makevfile ..."
  tstart=${hoje}
  curr_hour=0
  while [ $curr_hour -le $timmax_vfl ]; do
    x_ano=${tstart:0:4}
    x_mes=${tstart:4:2}
    x_dia=${tstart:6:2}
    x_hora=${tstart:8:2}
    echo "Submetendo job xsub_vfl_$tstart.sh"
  	sbatch xsub_vfl_$tstart.sh

    curr_hour=$(($curr_hour+$inc_hour))
    # soma de novo caso não esteja no último horário (vfl faz 2 horários por vez)
    if [ $curr_hour -lt $timmax_vfl ]; then
		  tstart=`date +%Y%m%d%H --date="$x_ano-$x_mes-$x_dia $x_hora $inc_hour_double hour"`
		  curr_hour=$(($curr_hour+$inc_hour))
		else
		  tstart=`date +%Y%m%d%H --date="$x_ano-$x_mes-$x_dia $x_hora $inc_hour hour"`
    fi

  done

  rm -f *.ctl *.inv *.blow *.gra DumpMemory* ts*.out *.done
fi


if [ ${_fase} == "INITIAL" ]; then
  echo "Submeterndo job ${xsub_ini_iau0_name}"
  sbatch ${xsub_ini_iau0_name}
fi



# fim do script















