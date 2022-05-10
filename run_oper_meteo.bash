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
module load pbs
module load craype-x86-skylake
module load stat

_NOVA_DATA="-1"
_NOVA_DATA=`echo $_NOVA_DATA | tr "-" " "`
ontem=`date +%Y%m%d --date="$_ano-$_mes-$_dia $_HORA $_NOVA_DATA day ago"`
diao=`date +%d --date="${ontem}"`
meso=`date +%m --date="${ontem}"`
anoo=`date +%Y --date="${ontem}"`

hoje=${_ano}${_mes}${_dia}
ontem21h=${ontem}"21"

_NOVA_DATA="-2"
_NOVA_DATA=`echo $_NOVA_DATA | tr "-" " "`
anteontem=`date +%Y%m%d --date="$_ano-$_mes-$_dia $_HORA $_NOVA_DATA day ago"`

# Parâmetros do RAMSIN
expnme=BRAMS-8km
expnameIAU=$expnme-IAU1

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
hfilout="'.\/${ontem21h}\/dataout\/ANL\/HOPQUE'"
afilout="'.\/${ontem21h}\/dataout\/ANL\/OPQUE'"
pastfn="'.\/$anteontem\/dataout\/ANL\/OPQUE-A-$1-$2-$3-000000-head.txt'"
topfiles="'.\/${ontem21h}\/dataout\/sfc\/top_oq3g'"
sfcfiles="'.\/${ontem21h}\/dataout\/sfc\/sfc_oq3g'"
sstfpfx="'.\/${ontem21h}\/dataout\/sfc\/sst_oq3g'"
ndvifpfx="'.\/${ontem21h}\/sfc\/ndv_oq3g'"
time_file_gfs_ini_orig="18"
usdata_in="'.\/my_external\/"${ontem}${time_file_gfs_ini_orig}"\/dataout\/umid_solo\/GFS.SOIL:UMID_TEMP.'"
usmodel_in="'.\/${ontem21h}\/dataout\/UMD\/gl_sm_gpnr.'"
icprefix="'.\/${ontem21h}\/datain\/grads\/ic'"
icgradsprefix="'.\/${ontem21h}\/dataout\/ic\/icgrads'"
gprefix="'.\/${ontem21h}\/dataout\/post\/chem'"

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

my_atmos_idir="/lustre_xc50/denis_eiras/ioper_brams5.6/my_external/${ontem}${time_file_gfs_ini_orig}/dataout/GFS_0p25/"
xsub_ini_iau1_name="xsub_ini_iau1_${ontem21h}.sh"
xsub_ini_iau2_name="xsub_ini_iau2_${ontem21h}.sh"
xsub_ini_iau0_name="xsub_ini_iau0_${ontem21h}.sh"
dir_local=`pwd`



if [ ${_fase} == "PREPARAR_AMBIENTE" ]; then
  echo
  echo "Criando diretórios ..."
  mkdir -p "./${ontem21h}"
  mkdir -p "./${ontem21h}/datain"
  mkdir -p "./${ontem21h}/dataout"
  mkdir -p "./${ontem21h}/dataout/ANL"
  mkdir -p "./${ontem21h}/dataout/HIS"
  mkdir -p "./${ontem21h}/dataout/IVAR"
  mkdir -p "./${ontem21h}/dataout/IC"
  mkdir -p "./${ontem21h}/dataout/POST"
  mkdir -p "./${ontem21h}/dataout/LOG"
  mkdir -p "./${ontem21h}/dataout/SFC"
  mkdir -p "./${ontem21h}/dataout/UMD"
  mkdir -p "./${ontem21h}/datain/GRADS"
  mkdir -p "./${ontem21h}/datain/QUEIMA"

  mkdir -p "./${ontem21h}/dataout/IAU_tendencies"
  mkdir -p "./my_external/${ontem}${time_file_gfs_ini_orig}/dataout/umid_solo"
  rm -rf ${my_atmos_idir}
  mkdir -p ${my_atmos_idir}



  # ~~~~~~~~~~~~~~~ Criação de RAMSINS ~~~~~~~~~~~~~~~
  echo
  echo "Criando RAMSINS ..."

  cat < ./templates_meteo/RAMSIN_TEMPLATE \
       | sed "s/{USMODEL_IN}/${usmodel_in}/g" \
       | sed "s/{USDATA_IN}/${usdata_in}/g" \
       | sed "s/{DATE}/${ontem21h}/g" \
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
       | sed "s/{AER_ASSIM}/${aer_assim}/g"            \
       | sed "s/{SRCMAPFN}/${srcmapfn}/g" \
       | sed "s/{RECYCLE_TRACERS}/${recycle_tracers}/g"\
       | sed "s/{FRQANL}/${frqanl}/g"                  \
       | sed "s/{HFILOUT}/${hfilout}/g"                 \
       | sed "s/{AFILOUT}/${afilout}/g"                 \
       | sed "s/{PASTFN}/${pastfn}/g"                  \
       | sed "s/{TOPFILES}/${topfiles}/g"               \
       | sed "s/{SFCFILES}/${sfcfiles}/g"               \
       | sed "s/{SSTFPFX}/${sstfpfx}/g"                \
       | sed "s/{NDVIFPFX}/${ndvifpfx}/g"              \
       | sed "s/{USDATA_IN}/${usdata_in}/g"            \
       | sed "s/{USMODEL_IN}/${usmodel_in}/g"          \
       | sed "s/{ICPREFIX}/${icprefix}/g"               \
       | sed "s/{ICGRADSPREFIX}/${icgradsprefix}/g"     \
       | sed "s/{GPREFIX}/${gprefix}/g"                 > RAMSIN_TEMPLATE_TMP

  # para makesfc, makevfile e initial iau=1
  iau=1
  ipos=0
  expnme=$expnme-IAU${iau}
  applyiau=${iau}

  cat < RAMSIN_TEMPLATE_TMP \
    | sed "s/{RUNTYPE}/MAKESFC/g" \
    | sed "s/{EXPNME}/${expnme}/g" \
    | sed "s/{APPLYIAU}/${applyiau}/g" \
    | sed "s/{IPOS}/${ipos}/g" \
    | sed "s/{IMONTH1}/${imonth1}/g" \
    | sed "s/{IDATE1}/${idate1}/g" \
    | sed "s/{IYEAR1}/${iyear1}/g" \
    | sed "s/{ITIME1}/${itime1}/g" \
    | sed "s/{TIMMAX}/${timmax}/g" > RAMSIN_SFC_${ontem21h}

  cat < RAMSIN_TEMPLATE_TMP \
    | sed "s/{RUNTYPE}/MAKEVFILE/g" \
    | sed "s/{EXPNME}/${expnme}/g" \
    | sed "s/{APPLYIAU}/${applyiau}/g" \
    | sed "s/{IPOS}/${ipos}/g" \
    | sed "s/{IYEAR1}/${iyear1}/g" \
    | sed "s/{IMONTH1}/${imonth1}/g" \
    | sed "s/{IDATE1}/${idate1}/g" \
    | sed "s/{ITIME1}/1800/g" \
    | sed "s/{TIMMAX}/6/g" > RAMSIN_VFL_${ontem21h}

  tstart=${ontem21h}

  curr_hour=0
  while [ $curr_hour -lt $timmax_vfl ]; do
    x_ano=${tstart:0:4}
    x_mes=${tstart:4:2}
    x_dia=${tstart:6:2}
    x_hora=${tstart:8:2}

    cat < RAMSIN_TEMPLATE_TMP \
      | sed "s/{RUNTYPE}/MAKEVFILE/g" \
      | sed "s/{EXPNME}/${expnme}/g" \
      | sed "s/{APPLYIAU}/${applyiau}/g" \
      | sed "s/{IPOS}/${ipos}/g" \
      | sed "s/{IYEAR1}/${x_ano}/g" \
      | sed "s/{IMONTH1}/${x_mes}/g" \
      | sed "s/{IDATE1}/${x_dia}/g" \
      | sed "s/{ITIME1}/${x_hora}/g" \
      | sed "s/{TIMMAX}/3/g" > RAMSIN_VFL_$tstart

      curr_hour=$(($curr_hour+$inc_hour))
      # soma de novo caso não esteja no último horário (vfl faz 2 horários por vez)
      if [ $curr_hour -lt $timmax_vfl ]; then
        tstart=`date +%Y%m%d%H --date="$x_ano-$x_mes-$x_dia $x_hora $inc_hour_double hour"`
        curr_hour=$(($curr_hour+$inc_hour))
      else
        tstart=`date +%Y%m%d%H --date="$x_ano-$x_mes-$x_dia $x_hora $inc_hour hour"`
      fi
  done

  cat < RAMSIN_TEMPLATE_TMP \
       | sed "s/{RUNTYPE}/INITIAL/g" \
       | sed "s/{EXPNME}/${expnme}/g" \
       | sed "s/{APPLYIAU}/${applyiau}/g" \
       | sed "s/{IPOS}/${ipos}/g" \
       | sed "s/{IMONTH1}/${imonth1}/g" \
       | sed "s/{IDATE1}/${idate1}/g" \
       | sed "s/{IYEAR1}/${iyear1}/g" \
       | sed "s/{ITIME1}/${itime1}/g" \
       | sed "s/{TIMMAX}/3/g" > RAMSIN_INI_IAU1_${ontem21h}

  iau=2
  ipos=2
  expnme=$expnme-IAU${iau}
  applyiau=${iau}
  cat < RAMSIN_TEMPLATE_TMP \
       | sed "s/{RUNTYPE}/INITIAL/g" \
       | sed "s/{EXPNME}/${expnme}/g" \
       | sed "s/{APPLYIAU}/${applyiau}/g" \
       | sed "s/{IPOS}/${ipos}/g" \
       | sed "s/{IMONTH1}/${imonth1}/g" \
       | sed "s/{IDATE1}/${idate1}/g" \
       | sed "s/{IYEAR1}/${iyear1}/g" \
       | sed "s/{ITIME1}/${itime1}/g" \
       | sed "s/{TIMMAX}/${timmax}/g" > RAMSIN_INI_IAU2_${ontem21h}

  iau=0
  ipos=2
  expnme=$expnme-IAU${iau}
  applyiau=${iau}
  cat < RAMSIN_TEMPLATE_TMP \
       | sed "s/{RUNTYPE}/INITIAL/g" \
       | sed "s/{EXPNME}/${expnme}/g" \
       | sed "s/{APPLYIAU}/${applyiau}/g" \
       | sed "s/{IPOS}/${ipos}/g" \
       | sed "s/{IMONTH1}/${imonth1}/g" \
       | sed "s/{IDATE1}/${idate1}/g" \
       | sed "s/{IYEAR1}/${iyear1}/g" \
       | sed "s/{ITIME1}/${itime1}/g" \
       | sed "s/{TIMMAX}/${timmax}/g" > RAMSIN_INI_IAU0_${ontem21h}

  rm RAMSIN_TEMPLATE_TMP



  # ~~~~~~~~~~~~~~~ Criação de Jobs de Submissão ~~~~~~~~~~~~~~~
  echo
  echo "Criando arquivos de submissão ..."
  dirbase="\/lustre_xc50\/denis_eiras\/ioper_brams5.6"
  executable="${dirbase}\/EXEC\/brams-5.6"
  dirbase_no_sed="/lustre_xc50/denis_eiras/ioper_brams5.6"
  executable_no_sed="${dirbase_no_sed}/EXEC/brams-5.6"

  xsub_sfc_name="xsub_sfc_${ontem21h}.sh"
  echo "Criando Submit para o MAKESFC - "${xsub_sfc_name}" ..."
  pbs_queue="pesq"
  select=1
  ncpus=1
  mpiprocs=1
  wall="01:00:00"
  jobname="BRS_${ontem21h}"
  nproc=1
  ramsin="RAMSIN_SFC_${ontem21h}"

  cat < ./templates_meteo/XSUB_OPER_TEMPLATE \
       | sed "s/{PBS_QUEUE}/${pbs_queue}/g" \
       | sed "s/{SELECT}/${select}/g" \
       | sed "s/{MPIPROCS}/${mpiprocs}/g" \
       | sed "s/{NCPUS}/${ncpus}/g" \
       | sed "s/{WALL}/${wall}/g" \
       | sed "s/{JOBNAME}/${jobname}/g" \
       | sed "s/{DIRBASE}/${dirbase}/g" \
       | sed "s/{NPROC}/${nproc}/g" \
       | sed "s/{EXECUTABLE}/${executable}/g" \
       | sed "s/{RAMSIN}/${ramsin}/g" > ${xsub_sfc_name}
  chmod +x ${xsub_sfc_name}


  echo "Criando Submit para o MAKEVFILE da primeira hora (21h do dia anterior) a ${timmax_vfl} hora ..."
  wall="00:10:00"
  pbs_queue="pesq"
  tstart=${ontem21h}
  curr_hour=0
  while [ $curr_hour -lt $timmax_vfl ]; do
    x_ano=${tstart:0:4}
    x_mes=${tstart:4:2}
    x_dia=${tstart:6:2}
    x_hora=${tstart:8:2}

    jobname="BRV_${tstart}"
    ramsin="RAMSIN_VFL_${tstart}"
    xsub_vfl_name="xsub_vfl_${tstart}.sh"
    cat < ./templates_meteo/XSUB_OPER_TEMPLATE \
       | sed "s/{PBS_QUEUE}/${pbs_queue}/g" \
       | sed "s/{SELECT}/${select}/g" \
       | sed "s/{MPIPROCS}/${mpiprocs}/g" \
       | sed "s/{NCPUS}/${ncpus}/g" \
       | sed "s/{WALL}/${wall}/g" \
       | sed "s/{JOBNAME}/${jobname}/g" \
       | sed "s/{DIRBASE}/${dirbase}/g" \
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

  echo "Criando Submit para o INITIAL de 21H ontem - ${xsub_ini_iau1_name}..."
  pbs_queue="pesq"
  select=26
  ncpus=40
  mpiprocs=40
  nproc=1040
  wall="01:30:00"
  jobname="BRI1_${ontem21h}"
  ramsin="RAMSIN_INI_IAU1_${ontem21h}"

  cat < ./templates_meteo/XSUB_OPER_TEMPLATE \
     | sed "s/{PBS_QUEUE}/${pbs_queue}/g" \
     | sed "s/{SELECT}/${select}/g" \
     | sed "s/{MPIPROCS}/${mpiprocs}/g" \
     | sed "s/{NCPUS}/${ncpus}/g" \
     | sed "s/{WALL}/${wall}/g" \
     | sed "s/{JOBNAME}/${jobname}/g" \
     | sed "s/{DIRBASE}/${dirbase}/g" \
     | sed "s/{NPROC}/${nproc}/g" \
     | sed "s/{EXECUTABLE}/${executable}/g" \
     | sed "s/{RAMSIN}/${ramsin}/g" > ${xsub_ini_iau1_name}
    chmod +x ${xsub_ini_iau1_name}

  wall="04:00:00"

  echo "Criando Submit para o INITIAL_IAU2 - ${xsub_ini_iau2_name} ..."
  jobname="BRI2_${ontem21h}"
  ramsin="RAMSIN_INI_IAU2_${ontem21h}"
  cat < ./templates_meteo/XSUB_OPER_TEMPLATE \
       | sed "s/{PBS_QUEUE}/${pbs_queue}/g" \
       | sed "s/{SELECT}/${select}/g" \
       | sed "s/{MPIPROCS}/${mpiprocs}/g" \
       | sed "s/{NCPUS}/${ncpus}/g" \
       | sed "s/{WALL}/${wall}/g" \
       | sed "s/{JOBNAME}/${jobname}/g" \
       | sed "s/{DIRBASE}/${dirbase}/g" \
       | sed "s/{NPROC}/${nproc}/g" \
       | sed "s/{EXECUTABLE}/${executable}/g" \
       | sed "s/{RAMSIN}/${ramsin}/g" > ${xsub_ini_iau2_name}
  chmod +x ${xsub_ini_iau2_name}

  echo "Criando Submit para o INITIAL_IAU0 - ${xsub_ini_iau0_name} ..."
  jobname="BRI0_${ontem21h}"
  ramsin="RAMSIN_INI_IAU0_${ontem21h}"
  cat < ./templates_meteo/XSUB_OPER_TEMPLATE \
       | sed "s/{PBS_QUEUE}/${pbs_queue}/g" \
       | sed "s/{SELECT}/${select}/g" \
       | sed "s/{MPIPROCS}/${mpiprocs}/g" \
       | sed "s/{NCPUS}/${ncpus}/g" \
       | sed "s/{WALL}/${wall}/g" \
       | sed "s/{JOBNAME}/${jobname}/g" \
       | sed "s/{DIRBASE}/${dirbase}/g" \
       | sed "s/{NPROC}/${nproc}/g" \
       | sed "s/{EXECUTABLE}/${executable}/g" \
       | sed "s/{RAMSIN}/${ramsin}/g" > ${xsub_ini_iau0_name}
  chmod +x ${xsub_ini_iau0_name}



  # ~~~~~~~~~~~~~~~ Criação de namelists para o Prep ~~~~~~~~~~~~~~~
  #
  # >>> ATENÇÃO <<<
  #
  # hack provisório para conseguir executar o pré somente para 2 horários à partir das 18h:
  #
  # Tentativa anterior:
  # - se tentar iniciar a partir das 18 gera dados das 0h do dia anterior até o final do período.
  #
  # Hack provisório:
  # - criar um link para os arquivos das 18 e 21 como sendo 00 e 03; executar por 3 horas (1 step) à partir das 00h;
  # - excluir o arquivo gerado das 00h;
  # - renomear o arquivo gerado das 03h para 21h antes de executar o VFL.

  cams="$dirbase\/datafix\/CAMS\/"

  echo
  echo "Criando namelist para o Prep de ontem 21h - pre_${ontem21h}.nml ..."

  time_file_gfs_ini_hack="00"
  time_file_gfs_fim_hack="03"
  pre_step="3"
  my_atmos_idir_prefix="\/lustre_xc50\/denis_eiras\/ioper_brams5.6\/my_external"
  atmos_idir="/lustre_xc50/ioper/data/external/${ontem}${time_file_gfs_ini_orig}/dataout/GFS_0p25/"

  # Para obter os arquivos do GFS do horário das 18 ...
  # wget "https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.${ontem}/${time_file_gfs_ini_orig}/gfs.t${time_file_gfs_ini_orig}z.pgrb2.0p25.f000 -o ${my_atmos_idir}
  # wget "https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.${ontem}/${time_file_gfs_ini_orig}/gfs.t${time_file_gfs_ini_orig}z.pgrb2.0p25.f003 -o ${my_atmos_idir}

  # link para manter o padrão utilizado com nome .grib2
  ln -sf "${atmos_idir}/gfs.t${time_file_gfs_ini_orig}z.pgrb2.0p25.f000.${ontem}${time_file_gfs_ini_orig}.grib2" "${my_atmos_idir}/gfs.t${time_file_gfs_ini_orig}z.pgrb2.0p25.f000.${ontem}${time_file_gfs_ini_orig}.grib2"
  ln -sf "${atmos_idir}/gfs.t${time_file_gfs_ini_orig}z.pgrb2.0p25.f003.${ontem}${time_file_gfs_ini_orig}.grib2" "${my_atmos_idir}/gfs.t${time_file_gfs_ini_orig}z.pgrb2.0p25.f003.${ontem}${time_file_gfs_ini_orig}.grib2"

  prep_out_dir="${dirbase}\/${ontem}${itime1}\/datain\/GRADS\/"
  cat < ./templates_meteo/PRE_TEMPLATE \
       | sed "s/{TIME_FILE_GFS}/${time_file_gfs_ini_orig}/g" \
       | sed "s/{ATMOS_IDIR_PREFIX}/${my_atmos_idir_prefix}/g" \
       | sed "s/{PRE_STEP}/${pre_step}/g" \
       | sed "s/{IMONTH1}/${imonth1}/g" \
       | sed "s/{IDATE1}/${idate1}/g" \
       | sed "s/{IYEAR1}/${iyear1}/g" \
       | sed "s/{ITIME1}/${time_file_gfs_ini_hack}/g" \
       | sed "s/{IMONTH2}/${imonth1}/g" \
       | sed "s/{IDATE2}/${idate1}/g" \
       | sed "s/{IYEAR2}/${iyear1}/g" \
       | sed "s/{ITIME2}/${time_file_gfs_fim_hack}/g" \
       | sed "s/{DATE}/${ontem}/g" \
       | sed "s/{PREP_OUT_DIR}/${prep_out_dir}/g" \
       | sed "s/{CAMS}/${cams}/g" \
       | sed "s/{DIRBASE}/${dirbase}/g" \
       > pre_${ontem21h}.nml

  echo "Criando namelist para o Prep à partir das 00h do dia atual - pre_${hoje}.nml até ${yyyymmdd2_pre}"
  cams="$dirbase\/datafix\/CAMS\/"

  atmos_idir_prefix="\/lustre_xc50\/ioper\/data\/external"
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
       | sed "s/{DIRBASE}/${dirbase}/g" \
       > pre_${hoje}.nml

  echo
  echo "Entrando no diretório "${dir_local}
  cd ${dir_local}
  echo "Criando diretório temporário e variável de ambiente TMPDIR ..."
  export TMPDIR="/lustre_xc50/denis_eiras/ioper_brams5.6/tmp"
  mkdir -p ${TMPDIR}

  echo
  echo "Extraindo os dados de umidade do GFS ..."
  file_for_smoist="${my_atmos_idir}/gfs.t${time_file_gfs_ini_orig}z.pgrb2.0p25.f003.${ontem}${time_file_gfs_ini_orig}.grib2"
  wgrib2 ${file_for_smoist} -s | grep 'TSOIL\|SOILW' | wgrib2 -i ${file_for_smoist} -netcdf tmp_out.nc
  smoist_file="/lustre_xc50/denis_eiras/ioper_brams5.6/my_external/"${ontem}${time_file_gfs_ini_orig}"/dataout/umid_solo/GFS.SOIL:UMID_TEMP.${ontem21h}"
  grads -lc "run ./gerabin.gs tmp_out.nc ${smoist_file}"
  rm tmp_out.nc

  echo
  echo "Gerando os dados de SST ..."
  ./geraSST2RAMS.bash "${hoje}00"

fi  # fim fase PREPARAR_AMBIENTE



# ~~~~~~~~~~~~~~~ Submissão de Jobs ~~~~~~~~~~~~~~~

if [ ${_fase} == "SFC" ]; then
  echo
  echo "Submeterndo job xsub_sfc_${ontem21h}.sh"
  qsub xsub_sfc_${ontem21h}.sh
fi


if [ ${_fase} == "VFL" ]; then
  rm -f *.ctl *.inv *.blow *.gra  # caso parar o PRE no meio do processo
  echo
  echo "Executando prep na data de ontem 21h = ${ontem}2100"
  # module swap PrgEnv-cray/6.0.4 PrgEnv-gnu  - defaul agora é gnu 

  echo "
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
module load PrgEnv-gnu
set -x

cd ${dir_local}
aprun -n 1 -N 1 ./EXEC/prep_1.0 > prep.log
set +x  "  > ./xsub_prep.sh

  ln -sf pre_${ontem21h}.nml pre.nml
  sleep 10 && tail -f prep.log &
  qsub -Wblock=true ./xsub_prep.sh
  mv prep.log prep_${ontem21h}.log

  new_ctl="./${ontem21h}/datain/GRADS/IC${iyear1}${imonth1}${idate1}21"
  # continuação do hack do pré
  rm "./${ontem21h}/datain/GRADS/IC${iyear1}${imonth1}${idate1}00.ctl"
  rm "./${ontem21h}/datain/GRADS/IC${iyear1}${imonth1}${idate1}00.gra"
  mv "./${ontem21h}/datain/GRADS/IC${iyear1}${imonth1}${idate1}03.ctl" ${new_ctl}".ctl"
  mv "./${ontem21h}/datain/GRADS/IC${iyear1}${imonth1}${idate1}03.gra" "./${ontem21h}/datain/GRADS/IC${iyear1}${imonth1}${idate1}21.gra"

  cat < ${new_ctl}".ctl" \
     | sed "s/IC${ontem}03/IC${ontem21h}/g" \
     | sed "s/linear\ 03/linear\ 21/g" \
     > ${new_ctl}".ct2"

  mv ${new_ctl}".ct2" ${new_ctl}".ctl"

  echo "Executando prep na data de iau2 = ${hoje}"
  ln -sf pre_${hoje}.nml pre.nml
  sleep 10 && tail -f prep.log 
  qsub -Wblock=true ./xsub_prep.sh
  mv prep.log prep_${hoje}.log

  echo
  echo "Iniiciando submissão dos jobs makevfile ..."
  tstart=${ontem21h}
  curr_hour=0
  while [ $curr_hour -lt $timmax_vfl ]; do
    x_ano=${tstart:0:4}
    x_mes=${tstart:4:2}
    x_dia=${tstart:6:2}
    x_hora=${tstart:8:2}
    echo "Submetendo job xsub_vfl_$tstart.sh"
  	qsub xsub_vfl_$tstart.sh

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


if [ ${_fase} == "INITIAL_IAU1" ]; then
  echo "Submeterndo job ${xsub_ini_iau1_name}"
  qsub ${xsub_ini_iau1_name}
fi


if [ ${_fase} == "INITIAL_IAU2" ]; then
  echo "Submeterndo job ${xsub_ini_iau2_name}"
  qsub ${xsub_ini_iau2_name}
fi


if [ ${_fase} == "INITIAL_IAU0" ]; then
  echo "Submeterndo job ${xsub_ini_iau0_name}"
  qsub ${xsub_ini_iau0_name}
fi



# fim do script















