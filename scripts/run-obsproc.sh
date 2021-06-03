#!/usr/bin/env bash 
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

. "$DIR/print_msg"

if [[ -n $1 ]]; then
    file=$(realpath $1)
    sed -i "s~^[[:space:]]*obs_gts_filename.*$~ obs_gts_filename = \'${file}\'~" $OBSPROC_DIR/namelist.obsproc
fi

cd $OBSPROC_DIR

rm obs_gts_[0-9]*
print_msg "Corriendo obsproc..."
./obsproc.exe >& obsproc.out
cat obsproc.out

print_msg "Enlazando archivos..."
i=1
for file in obs_gts_[0-9]*
do
    ln -sf $(realpath $file) $WRFDA_DIR/ob`printf %02d $i`.ascii
    i=$((i+1))
done