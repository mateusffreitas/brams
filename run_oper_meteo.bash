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
# - SFC: Executar o MAKESFC para a data informada
#
# - VFL: Extrai os dados de umidade do Solo do GFS; Executa o PRE do BRAMS usando os arquivo do GFS do dia anterior (18H) com relação à linha
#        de comando informada, gerando os arquivos de condições iniciais das 21H do dia anterior. Depois gera as condições iniciais das 00h
#        do dia atual até 7 dias pra frente (171h no total). Em seguida, executa a fase MAKEVFILE, utilizando os arquivos gerados pelo PRE.
#        *** Observação ***: Verifique o comentário abaixo 'hack provisório executar o pré somente para 2 horários', que explica um workaround a ser
#        utilizado, até que uma correção no PRE seja feita.
#
# - INITIAL_IAU1: Executa a fase INITIAL às 21h do dia anterior com IAU=1, por 3 horas, utilizado o arquivo das 21H que foi gerado à partir do arquivo das 18h do GFS
#
# - INITIAL_IAU2: Executa a fase INITIAL às 21h do dia anterior com IAU=2, por 171 horas, utilizando os demais arquivos gerados pela fase VFL.
#
# - INITIAL_IAU0: *** Essa fase não deve ser executada operacionalmente ***
#                 Executa a fase INITIAL às 21h do dia anterior com IAU=0, por 171 horas, utilizando os demais arquivos gerados pela fase VFL.
#



# ~~~~~~~~~~~~~~~ Início do script ~~~~~~~~~~~~~~~

_fase=$4
_dia=$3
_mes=$2
_ano=$1

echo
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Iniciando execução da fase ${_fase} ... "
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
module swap gnu9 intel
module swap openmpi4 impi
module load phdf5
module load netcdf
module load netcdf-fortran
module load hwloc
echo "Lista de módulos carregados: "
module list

_NOVA_DATA="-1"
_NOVA_DATA=`echo $_NOVA_DATA | tr "-" " "`
ontem=`date +%Y%m%d --date="$_ano-$_mes-$_dia $_HORA $_NOVA_DATA day ago"`
diao=`date +%d --date="${ontem}"`
meso=`date +%m --date="${ontem}"`
anoo=`date +%Y --date="${ontem}"`

hoje=${_ano}${_mes}${_dia}00
# ontem21h=${ontem}"21"

_NOVA_DATA="-2"
_NOVA_DATA=`echo $_NOVA_DATA | tr "-" " "`
anteontem=`date +%Y%m%d --date="$_ano-$_mes-$_dia $_HORA $_NOVA_DATA day ago"`

# Parâmetros do RAMSIN
expnme=BRAMS-8km

# 7 dias mais 3 horas
timmax=171

imonth1=${meso}
idate1=${diao}
iyear1=${anoo}
itime1=21

nnxp=1017
nnyp=993
nnzp=45
deltax=8000.
deltay=8000.
dtlong=45.
polelat=-14.0
polelon=-56.0
centlat=-14.0
centlon=-56.0
chem_timestep=320.
chem_assim=0
aer_assim=0
srcmapfn="'NONE'"
recycle_tracers=0
frqanl=10800.
hfilout="'.\/${hoje}\/dataout\/ANL\/HOPQUE'"
afilout="'.\/${hoje}\/dataout\/ANL\/OPQUE'"
pastfn="'.\/$ontem\/dataout\/ANL\/OPQUE-A-$1-$2-$3-000000-head.txt'"
topfiles="'.\/${hoje}\/dataout\/sfc\/top_oq3g'"
sfcfiles="'.\/${hoje}\/dataout\/sfc\/sfc_oq3g'"
sstfpfx="'.\/${hoje}\/dataout\/sfc\/sst_oq3g'"
ndvifpfx="'.\/${hoje}\/sfc\/ndv_oq3g'"
usdata_in="'.\/my_external\/"${hoje}"\/dataout\/umid_solo\/GFS.SOIL:UMID_TEMP.'"
usmodel_in="'.\/${hoje}\/dataout\/UMD\/gl_sm_gpnr.'"
icprefix="'.\/${hoje}\/datain\/grads\/ic'"
icgradsprefix="'.\/${hoje}\/dataout\/ic\/icgrads'"
gprefix="'.\/${hoje}\/dataout\/post\/chem'"

# outros parâmetros
inc_hour=3
inc_hour_double=6
timmax_vfl=171
timmax_pre=171
idate2_pre=`date +%d --date="${iyear1}-${imonth1}-${idate1} ${itime1} $timmax_pre hour"`
imonth2_pre=`date +%m --date="${iyear1}-${imonth1}-${idate1} ${itime1} $timmax_pre hour"`
iyear2_pre=`date +%Y --date="${iyear1}-${imonth1}-${idate1} ${itime1} $timmax_pre hour"`
itime2_pre=`date +%H --date="${iyear1}-${imonth1}-${idate1} ${itime1} $timmax_pre hour"`
yyyymmdd2_pre=${iyear2_pre}${imonth2_pre}${idate2_pre}

dir_local=`pwd`
my_atmos_idir="${dir_local}/my_external/${hoje}/dataout/GFS_0p25/"
xsub_ini_iau0_name="xsub_ini_iau0_${hoje}.sh"



if [ ${_fase} == "PREPARAR_AMBIENTE" ]; then
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

  mkdir -p "./${hoje}/dataout/IAU_tendencies"
  mkdir -p "./my_external/${hoje}/dataout/umid_solo"
  rm -rf ${my_atmos_idir}
  mkdir -p ${my_atmos_idir}



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

  cat < ./templates_meteo/RAMSIN_TEMPLATE_ADVANCED \
    | sed "s/{DATE}/${hoje}/g" \
    | sed "s/{RECYCLE_TRACERS}/${recycle_tracers}/g"\
    | sed "s/{PASTFN}/${pastfn}/g"                  \
    | sed "s/{GPREFIX}/${gprefix}/g" > RAMSIN_TEMPLATE_ADVANCED_TMP


  # para makesfc e makevfile 

  iau=0
  ipos=0
  expnme=$expnme-IAU${iau}
  applyiau=${iau}

  # MAKESFC
  cat < RAMSIN_TEMPLATE_BASIC_TMP \
    | sed "s/{RUNTYPE}/MAKESFC/g" \
    | sed "s/{EXPNME}/${expnme}/g" \
    | sed "s/{APPLYIAU}/${applyiau}/g" \
    | sed "s/{IPOS}/${ipos}/g" \
    | sed "s/{IMONTH1}/${imonth1}/g" \
    | sed "s/{IDATE1}/${idate1}/g" \
    | sed "s/{IYEAR1}/${iyear1}/g" \
    | sed "s/{ITIME1}/${itime1}/g" \
    | sed "s/{TIMMAX}/${timmax}/g" > RAMSIN_BASIC_SFC_${hoje}
  cp RAMSIN_TEMPLATE_ADVANCED_TMP RAMSIN_ADVANCED_SFC_${hoje}

  # MAKEVFILE
  cat < RAMSIN_TEMPLATE_BASIC_TMP \
    | sed "s/{RUNTYPE}/MAKEVFILE/g" \
    | sed "s/{EXPNME}/${expnme}/g" \
    | sed "s/{APPLYIAU}/${applyiau}/g" \
    | sed "s/{IPOS}/${ipos}/g" \
    | sed "s/{IYEAR1}/${iyear1}/g" \
    | sed "s/{IMONTH1}/${imonth1}/g" \
    | sed "s/{IDATE1}/${idate1}/g" \
    | sed "s/{ITIME1}/1800/g" \
    | sed "s/{TIMMAX}/6/g" > RAMSIN_BASIC_VFL_${hoje}
  cp RAMSIN_TEMPLATE_ADVANCED_TMP RAMSIN_ADVANCED_VFL_${hoje}

  tstart=${hoje}
  curr_hour=0
  while [ $curr_hour -lt $timmax_vfl ]; do
    x_ano=${tstart:0:4}
    x_mes=${tstart:4:2}
    x_dia=${tstart:6:2}
    x_hora=${tstart:8:2}

    cat < RAMSIN_TEMPLATE_BASIC_TMP \
      | sed "s/{RUNTYPE}/MAKEVFILE/g" \
      | sed "s/{EXPNME}/${expnme}/g" \
      | sed "s/{APPLYIAU}/${applyiau}/g" \
      | sed "s/{IPOS}/${ipos}/g" \
      | sed "s/{IYEAR1}/${x_ano}/g" \
      | sed "s/{IMONTH1}/${x_mes}/g" \
      | sed "s/{IDATE1}/${x_dia}/g" \
      | sed "s/{ITIME1}/${x_hora}/g" \
      | sed "s/{TIMMAX}/3/g" > RAMSIN_BASIC_VFL_$tstart
      cp RAMSIN_TEMPLATE_ADVANCED_TMP RAMSIN_ADVANCED_VFL_${tstart}

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
  expnme=$expnme-IAU${iau}
  applyiau=${iau}
  cat < RAMSIN_TEMPLATE_BASIC_TMP \
       | sed "s/{RUNTYPE}/INITIAL/g" \
       | sed "s/{EXPNME}/${expnme}/g" \
       | sed "s/{APPLYIAU}/${applyiau}/g" \
       | sed "s/{IPOS}/${ipos}/g" \
       | sed "s/{IMONTH1}/${imonth1}/g" \
       | sed "s/{IDATE1}/${idate1}/g" \
       | sed "s/{IYEAR1}/${iyear1}/g" \
       | sed "s/{ITIME1}/${itime1}/g" \
       | sed "s/{TIMMAX}/${timmax}/g" > RAMSIN_INI_IAU0_${hoje}

  # rm RAMSIN_TEMPLATE_BASIC_TMP RAMSIN_TEMPLATE_ADVANCED_TMP



  # ~~~~~~~~~~~~~~~ Criação de Jobs de Submissão ~~~~~~~~~~~~~~~
  echo
  echo "Criando arquivos de submissão ..."
  dirbase_escaped="\/mnt\/beegfs\/denis.eiras\/ioper_brams6.0"
  # exec is a link
  executable="${dirbase_escaped}\/EXEC\/brams_exec"
  dirbase="${dir_local}"
  executable_no_sed="${dirbase}/EXEC/brams-exec"

  xsub_sfc_name="xsub_sfc_${hoje}.sh"
  echo "Criando Submit para o MAKESFC - "${xsub_sfc_name}" ..."
  queue="pesq2"
  select=1
  ncpus=1
  mpiprocs=1
  wall="01:00:00"
  jobname="BRS_${hoje}"
  nproc=1
  ramsin="RAMSIN_BASIC_SFC_${hoje}"

  cat < ./templates_meteo/SLURM_EGEON_TEMPLATE \
       | sed "s/{QUEUE}/${queue}/g" \
       | sed "s/{SELECT}/${select}/g" \
       | sed "s/{MPIPROCS}/${mpiprocs}/g" \
       | sed "s/{NCPUS}/${ncpus}/g" \
       | sed "s/{WALL}/${wall}/g" \
       | sed "s/{JOBNAME}/${jobname}/g" \
       | sed "s/{DIRBASE}/${dirbase_escaped}/g" \
       | sed "s/{NPROC}/${nproc}/g" \
       | sed "s/{EXECUTABLE}/${executable}/g" \
       | sed "s/{RAMSIN}/${ramsin}/g" > ${xsub_sfc_name}
  chmod +x ${xsub_sfc_name}


  echo "Criando Submit para o MAKEVFILE da primeira hora ${hoje} a ${timmax_vfl} hora ..."
  wall="00:10:00"
  tstart=${hoje}
  curr_hour=0
  while [ $curr_hour -lt $timmax_vfl ]; do
    x_ano=${tstart:0:4}
    x_mes=${tstart:4:2}
    x_dia=${tstart:6:2}
    x_hora=${tstart:8:2}

    jobname="BRV_${tstart}"
    ramsin="RAMSIN_BASIC_VFL_${tstart}"
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
       | sed "s/{EXECUTABLE}/${executable}/g" \
       | sed "s/{RAMSIN}/${ramsin}/g" > ${xsub_vfl_name}
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

  echo "Criando Submit para o INITIAL_IAU0 - ${xsub_ini_iau0_name} ..."
  select=8
  ncpus=128
  mpiprocs=128
  nproc=1040
  wall="04:00:00"
  jobname="BRI0_${hoje}"
  ramsin="RAMSIN_INI_IAU0_${hoje}"
  cat < ./templates_meteo/SLURM_EGEON_TEMPLATE \
       | sed "s/{QUEUE}/${queue}/g" \
       | sed "s/{SELECT}/${select}/g" \
       | sed "s/{MPIPROCS}/${mpiprocs}/g" \
       | sed "s/{NCPUS}/${ncpus}/g" \
       | sed "s/{WALL}/${wall}/g" \
       | sed "s/{JOBNAME}/${jobname}/g" \
       | sed "s/{DIRBASE}/${dirbase_escaped}/g" \
       | sed "s/{NPROC}/${nproc}/g" \
       | sed "s/{EXECUTABLE}/${executable}/g" \
       | sed "s/{RAMSIN}/${ramsin}/g" > ${xsub_ini_iau0_name}
  chmod +x ${xsub_ini_iau0_name}



  # ~~~~~~~~~~~~~~~ Criação de namelists para o Prep ~~~~~~~~~~~~~~~

  cams="$dirbase_escaped\/datafix\/CAMS\/"

  echo
  echo "Criando namelist para o Prep de ontem 21h - pre_${hoje}.nml ..."

  pre_step="3"
  # Para obter os arquivos do GFS do horário das 18 ...
  # wget "https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.${ontem}/${time_file_gfs_ini_orig}/gfs.t${time_file_gfs_ini_orig}z.pgrb2.0p25.f000 -o ${my_atmos_idir}
  # wget "https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.${ontem}/${time_file_gfs_ini_orig}/gfs.t${time_file_gfs_ini_orig}z.pgrb2.0p25.f003 -o ${my_atmos_idir}

  echo "Criando namelist para o Prep à partir das 00h do dia atual - pre_${hoje}.nml até ${yyyymmdd2_pre}"
  cams="$dirbase_escaped\/datafix\/CAMS\/"

  atmos_idir_prefix="${dirbase_escaped}\/data\/external"
  cat < ./templates_meteo/PRE_TEMPLATE \
       | sed "s/{TIME_FILE_GFS}/00/g" \
       | sed "s/{ATMOS_IDIR_PREFIX}/${atmos_idir_prefix}/g" \
       | sed "s/{PRE_STEP}/${pre_step}/g" \
       | sed "s/{IMONTH1}/${_mes}/g" \
       | sed "s/{IDATE1}/${_dia}/g" \
       | sed "s/{IYEAR1}/${_ano}/g" \
       | sed "s/{ITIME1}/00/g" \
       | sed "s/{IMONTH2}/${imonth2_pre}/g" \
       | sed "s/{IDATE2}/${idate2_pre}/g" \
       | sed "s/{IYEAR2}/${iyear2_pre}/g" \
       | sed "s/{ITIME2}/${itime2_pre}/g" \
       | sed "s/{DATE}/${hoje}/g" \
       | sed "s/{PREP_OUT_DIR}/${prep_out_dir}/g" \
       | sed "s/{CAMS}/${cams}/g" \
       | sed "s/{DIRBASE}/${dirbase_escaped}/g" \
       > pre_${hoje}.nml

  echo
  echo "Entrando no diretório "${dir_local}
  cd ${dir_local}
  echo "Criando diretório temporário e variável de ambiente TMPDIR ..."
  export TMPDIR="${dirbase}/tmp"
  mkdir -p ${TMPDIR}

  echo
  echo "Extraindo os dados de umidade do GFS ..."

  # TODO CHECH file ***************************************************
  # TODO CHECH file ***************************************************
  # TODO CHECH file ***************************************************
  file_for_smoist="${my_atmos_idir}/gfs.t00z.pgrb2.0p25.f001.${hoje}.grib2"

  wgrib2 ${file_for_smoist} -s | grep 'TSOIL\|SOILW' | wgrib2 -i ${file_for_smoist} -netcdf tmp_out.nc
  smoist_file="${dirbase}/my_external/"${hoje}"/dataout/umid_solo/GFS.SOIL:UMID_TEMP.${hoje}"
  grads -lc "run ./gerabin.gs tmp_out.nc ${smoist_file}"
  rm tmp_out.nc

  echo
  echo "Gerando os dados de SST ..."
  ./geraSST2RAMS.bash "${hoje}"

fi  # fim fase PREPARAR_AMBIENTE



# ~~~~~~~~~~~~~~~ Submissão de Jobs ~~~~~~~~~~~~~~~

if [ ${_fase} == "SFC" ]; then
  echo
  echo "Submeterndo job xsub_sfc_${hoje}.sh"
  qsub xsub_sfc_${hoje}.sh
fi


if [ ${_fase} == "VFL" ]; then
  rm -f *.ctl *.inv *.blow *.gra  # caso parar o PRE no meio do processo
  echo
  echo "

#!/bin/bash
#SBATCH --job-name=BRAMSprep
#SBATCH --nodes=1
#SBATCH --partition=${queue}
#SBATCH --tasks-per-node=${ncpus}
#SBATCH --ntasks=1
#SBATCH --time=00:30:00
#sbatch --mem-per-cpu=64000M
#SBATCH --output=BRAMSprep.log
#SBATCH --exclusive

cd $SLURM_SUBMIT_DIR
echo $SLURM_SUBMIT_DIR
module swap gnu9 intel
module swap openmpi4 impi
module load phdf5
module load netcdf
module load netcdf-fortran
module load hwloc
echo "Lista de módulos carregados: "
module list
echo "============================="

cd ${dirbase}
export TMPDIR=${dirbase}/tmp

ulimit -s unlimited
MPI_PARAMS="-iface ib0 -bind-to core -map-by core"
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export I_MPI_DEBUG=5
export MKL_DEBUG_CPU_TYPE=5
mpirun -env MKL_DEBUG_CPU_TYPE=5 -env UCX_NET_DEVICES=mlx5_0:1 -genvall ./EXEC/prep_1.0 &> prep.log

set +x  "  > ./xsub_prep.sh

  echo "Executando prep na data de iau2 = ${hoje}"
  ln -sf pre_${hoje}.nml pre.nml
  sleep 10 && tail -f prep.log &
  sbatch -W ./xsub_prep.sh
  mv prep.log prep_${hoje}.log

    echo
  echo "Iniiciando submissão dos jobs makevfile ..."
  tstart=${hoje}
  curr_hour=0
  while [ $curr_hour -lt $timmax_vfl ]; do
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
fi


if [ ${_fase} == "INITIAL_IAU0" ]; then
  echo "Submeterndo job ${xsub_ini_iau0_name}"
  sbatch ${xsub_ini_iau0_name}
fi



# fim do script















