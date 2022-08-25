grep -zPo "(?<=^$1)\s*:[\s\S]+?(?=\s+@?cp -f)" $2 | grep -P -w "[\w.-]+\.o" -o
