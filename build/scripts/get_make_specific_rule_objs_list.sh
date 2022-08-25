grep -P  "==.+$1" "$2" | grep -P "(\b[\w.-]+\.o\b)" -o | head -n -1
#grep "grid_dims.o" model_err/ModVarfFile.o.err | grep "==" | grep -P "(\b\w+\.o\b)" -o


