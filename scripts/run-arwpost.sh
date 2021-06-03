#!/usr/bin/env bash 

DIRECTORY=$(pwd)
echo $#
if [[ $# -eq 2 ]]; then
    echo "Backup of namelist.ARWpost..."
    cp $ARW_POST/namelist.ARWpost $HOME/namelist.ARWpost
    inputname=$(realpath $1)
    outname=$2
    echo "Configure namelist.ARWpost..."
    sed -i "s~^[[:space:]]*input_root_name.*~ input_root_name = "\'"${inputname}"\'"~" $ARW_POST/namelist.ARWpost
    sed -i "s~^[[:space:]]*output_root_name.*~ output_root_name = "\'"./${outname}"\'"~" $ARW_POST/namelist.ARWpost
fi

cd $ARW_POST

./ARWpost.exe

cp ${outname}* ${DIRECTORY}