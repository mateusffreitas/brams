#!/bin/bash
git log -1 > saida.git
echo "!Include para controle de versão" > ../src/utils/include/modGitInfo.inc 
echo " character(len=*), parameter :: lastCommit = '" $(head -1 saida.git) "'" >> ../src/utils/include/modGitInfo.inc
echo " character(len=*), parameter :: lastMerge = '" $(head -2 saida.git | tail -1) "'" >> ../src/utils/include/modGitInfo.inc
echo " character(len=*), parameter :: lastAuthor = '" $(head -3 saida.git | tail -1) "'" >> ../src/utils/include/modGitInfo.inc
echo " character(len=*), parameter :: lastGitDate = '" $(head -4 saida.git | tail -1 ) "'" >> ../src/utils/include/modGitInfo.inc
rm saida.git