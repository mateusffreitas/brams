#!/bin/bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Script para executar todas as fasees do BRAMS meteorológico pré-operacional.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# O script executa as fases PREPARAR_AMBIENTE, MAKESFC, PRE do BRAMS, MAKEVFILE, INITIAL com IUA=1 e INITIAL com IAU=2, em um parametrizado
# intevalo de datas. Utiliza o script run_oper_meteo.bash como auxiliar.
#
# $ ./run_brams_interval yyyy mm dd dias_de_rodada is_ate_vfl
#
# Onde os paarâmetros são:
# - yyyy = ano inicial da rodada
# - mm = mês inicial da rodada
# - dd = dia inicial da rodada
# - dias_de_rodada = número de dias de rodadas à partir da data inicial
# - is_ate_vfl = se informado um valor qualquer, execucta somente até a fase VFL
#
# OBS: O tempo de previsão de cada dia está definido no parâmetro timmax do script run_oper_meteo.bash
#
# Ex, Para rodar os dias 01/mar/2021 até 10/mar/2021, execute:
# $ ./run_brams_interval 2021 03 01 10
# Essa chamada invocará o script run.brams 10 vezes, iniciando pelo dia 01/mar , avançando um dia até o décimo dia.



function exec_fase() {
  fase="$4"
  arquivo_teste="$5"
  tempo_max="$6"
  tempo=0
  tempo_inc=60

  # para sempre executar => rm ${arquivo_teste}
  if [ -f ${arquivo_teste} ]; then
    echo
    echo "Fase ${fase} já havia sido executada. Pulando a execução ..."
    echo
    return
  fi

  ./run_oper_meteo.bash "$1" "$2" "$3" ${fase}/mnt/beegfs/denis.eiras/ioper_brams6.0/my_external/2021010400/dataout/umid_solo/GFS.SOIL
      echo
      echo "***************************************************"
      echo "Tempo de execução excedido para a fase ${fase} !!! Parando execução"
      exit 1
    fi
  done

  echo
  echo "Fase ${fase} executada com sucesso !!!"
  echo

}

_ano=$1
_mes=$2
_dia=$3
_num_rodadas=$4

if [ -z $5 ]; then
  _is_ate_vfl=false
else
  _is_ate_vfl=true
fi

dias_de_previsao=7

yyyymmdd_ini=${_ano}${_mes}${_dia}

incr_dias=1
yyyymmdd_atual=${yyyymmdd_ini}
contador_rodada=0
_NOVA_DATA="-1"
_NOVA_DATA=`echo $_NOVA_DATA | tr "-" " "`

while [ ${contador_rodada} -lt ${_num_rodadas} ]; do

  x_ano=${yyyymmdd_atual:0:4}
  x_mes=${yyyymmdd_atual:4:2}
  x_dia=${yyyymmdd_atual:6:2}

  ontem=`date +%Y%m%d --date="$x_ano-$x_mes-$x_dia $_HORA $_NOVA_DATA day ago"`
  dia_ontem=`date +%d --date="${ontem}"`
  mes_ontem=`date +%m --date="${ontem}"`
  ano_ontem=`date +%Y --date="${ontem}"`
  ontem21h=${ontem}"21"

  yyyymmdd_previsao_final=`date +%Y%m%d%H --date="$x_ano-$x_mes-$x_dia 00 ${dias_de_previsao} day"`
  x_ano_fim=${yyyymmdd_previsao_final:0:4}
  x_mes_fim=${yyyymmdd_previsao_final:4:2}
  x_dia_fim=${yyyymmdd_previsao_final:6:2}

  echo
  echo "=========================================================================================================================="
  echo "Iniciando execução de todas as fases do dia ${yyyymmdd_atual} ..."
  echo "=========================================================================================================================="
  echo

  # somando um dia antes do final do loop, devido ao teste _is_ate_vfl
  yyyymmdd_atual=`date +%Y%m%d%H --date="$x_ano-$x_mes-$x_dia 00 ${incr_dias} day"`
  contador_rodada=$((${contador_rodada}+${incr_dias}))
  dir_dataout_base="/lustre_xc50/denis_eiras/ioper_brams5.6/${ontem21h}/dataout"

  fase="PREPARAR_AMBIENTE"
  ./run_oper_meteo.bash  ${x_ano} ${x_mes} ${x_dia} ${fase}

  fase="SFC"
  test_ok_file_name="${dir_dataout_base}/SFC/ndv_OQ3g-N-0000-12-16-120000-g1.vfm"
  exec_fase ${x_ano} ${x_mes} ${x_dia} ${fase} ${test_ok_file_name} 10800

  fase="VFL"
  test_ok_file_name="${dir_dataout_base}/IVAR/OPQUE-V-${x_ano_fim}-${x_mes_fim}-${x_dia_fim}-000000-g1.vfm"
  exec_fase ${x_ano} ${x_mes} ${x_dia} ${fase} ${test_ok_file_name} 10800

  if [ "${_is_ate_vfl}" = true ]; then
    continue
  fi

  fase="INITIAL_IAU0"
  test_ok_file_name="${dir_dataout_base}/POST/meteo-A-${x_ano_fim}-${x_mes_fim}-${x_dia_fim}-000000-g1.gra"
  exec_fase ${x_ano} ${x_mes} ${x_dia} ${fase} ${test_ok_file_name} 14400

done



# fim do script
