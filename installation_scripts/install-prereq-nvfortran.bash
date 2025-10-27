#!/bin/bash

PREREQ_DIR=${PREREQ_DIR:-"${HOME}/opt-nvfortran"}
INSTALL_DIR=${INSTALL_DIR:-"${PWD}/nvfortran-prereq-install"}
PREREQ_DL_DIR=${PREREQ_DL_DIR:-"${PWD}/prereq-download-dir/"}
NUM_MAKE_JOBS=${NUM_MAKE_JOBS:-8}
MPICH_VERSION=${MPICH_VERSION:-4.2.1}

unset F90 F90FLAGS

export PATH=${PREREQ_DIR}/bin:$PATH
export LD_LIBRARY_PATH=${PREREQ_DIR}/lib:$LD_LIBRARY_PATH

mkdir -p ${PREREQ_DIR}
mkdir -p ${PREREQ_DIR}/bin
mkdir -p ${PREREQ_DIR}/lib
mkdir -p ${PREREQ_DIR}/include
mkdir -p ${INSTAL_DIR}
cd ${INSTAL_DIR}

export CC="nvc -tp host"
export CXX="nvc++ -tp host"
export FC="nvfortran -tp host"
export F77="nvfortran -tp host"
export F90="nvfortran -tp host"
#export CXX="nvc++ "
#export CC="nvc"
#export F90="nvfortran "
#export FC="nvfortran "
#export F77="nvfortran "

# NVHPC's zlib is used instead

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

if [[ ! -f .mpich-${MPICH_VERSION}.done ]]; then
  cp ${PREREQ_DL_DIR}/mpich-${MPICH_VERSION}.tar.gz .
  tar -xzvf mpich-${MPICH_VERSION}.tar.gz
  cd mpich-${MPICH_VERSION}/
  autoreconf -i -f
  ./configure CFLAGS="-O2 -fPIC " FFLAGS="-O2 -fPIC" CXXFLAGS="-O2 -fPIC" FCFLAGS="-O2 -fPIC " \
    --prefix=${PREREQ_DIR} --with-device=ch4 --enable-fortran \
    --enable-shared
  make clean && make -j $NUM_MAKE_JOBS
  make install
  [[ $? -eq 0 ]] || {
    echo "Error while installing mpich-${MPICH_VERSION}"
    exit 1
  }
  touch ../.mpich-${MPICH_VERSION}.done
  cd ..
fi

if [[ ! -f .hdf5-mpich-${MPICH_VERSION}.done ]]; then
  cp ${PREREQ_DL_DIR}/hdf5-1.14.5.tar.gz .
  tar -xzvf hdf5-1.14.5.tar.gz
  cd hdf5-1.14.5
  autoreconf -i -f
  CC=${PREREQ_DIR}/bin/mpicc FC=${PREREQ_DIR}/bin/mpif90 FFLAGS=-fPIC FCFLAGS=-fPIC CFLAGS=-fPIC \
    ./configure --prefix=${PREREQ_DIR} \
    --with-szlib=${PREREQ_DIR} --enable-parallel --enable-fortran=yes --enable-hl=yes
  make clean && make -j $NUM_MAKE_JOBS
  make install
  [[ $? -eq 0 ]] || {
    echo "Error while installing hdf5"
    exit 1
  }
  touch ../.hdf5-mpich-${MPICH_VERSION}.done
  cd ..
fi

if [[ ! -f .netcdf-c-mpich-${MPICH_VERSION}.done ]]; then
  cp ${PREREQ_DL_DIR}/netcdf-c-4.8.1.tar.gz .
  tar -xzvf netcdf-c-4.8.1.tar.gz
  cd netcdf-c-4.8.1/
  autoreconf -i -f
  CPPFLAGS=-I${PREREQ_DIR}/include LDFLAGS="-L${PREREQ_DIR}/lib " CFLAGS='-O3 -fPIC' FFLAGS=-fPIC FCFLAGS=-fPIC \
    CC=${PREREQ_DIR}/bin/mpicc FC=${PREREQ_DIR}/bin/mpif90 \
    CXX=${PREREQ_DIR}/bin/mpicxx F90=${PREREQ_DIR}/bin/mpif90 F77=${PREREQ_DIR}/bin/mpif90 \
    ./configure --prefix=${PREREQ_DIR} --enable-netcdf4 --enable-shared --disable-libxml2 --disable-dap --disable-curl
  make clean && make -j $NUM_MAKE_JOBS
  make install
  [[ $? -eq 0 ]] || {
    echo "Error while installing netcdf-c"
    exit 1
  }
  touch ../.netcdf-c-mpich-${MPICH_VERSION}.done
  cd ..
fi

if [[ ! -f .netcdf-fortran-mpich-${MPICH_VERSION}.done ]]; then
  cp ${PREREQ_DL_DIR}/netcdf-fortran-4.5.3.tar.gz .
  tar -xzvf netcdf-fortran-4.5.3.tar.gz
  cd netcdf-fortran-4.5.3/
  autoreconf -i -f
  CPPFLAGS=-I${PREREQ_DIR}/include LDFLAGS=-L${PREREQ_DIR}/lib CFLAGS='-O3' \
    CC=${PREREQ_DIR}/bin/mpicc FC=${PREREQ_DIR}/bin/mpif90 CXX=${PREREQ_DIR}/bin/mpicxx \
    F90=${PREREQ_DIR}/bin/mpif90 F77=${PREREQ_DIR}/bin/mpif90 \
    ./configure --prefix=${PREREQ_DIR}
  make clean && make -j $NUM_MAKE_JOBS
  make install
  [[ $? -eq 0 ]] || {
    echo "Error while installing netcdf-fortran"
    exit 1
  }
  touch ../.netcdf-fortran-mpich-${MPICH_VERSION}.done
  cd ..
fi

if [[ ! -f .wgrib2.done ]]; then
  cp ${PREREQ_DL_DIR}/wgrib2-3.7.0.tar.gz .
  tar -xzvf wgrib2-3.7.0.tar.gz
  cd wgrib2-3.7.0
  mkdir -p build && cd build
  cmake .. -DCMAKE_INSTALL_PREFIX=${PREREQ_DIR}/ \
    -DCMAKE_INSTALL_LIBDIR=${PREREQ_DIR}/lib -DMAKE_FTN_API=ON
  make -j $NUM_MAKE_JOBS
  make install
  [[ $? -eq 0 ]] || {
    echo "Error while installing wgrib2"
    exit 1
  }
  touch ../../.wgrib2.done
  cd ../../
fi
