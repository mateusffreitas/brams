#!/bin/bash
# Use in BRAMS-6.0 folder
INTEL_COMPILER_VERSION=${INTEL_COMPILER_VERSION:-"latest"}
PREREQ_DIR=${PREREQ_DIR:-"${HOME}/opt-intel-llvm-impi-${INTEL_COMPILER_VERSION}"}
BRAMS_DIR=${BRAMS_DIR:-"${PWD}/../"}
BRAMS_INSTALL_DIR=${BRAMS_INSTALL_DIR:-"${HOME}/brams-6.0-ifx-impi"}
PRE_BRAMS=${PRE_BRAMS:-1}
export PATH=${PREREQ_DIR}/bin:$PATH
export LD_LIBRARY_PATH=${PREREQ_DIR}/lib:$LD_LIBRARY_PATH

cd ${BRAMS_DIR}/build

./configure --program-prefix=BRAMS_6.0 --prefix=${BRAMS_INSTALL_DIR} --enable-jules \
  --with-chem=RELACS_TUV --with-aer=SIMPLE --with-fpcomp=mpiifx \
  --with-cpcomp=mpiicx --with-fcomp=ifx --with-ccomp=icx \
  --with-netcdff=${PREREQ_DIR} --with-netcdfc=${PREREQ_DIR} --with-wgrib2=${PREREQ_DIR}
make clean
make FPCOMP=mpiifx CPCOMP=mpiicx CCOMP=icx FCOMP=ifx -f Make_utils
make
make install
[[ $? -eq 0 ]] || {
  echo "Error while installing BRAMS"
  exit 1
}

if [[ $PRE_BRAMS -eq 1 ]]; then
  make pre-brams
  make install-pre-brams
  [[ $? -eq 0 ]] || {
    echo "Error while installing PRE-BRAMS"
    exit 1
  }
fi
