#Run after every patch
sed -i 's/aer1_list_MATRIX1/aer1_list/g ; s/aer1_list_SIMPLE/aer1_list/g' depend_model.mk
sed -i 's/\ teb_vars_const/ mem_teb_vars_const/g' depend_model.mk
sed -i 's/\ readbcst/ ReadBcst/g' depend_model.mk
sed -i 's/\ mem_grell_param\.o/ mem_grell_param2.o/g' depend_model.mk
sed -i 's/\ cuparm_grell3\.o/ cup_grell3.o/g' depend_model.mk
sed -i 's/\ Isorropia_Module\.o/ issoropia.o/g' depend_model.mk
sed -i 's/\ convpar_gf_geos5\.o/ ConvPar_GF_GEOS5.o/g' depend_model.mk
sed -i 's/\ monotonic_adv\.o/ radvc_mnt.o/g' depend_model.mk
sed -i 's/\ extras\.o/ extra.o/gi' depend_model.mk
sed -i 's/\ mod_chem_spack_ros\.o/ chem_spack_ros.o/g' depend_model.mk
sed -i 's/\ mod_chem_spack_rates\.o/ chem_spack_rates.o/g' depend_model.mk
sed -i 's/\ module_dry_dep\.o/ chem_dry_dep.o/g' depend_model.mk
sed -i 's/\ mod_chem_spack_kinetic\.o/ chem_spack_kinetic.o/g' depend_model.mk
sed -i 's/\ mod_chem_spack_dratedc\.o/ chem_spack_dratedc.o/g' depend_model.mk
sed -i 's/\ mod_chem_spack_jacdchemdc\.o/ chem_spack_jacdchemdc.o/g' depend_model.mk
sed -i 's/\ mod_chem_spack_fexchem\.o/ chem_spack_fexchem.o/g' depend_model.mk
sed -i 's/\ ModPostOneFieldNetcdf\.o/ ModPostOneFieldNetCDF.o/g' depend_model.mk

