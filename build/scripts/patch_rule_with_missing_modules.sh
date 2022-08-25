#!/usr/bin/env bash

if [[ $# -lt 3 ]]; then
    echo "Usage: ./patch turb_k.o.err depend_model.mk ../src/"
    exit
fi

MODULES=$(./scripts/get_missing_modules_from_make_err.sh $1)
LAST_OBJ_FNAME=$(./scripts/get_make_objs_rules_names.sh $1 | tail -n 1)
BASENAME=$(basename $1)
LAST_OBJ=${LAST_OBJ_FNAME%.*}

echo $BASENAME LastObj=$LAST_OBJ_FNAME

if [[ $(printf "$MODULES" | wc -c) -eq 0 ]]; then
    echo "No modules to patch in."
    exit
else

    DEP_LIST=$(./scripts/get_depend_specific_rule_objs_list.sh ${LAST_OBJ}.o $2)
    MISSING_OBJS=$(for i in ${MODULES}; do printf " ${i%.*}.o"; done)

    echo "Dependency list= $DEP_LIST"
    echo "Missing deps = $MISSING_OBJS"

    for OBJ in $MISSING_OBJS; do
        WILL_PATCH=1
        REAL_MOD_OBJ_NAMES=($(scripts/get_filename_of_module.sh ${OBJ%.o} $3))

        if [[ ${#REAL_MOD_OBJ_NAMES[@]} -ge 1 ]]; then
            echo Real name candidates ${REAL_MOD_OBJ_NAMES[@]}
            echo Choosing first one ${REAL_MOD_OBJ_NAMES[0]}
            REAL_OBJ=${REAL_MOD_OBJ_NAMES[0]}.o

        else
            echo Could not find matching file candidate. Using $OBJ
            REAL_OBJ=$OBJ
        fi

        for DEP in $DEP_LIST; do

            if [[ $REAL_OBJ == $DEP ]]; then
                WILL_PATCH=0
                echo $REAL_OBJ module is in dependency list of "$LAST_OBJ_FNAME" already
                break
            fi
        done

        if [[ $WILL_PATCH -eq 1 ]]; then
            echo Patching in $REAL_OBJ module in "$LAST_OBJ_FNAME"
            perl -pi -e "s/(\b${LAST_OBJ}.[fF]90)/\1 ${REAL_OBJ}/" $2

        fi
    done

fi
