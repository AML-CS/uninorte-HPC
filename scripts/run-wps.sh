#!/bin/sh
#
# Script file which helps to run WRF 4.2 and WRFDA 4.0
# Tested in Centos 7, Uninorte HPC
# Author: vdguevara@uninorte.edu.co
#

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/print_msg"

function check_success() {
    if [[ $# -eq 1 ]];then
        grep "Successful completion" "${1}.log" > /dev/null
        if [[ $? -eq 0 ]]; then
            print_msg "Successful completion" -cgreen
        else
            print_msg "An error ocurred while running ${1}. Check the logs" -cred
            exit 1
        fi
    fi
}

function usage() {
    echo "Usage: $0 [options] [DATA_SOURCE]"
    echo "Runs WPS programs using the files in DATA_SOURCE as input"
    printf "\n  %-20s %s\n" "-s --skip-geogrid" "Skips geogrid"
    printf "  %-20s %s\n" "-f --from" "Start date"
    printf "  %-20s %s\n" "-t --to" "End date"
    printf "  %-20s %s\n\n" "-h --help" "Show this message and exit"

    exit 0
}

options=$(getopt -o shf:t: --long skip-geogrid --long from: --long to: --long help  -- "$@")

[ $? -eq 0 ] || {
    echo "Incorrect options provided"
    exit 1
}


DATA_DIR="$WRF_ROOT_DIR/data/WPS_REAL"
GEOGRID=true

eval set -- "$options"

while true; do
    case "$1" in
        -s|--skip-geogrid)
        GEOGRID=false
        ;;

        -h|--help)
        usage
        ;;

        -f|--from)
        shift
        FROM=$1
        ;;

        -t|--to)
        shift
        TO=$1
        ;;

        --)
        shift
        break
        ;;
    esac
    shift
done

if [[ -n $1 ]]; then
    DATA_DIR=$(realpath $1)
fi

cd $WPS_DIR

# Namelist modification
if [[ -n $FROM ]]; then
    FROM=$(date --date="${FROM}" +%Y-%m-%d_%H:%M:%S)
    sed -i "s/start_date.*/start_date = '$FROM', '$FROM', '$FROM',/" namelist.wps
    print_msg "Start date: ${FROM}" -cmagenta
fi

if [[ -n $TO ]]; then
    TO=$(date --date="${TO}" +%Y-%m-%d_%H:%M:%S)
    sed -i "s/end_date.*/end_date =   '$TO', '$TO', '$TO',/" namelist.wps
    print_msg "End date: ${TO}" -cmagenta
fi

rm met_em* 2> /dev/null
# Geogrid
if ${GEOGRID}; then
    print_msg "Running geogrid..."
    ./geogrid.exe >& geogrid.log
    check_success geogrid
fi

# Ungrib
print_msg "\nRunning ungrib"
print_msg "Using data in ${DATA_DIR}" -cmagenta
./link_grib.csh ${DATA_DIR}/*
ln -sf ungrib/Variable_Tables/Vtable.GFS Vtable
./ungrib.exe >& ungrib.log
check_success ungrib

# Metgrid
print_msg "\nRunning metgrid..."
./metgrid.exe >& metgrid.log
check_success metgrid
