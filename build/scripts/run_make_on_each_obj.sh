#!/usr/bin/env bash
#Make libutils first and copy its objs and mods into a folder
# $1 ex: depend_model
# if

grep -Po "^[\w-.]+\.o(?=[\s]*:)" $1 | xargs -I{} basename {} | sed 's/\.err//g' | xargs -I{} bash -c "
rm -f *.o *.mod *.*90 ;
mkdir -p tmp-objs/{} ;
ls -1 tmp-objs/{} | xargs -I[] ln -sf tmp-objs/{}/[] [] ;
ls -1 libutils_files | xargs -I[] ln -sf libutils_files/[] [] ;
echo {} ;
make -r {} 2>&1  &> {}.err ;
mv -f *.o *.mod *.*90 tmp-objs/{}/ "

# Move results *.err into a folder, and use it as input for another round, after using patch all
#grep -i "error " -l 4model_err/* | xargs -I{} basename {} | sed 's/\.err//g' | xargs -I{} bash -c "rm -f *.o *.mod *.*90 ;ls -1 libutils_files | xargs -I{} ln -sf libutils_files/{} {} ; echo {} ; make -r  {} 2>&1  &> {}.err ; rm -f *.o *.mod *.*90"
