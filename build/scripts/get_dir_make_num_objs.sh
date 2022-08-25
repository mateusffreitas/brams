
find $1 -type f | xargs -I{} bash -c "printf '{} ' ; ./scripts/get_make_obj_rule_name.sh {} | wc -l"
