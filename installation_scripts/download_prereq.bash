#!/bin/bash
PREREQ_DL_DIR=${PREREQ_DL_DIR:-"${PWD}/prereq-download-dir/"}
MPICH_VERSION=${MPICH_VERSION:-4.2.1}
WGET_OPTS="--tries=5 --timeout=30 --wait=5 -c"

mkdir -p $PREREQ_DL_DIR

wget $WGET_OPTS https://zlib.net/fossils/zlib-1.2.11.tar.gz -P $PREREQ_DL_DIR
[[ $? -eq 0 ]] || { echo "Error while downloading zlib" ; exit 1 ; }
wget $WGET_OPTS https://support.hdfgroup.org/ftp/lib-external/szip/2.1.1/src/szip-2.1.1.tar.gz -P $PREREQ_DL_DIR
[[ $? -eq 0 ]] || { echo "Error while downloading szip" ; exit 1 ;}
wget $WGET_OPTS https://www.mpich.org/static/downloads/${MPICH_VERSION}/mpich-${MPICH_VERSION}.tar.gz -P $PREREQ_DL_DIR
[[ $? -eq 0 ]] || { echo "Error while downloading mpich" ; exit 1 ;}
wget $WGET_OPTS https://github.com/Unidata/netcdf-c/archive/refs/tags/v4.8.1.tar.gz -O $PREREQ_DL_DIR/netcdf-c-4.8.1.tar.gz
[[ $? -eq 0 ]] || { echo "Error while downloading netcdf-c" ; exit 1 ;}
wget $WGET_OPTS https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v4.5.3.tar.gz -O $PREREQ_DL_DIR/netcdf-fortran-4.5.3.tar.gz
[[ $? -eq 0 ]] || { echo "Error while downloading netcdf-fortran" ; exit 1 ;}
wget $WGET_OPTS  https://github.com/NOAA-EMC/wgrib2/archive/refs/tags/v3.7.0.tar.gz  -O $PREREQ_DL_DIR/wgrib2-3.7.0.tar.gz
[[ $? -eq 0 ]] || { echo "Error while downloading wgrib2" ; exit 1 ;}
wget $WGET_OPTS https://github.com/HDFGroup/hdf5/releases/download/hdf5_1.14.5/hdf5-1.14.5.tar.gz -P $PREREQ_DL_DIR
[[ $? -eq 0 ]] || { echo "Error while downloading hdf5" ; exit 1 ;}
