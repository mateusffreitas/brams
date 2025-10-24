#!/bin/bash

INTEL_COMPILER_VERSION=${INTEL_COMPILER_VERSION:-"latest"}
PREREQ_DL_DIR=${PREREQ_DL_DIR:-"${PWD}/prereq-download-dir/"}
PREREQ_DIR=${PREREQ_DIR:-"${HOME}/opt-intel-llvm-impi-${INTEL_COMPILER_VERSION}"}
INSTALL_DIR=${INSTALL_DIR:-"${PWD}/intel-llvm-impi-${INTEL_COMPILER_VERSION}-prereq-install"}
NUM_MAKE_JOBS=${NUM_MAKE_JOBS:-24}

unset F90 F90FLAGS

export PATH=${PREREQ_DIR}/bin:$PATH
export LD_LIBRARY_PATH=${PREREQ_DIR}/lib:$LD_LIBRARY_PATH

mkdir -p ${PREREQ_DIR}
mkdir -p ${PREREQ_DIR}/bin
mkdir -p ${PREREQ_DIR}/lib
mkdir -p ${PREREQ_DIR}/include
mkdir -p ${INSTALL_DIR}
cd ${INSTALL_DIR}

export CC=icx
export CXX=icpx
export FC=ifx
export F77=ifx
export F90=ifx

which mpiifx &>/dev/null
if [[ $? -ne 0 ]]; then
  export MPIFC="mpiifort -fc=ifx"
  export MPIF77="mpiifort -fc=ifx"
  export MPIF90="mpiifort -fc=ifx"
  export MPICC="mpiicc -cc=icx"
  export MPICXX="mpiicpc -cc=icx"
else
  export MPIFC="mpiifx"
  export MPIF77="mpiifx"
  export MPIF90="mpiifx"
  export MPICC="mpiicx"
  export MPICXX="mpiicpx"
fi

if [[ ! -f .zlib.done ]]; then
  cp ${PREREQ_DL_DIR}/zlib-1.2.11.tar.gz .
  tar -xzvf zlib-1.2.11.tar.gz
  cd zlib-1.2.11/
  ./configure --prefix=${PREREQ_DIR}
  make clean && make -j ${NUM_MAKE_JOBS}
  make install
  [[ $? -eq 0 ]] || {
    echo "Error while installing zlib"
    exit 1
  }
  touch ../.zlib.done
  cd ..
fi

if [[ ! -f .szip.done ]]; then
  cp ${PREREQ_DL_DIR}/szip-2.1.1.tar.gz .
  tar -xzvf szip-2.1.1.tar.gz
  cd szip-2.1.1/
  ./configure --prefix=${PREREQ_DIR}
  make clean && make -j $NUM_MAKE_JOBS
  make install
  [[ $? -eq 0 ]] || {
    echo "Error while installing szip"
    exit 1
  }
  touch ../.szip.done
  cd ..
fi

if [[ ! -f .hdf5-impi.done ]]; then
  cp ${PREREQ_DL_DIR}/hdf5-1.14.5.tar.gz .
  tar -xzvf hdf5-1.14.5.tar.gz
  cd hdf5-1.14.5
  autoreconf -i -f
  ./configure --prefix=${PREREQ_DIR} CFLAGS=-I${PREREQ_DIR}/include CPPFLAGS=-I${PREREQ_DIR}/include LDFLAGS=-L${PREREQ_DIR}/lib CC="${MPICC}" FC="${MPIFC}" CXX="${MPICXX}" F90="${MPIF90}" F77="${MPIF77}" \
    --with-zlib=${PREREQ_DIR} --with-szlib=${PREREQ_DIR} --enable-parallel --enable-fortran
  automake -a -f
  make clean && make -j $NUM_MAKE_JOBS
  make install
  [[ $? -eq 0 ]] || {
    echo "Error while installing hdf5"
    exit 1
  }
  touch ../.hdf5-impi.done
  cd ..
fi

if [[ ! -f .netcdf-c-impi.done ]]; then
  cp ${PREREQ_DL_DIR}/netcdf-c-4.8.1.tar.gz .
  tar -xzvf netcdf-c-4.8.1.tar.gz
  cd netcdf-c-4.8.1/
  CPPFLAGS=-I${PREREQ_DIR}/include LDFLAGS=-L${PREREQ_DIR}/lib CFLAGS='-O3' \
    CC="${MPICC}" FC="${MPIFC}" CXX="${MPICXX}" F90="${MPIF90}" F77="${MPIF77}" \
    ./configure --prefix=${PREREQ_DIR} --enable-netcdf4 --enable-shared --disable-dap
  make clean && make -j $NUM_MAKE_JOBS
  make install
  [[ $? -eq 0 ]] || {
    echo "Error while installing netcdf-c"
    exit 1
  }
  touch ../.netcdf-c-impi.done
  cd ..
fi

if [[ ! -f .netcdf-fortran-impi.done ]]; then
  cp ${PREREQ_DL_DIR}/netcdf-fortran-4.5.3.tar.gz .
  tar -xzvf netcdf-fortran-4.5.3.tar.gz
  cd netcdf-fortran-4.5.3/
  CPPFLAGS=-I${PREREQ_DIR}/include LDFLAGS=-L${PREREQ_DIR}/lib CFLAGS='-O3' \
    CC="${MPICC}" FC="${MPIFC}" CXX="${MPICXX}" F90="${MPIF90}" F77="${MPIF77}" \
    ./configure --prefix=${PREREQ_DIR}
  make clean && make -j $NUM_MAKE_JOBS
  make install
  [[ $? -eq 0 ]] || {
    echo "Error while installing netcdf-fortran"
    exit 1
  }
  touch ../.netcdf-fortran-impi.done
  cd ..
fi

if [[ ! -f .wgrib2-ifx.done ]]; then
  cp ${PREREQ_DL_DIR}/wgrib2-3.7.0.tar.gz .
  tar -xzvf wgrib2-3.7.0.tar.gz
  cd wgrib2-3.7.0
  mkdir build && cd build
  cmake .. -DCMAKE_INSTALL_PREFIX=${PREREQ_DIR}/ -DMAKE_FTN_API=ON
  time make -j $NUM_MAKE_JOBS
  make install
fi
