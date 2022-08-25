grep -i "error #7002" -A1 $1 | grep -iPo "use[\s]+[\w.-]+(?=,)?" | perl -p -e "s/use\ //i" | sort -u

