# Scripts for Running BRAMS

1. Scripts to run brams 6 and scripts to generate output files for evaluation

These scripts simulates the full process of running BRAMS operationally. 
They follows the same processes used in BRAMS 5.6 evaluation in XC-50, but these are adapted for Egeon.


Usage: ./run_oper_meteo_interval.bash YYYY MM DD NUMBER_OF_DAYS_TO_RUN

---

Copy of comments in script:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Script para executar todas as fasees do BRAMS meteorológico pré-operacional.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 O script executa as fases PREPARAR_AMBIENTE, MAKESFC, PRE do BRAMS, MAKEVFILE, INITIAL com IUA=1 e INITIAL com IAU=2, em um parametrizado
 intevalo de datas. Utiliza o script run_oper_meteo.bash como auxiliar.

 $ ./run_brams_interval yyyy mm dd dias_de_rodada is_ate_vfl

 Onde os paarâmetros são:
 - yyyy = ano inicial da rodada
 - mm = mês inicial da rodada
 - dd = dia inicial da rodada
 - dias_de_rodada = número de dias de rodadas �|  partir da data inicial
 - is_ate_vfl = se informado um valor qualquer, execucta somente até a fase VFL

 OBS: O tempo de previsão de cada dia está definido no parâmetro timmax do script run_oper_meteo.bash

 Ex, Para rodar os dias 01/mar/2021 até 10/mar/2021, execute:
 $ ./run_brams_interval 2021 03 01 10
 Essa chamada invocará o script run.brams 10 vezes, iniciando pelo dia 01/mar , avançando um dia até o décimo dia.


