#!/bin/bash
set -e
PREREQ_DL_DIR=${PREREQ_DL_DIR:-"${PWD}/prereq-download-dir/"}
MPICH_VERSION=${MPICH_VERSION:-3.3.1}

mkdir -p $PREREQ_DL_DIR

wget https://zlib.net/fossils/zlib-1.2.11.tar.gz -P $PREREQ_DL_DIR
[[ $? -ne 0 ]] && { echo "Error while downloading zlib" ; exit 1 ; }
wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4/szip-2.1.tar.gz -P $PREREQ_DL_DIR
[[ $? -ne 0 ]] && { echo "Error while downloading szip" ; exit 1 ;}
wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4/curl-7.26.0.tar.gz -P $PREREQ_DL_DIR
[[ $? -ne 0 ]] && { echo "Error while downloading curl" ; exit 1 ;}
wget https://github.com/Unidata/netcdf-c/archive/refs/tags/v4.8.1.tar.gz -O $PREREQ_DL_DIR/netcdf-c-4.8.1.tar.gz
[[ $? -ne 0 ]] && { echo "Error while downloading netcdf-c" ; exit 1 ;}
wget https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v4.5.3.tar.gz -O $PREREQ_DL_DIR/netcdf-fortran-4.5.3.tar.gz
[[ $? -ne 0 ]] && { echo "Error while downloading netcdf-fortran" ; exit 1 ;}
wget https://www.ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz -P $PREREQ_DL_DIR
[[ $? -ne 0 ]] && { echo "Error while downloading wgrib2" ; exit 1 ;}
wget https://github.com/HDFGroup/hdf5/archive/refs/tags/hdf5-1_12_1.tar.gz -P $PREREQ_DL_DIR
[[ $? -ne 0 ]] && { echo "Error while downloading hdf5" ; exit 1 ;}
wget https://www.mpich.org/static/downloads/${MPICH_VERSION}/mpich-${MPICH_VERSION}.tar.gz -P $PREREQ_DL_DIR
[[ $? -ne 0 ]] && { echo "Error while downloading mpich" ; exit 1 ;}

exit 0