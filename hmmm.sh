#! /bin/bash

declare -A VAR

usage() {
    printf "Usage: ${0##*/} [-w | -b bits | -l bits] CFG_FILE\n\n"
    printf "Where:\n"
    printf "%6s %-8s %-s\n" \
        "-w" \
        "" \
        "Do a master pull of the registry and cache. This wipes all"
    printf "%6s %-8s %-s\n" \
        "" "" "the data from the registry and cache and re-downloads it."
    printf "%6s %-8s %-s\n" \
        "-b" \
        "bits" \
        "Pull specific bits."
    printf "%6s %-8s %-s\n" \
        "" "" "i.e. -b 4.5 -b 4.6\n" 
    printf "%6s %-8s %-s\n" \
        "-l" \
        "bits" \
        "Pulls 'latest-' bits. Can be specified multiple times."
    printf "%6s %-8s %-s\n" \
        "" "" "i.e. -l 4.5 -l 4.6\n" 
    printf "\n"
    printf "    The options are exclusive, meaning only one can be specified at a time.\n"
    printf "    The -l option can be used multiple times as long as no other option\n"
    printf "    is specified.\n"
    printf "    The -b option is meant to be used as a one-off option.\n"
    printf "    The bits to download should be placed in the releases file instead.\n"
    printf "\n"
    printf "The CFG_FILE has a format of:\n"
    printf "    # at the beginning of a line is a comment\n"
    printf "    ; at the beginning of a line is a comment\n"
    printf "    key1: value1\n"
    printf "    key2: value2\n"
    printf "\n"
    printf "The release file has a format of:\n"
    printf "    # at the beginning of a line is a comment\n"
    printf "    ; at the beginning of a line is a comment\n"
    printf "    The fields are space seperated.\n\n"
    printf "    %-35s %-10s %-10s %-15s %s\n" \
        "Version" \
        "Added" \
        "Expires" \
        "Requestor"\
        "Comment"
    printf "    %-35s %-10s %-10s %-15s %s\n" \
        "4.5.0-0.nightly-2020-06-03-105031" \
        "2020-05-22" \
        "2020-06-28" \
        "joherr" \
        "This is just an example"

    exit
}


while getopts ":wb:l:" options
do
    case "${options}" in
        w) # Wipe everything and pull it again.
            VAR[wipe]=true
            ;;
        b) # Pull specific bits.
            specific_bits=${OPTARG}
            ;;
        l) # Pull or link to latest bits.
            VAR[latest]+=" ${OPTARG}"
            ;;
    esac
done

shift $((OPTIND - 1))

ini=$1

[[ -z ${ini:+isset} ]] && usage



## Parse the ini file
#
[[ -f ${ini} ]] && {

    while read -r key value
    do
        VAR[${key//:}]="$(eval printf \"$value\")"
    done < <( sed -E '/^#|^;|^\s*$/d' ${ini})
}

for i in "${!VAR[@]}"
do
	printf ":--: $i :-----: ${VAR[$i]} :--\n"
done

exit


## Read the remaining functions from the functions directory
#
: ${fundir:=functions}

for fun in ${fundir}/*.funct
do
    source ${fun}
done



##
## Main
##

declare -a build_pull

pull_builds=( $( build_pull_list -g "4.3 4.4" -n "4.5 4.6" ${VAR[release_file]} ) )

## Pull bits
#

for build in "${pull_builds[@]}"
do
    echo ":--: ${build}"
#    cache_files \
#        -s \
#        -p ${VAR[pullsecret_file]} \
#        -o ${VAR[file_owner]} \
#        -g ${VAR[file_group]} \
#        -w ${VAR[cache_www_dir]} \
#        -m ${VAR[local_registry]} \
#        -r ${VAR[local_repo]} \
#        -c ${VAR[installer_extract_cmd]}
#        ${build}
done









