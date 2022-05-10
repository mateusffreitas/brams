function main (args)
input_file=subwrd(args,1)
output_file=subwrd(args,2)

* Este programa converte dados de umidade do solo e temperatura do solo "GFS" do 
* formato netcdf para o formato binario do GrADS e realiza um recorte no dominio de grade 
* Uso: grads -lc 'run gerabin.gs <input_file> <output_file>'
* Exemplo:
*  $ wgrib2 gfs.t18z.pgrb2.0p25.f003.2021030218.grib2 -s | grep 'TSOIL\|SOILW' | wgrib2 -i gfs.t18z.pgrb2.0p25.f003.2021030218.grib2 -netcdf tmp_out.nc
*  $ grads -lc 'run gerabin.gs tmp_out.nc GFS.SOIL:UMID_TEMP.2021030221'

* Rodrigo Braz - rodrigo.braz@icloud.com	-	fev/2021
* Denis Eiras - denis.eiras@inpe.br - mar/2021 - Alterações para gerar os dados globais, com a mesma grade definida na versão 5.6 do BRAMS

* dominio global definido

'reinit'
'sdfopen 'input_file

'q time'
horario=subwrd(result,3)

'set x 1 1440'

'set gxout fwrite'
'set fwrite -le 'output_file'.bin'

nvars = 8
var.4 = "soilw_0_0_1mbel"
var.3 = "soilw_0_1_0_4mb"
var.2 = "soilw_0_4_1mbel"
var.1 = "soilw_1_2mbelow"
var.8 = "tsoil_0_0_1mbel"
var.7 = "tsoil_0_1_0_4mb"
var.6 = "tsoil_0_4_1mbel"
var.5 = "tsoil_1_2mbelow"

vars = 1
while (vars <= nvars )
* say var.vars
  'display 'var.vars
  vars = vars + 1
endwhile

'disable fwrite'
* 'quit'

* Escrever o descritor .ctl
err=write (output_file'.ctl','dset 'output_file'.bin')
err=write (output_file'.ctl','undef -999000000.000000')
err=write (output_file'.ctl','title UMID_TEMP')
err=write (output_file'.ctl','xdef 1440 linear 0.0 0.25')
err=write (output_file'.ctl','ydef 721 linear -90 0.25')
err=write (output_file'.ctl','zdef 1 linear 1 1')
err=write (output_file'.ctl','tdef 1 linear 'horario' 1dy zdef 1 linear 1 1')

err=write (output_file'.ctl','vars 8')
err=write (output_file'.ctl','soilw1	0 99 Volumetric soil moisture content:Proportion (instant):regular_ll:depthBelowLandLayer:levels 0.0-0.1 m')
err=write (output_file'.ctl','soilw2	0 99 Volumetric soil moisture content:Proportion (instant):regular_ll:depthBelowLandLayer:levels 0.1-0.4 m')
err=write (output_file'.ctl','soilw3	0 99 Volumetric soil moisture content:Proportion (instant):regular_ll:depthBelowLandLayer:levels 0.4-1.0 m')
err=write (output_file'.ctl','soilw4	0 99 Volumetric soil moisture content:Proportion (instant):regular_ll:depthBelowLandLayer:levels 1.0-2.0 m')
err=write (output_file'.ctl','st1	0 99 Soil Temperature:K (instant):regular_ll:depthBelowLandLayer:levels 0.0-0.1 m:fcst time 0 hrs')
err=write (output_file'.ctl','st2	0 99 Soil Temperature:K (instant):regular_ll:depthBelowLandLayer:levels 0.1-0.4 m:fcst time 0 hrs')
err=write (output_file'.ctl','st3	0 99 Soil Temperature:K (instant):regular_ll:depthBelowLandLayer:levels 0.4-1.0 m:fcst time 0 hrs')
err=write (output_file'.ctl','st4	0 99 Soil Temperature:K (instant):regular_ll:depthBelowLandLayer:levels 1.0-2.0 m:fcst time 0 hrs')
err=write (output_file'.ctl','endvars')

say "Soil moisture output_file= "output_file
'quit'
