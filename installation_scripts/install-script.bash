#!/bin/bash

gcc_env() {
    export PREREQ_DIR=${PREREQ_DIR:-"${HOME}/opt-gcc"}
    export INSTALL_DIR=${INSTALL_DIR:-"${HOME}/gcc-prereq-install"}
    export GCC_VERSION=$(gcc -dumpfullversion | awk -F. '{print $3+100*($2+100*$1)}')
    export BRAMS_INSTALL_DIR=${BRAMS_INSTALL_DIR:-"${HOME}/brams-6.0-gcc"}
}

intel_env() {
    export INTEL_COMPILER_VERSION=${INTEL_COMPILER_VERSION:-"latest"}
}

ifort_env() {
    intel_env
    export BRAMS_INSTALL_DIR=${BRAMS_INSTALL_DIR:-"${HOME}/brams-6.0-ifort"}
    export PREREQ_DIR=${PREREQ_DIR:-"${HOME}/opt-intel-${INTEL_COMPILER_VERSION}"}
    export INSTALL_DIR=${INSTALL_DIR:-"${HOME}/intel-${INTEL_COMPILER_VERSION}-prereq-install"}
}

ifort_impi_env() {
    intel_env
    export BRAMS_INSTALL_DIR=${BRAMS_INSTALL_DIR:-"${HOME}/brams-6.0-ifort-impi"}
    export PREREQ_DIR=${PREREQ_DIR:-"${HOME}/opt-intel-impi-${INTEL_COMPILER_VERSION}"}
    export INSTALL_DIR=${INSTALL_DIR:-"${HOME}/intel-impi-${INTEL_COMPILER_VERSION}-prereq-install"}
}

ifx_impi_env() {
    intel_env
    export BRAMS_INSTALL_DIR=${BRAMS_INSTALL_DIR:-"${HOME}/brams-6.0-ifx-impi"}
    export PREREQ_DIR=${PREREQ_DIR:-"${HOME}/opt-intel-llvm-impi-${INTEL_COMPILER_VERSION}"}
    export INSTALL_DIR=${INSTALL_DIR:-"${HOME}/intel-llvm-impi-${INTEL_COMPILER_VERSION}-prereq-install"}
}


export PREREQ_DL_DIR=${PREREQ_DL_DIR:-"${PWD}/prereq-download-dir/"}
export NUM_MAKE_JOBS=${NUM_MAKE_JOBS:-8}
export MPICH_VERSION=${MPICH_VERSION:-4.2.1}
export BRAMS_DIR=${BRAMS_DIR:-"${PWD}/../"}

case $1 in
  "ifort")
    echo Installing with ifort
    ifort_env

    . install-prereq-ifort.bash
  ;;
  "ifort-impi")
    echo Installing with ifort and intel mpi
    ifort_impi_env

    . install-prereq-ifort-impi.bash
  ;;
    "ifx-impi")
    echo Installing with ifx and intel mpi
    ifx_impi_env

    . install-prereq-ifx-impi.bash
  ;;
  "gcc")
    echo Installing with gcc
    gcc_env

    . install-prereq-gcc.bash
   ;;
  "download")
     echo Downloading prerequisites source files
    . download_prereq.bash
  ;;
  "brams-ifort")
     echo Installing BRAMS with ifort
     ifort_env

     . install-brams-ifort.bash
  ;;
  "brams-ifort-impi")
     echo Installing BRAMS with ifort and intel mpi
     ifort_impi_env

     . install-brams-ifort-impi.bash
  ;;
  "brams-ifx-impi")
     echo Installing BRAMS with ifx and intel mpi
     ifx_impi_env

     . install-brams-ifx-impi.bash
  ;;
  "brams-gcc")
     echo Installing BRAMS with gcc
     gcc_env

        . install-brams-gcc.bash
  ;;

esac
