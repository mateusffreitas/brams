grep -vP "cp -f|mv -f|F_COMMAND|^#|rm -f" $1 | sed  "/^[[:space:]]*$/d"
