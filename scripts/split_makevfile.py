#!/usr/bin/env python3
import math
import sys
import os
from datetime import datetime, timedelta

try:
    import f90nml
except ImportError as e:
    print(
        "f90nml library is required. You can install it via 'pip install --user f90nml'")
    exit(-1)


def create_patched_ramsin(base_date, filename, index, timmax):
    date_patch = {
        'idate1': base_date.day,
        'imonth1': base_date.month,
        'iyear1': base_date.year,
        'timmax': timmax
    }

    patch_nml = {'model_grids': date_patch}
    f90nml.patch(filename, patch_nml, f'{os.path.basename(filename)}_{index}')
    return f"{os.path.basename(filename)}_{index}"


def main():
    if len(sys.argv) <= 1:
        print("Usage: ./split_makevfile.py {RAMSIN_BASIC_filename}")
        exit()

    filename = sys.argv[1]

    with open(filename) as f:
        ramsinb = f90nml.read(f)

    isan_inc = ramsinb.get("isan_control")["isan_inc"]
    model_grids = ramsinb.get("model_grids")

    timeunit = model_grids["timeunit"]
    timmax = model_grids["timmax"]
    imonth1 = model_grids["imonth1"]
    idate1 = model_grids["idate1"]
    iyear1 = model_grids["iyear1"]
    itime1 = model_grids["itime1"]

    min_hours = 24

    if itime1 != 0:
        print(f"This program only supports ITIME1=0 for now.")
        exit(0)

    if timeunit != 'h' or timmax < min_hours:
        print(f"This program only supports a minimum of 24 hours.")
        exit(0)

    patched_filename_list = []
    num_days, remaining_hours = int(timmax // min_hours), timmax % min_hours
    base_date = datetime.strptime(f"{iyear1}{imonth1:02d}{idate1:02d}", "%Y%m%d")

    for idx in range(num_days):
        patched_filename = create_patched_ramsin(base_date, filename, idx, min_hours)
        base_date += timedelta(hours=min_hours)
        patched_filename_list.append(patched_filename)

    if remaining_hours > 0:
        patched_filename = create_patched_ramsin(base_date, filename, num_days,
                                                 remaining_hours)
        patched_filename_list.append(patched_filename)

    with open(f"{os.path.basename(filename)}_patched_list", "w+") as f:
        for line in patched_filename_list:
            print(line, file=f)

    isan_inc /= 100
    expected_ivar_file_count = 2 * (int(math.ceil(timmax / isan_inc)) + 1)

    with open(f"{os.path.basename(filename)}_ivar_count", "w+") as f:
        print(expected_ivar_file_count, file=f)


if __name__ == '__main__':
    main()
