# $1 Ex: monotonic_adv ; $2 Ex: ../src/
grep -i -P "^\s*module\s+${1}\b" $2 -R | cut -d':' -f1 | xargs -I{} basename {} | grep -Pi "\.f90$" | sort -u | sed -E 's/\.[fF]90$//g'
