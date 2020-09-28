#! /bin/bash


ini=$1

usage() {
    printf "usage: ${0##*/} CFG_FILE\n"
    printf "where: CFG_FILE has a format of:\n"
    printf "    # at the beginning of a line is a comment\n"
    printf "    ; at the beginning of a line is a comment\n"
    printf "    key1: value1\n"
    printf "    key2: value2\n"
    exit
}


[[ -z ${ini:+isset} ]] && usage

## Parse the ini file
#
declare -A VAR
[[ -f ${ini} ]] && {

    while read -r key value
    do
        # Since the variables are read in using a script and not sourced
        # in, tilde and environment expansion fo not occur.
        # ${value/#\~/$HOME} will do the tilde expansion if its at
        # the beginning of the string.
        # envsubst will provide the environment substitution.
        VAR[${key//:}]=$( echo ${value/#\~/$HOME} | envsubst )

    done < <( sed -E '/^#|^;|^\s*$/d' ${ini})
}

LOGFILE=${VAR[logfile]}
DEBUG=${VAR[debug]}
VERBOSE=${VAR[verbose]}


## Read the remaining functions from the functions directory
#
: ${fundir:=functions}

for fun in ${fundir}/*.funct
do
    source ${fun}
done

[[ -n ${DEBUG:+isset} ]] && {
    for var in ${!VAR[@]}
    do
        printf "%-20s: %s\n" "${var}" "${VAR[$var]}"
    done
}


## Set common vars
[[ ${VAR[bits]} =~ nightly ]] \
    && bopt='-n' \
    || bopt='-g'

: ${VAR[max_bits_to_check]:=20}


## Main
#

topull=$( build_pull_list ${bopt} ${VAR[version]} -x 1 -c ${VAR[max_bits_to_check]} )
dir=${VAR[dir]} pullsecret=${VAR[pullsecret_file]} fetch_upi_files ${topull}

# Todo
# put rhcos images on https server
# put tftpboot images on tftp server
# configure dhcp
# condigure dns
# configure pxe






