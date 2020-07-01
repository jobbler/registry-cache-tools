#! /bin/bash

declare -A VAR
declare -a build_pull

usage() {
    printf "Usage: ${0##*/} [-w | -b bits | -l bits] CFG_FILE\n\n"
    printf "Where:\n"
    printf "%6s %-8s %-s\n" \
        "-w" \
        "" \
        "Do a master pull of the registry and cache. This wipes all."
    printf "%6s %-8s %-s\n" \
        "-c" \
        "" \
        "Removes unreferenced RHCOS images."
    printf "%6s %-8s %-s\n" \
        "" "" "the data from the registry and cache and re-downloads it."
    printf "%6s %-8s %-s\n" \
        "-b" \
        "bits" \
        "Pull specific bits."
    printf "%6s %-8s %-s\n" \
        "" "" "i.e. -b 4.5 -b 4.6\n" 
    printf "%6s %-8s %-s\n" \
        "-r" \
        "bits" \
        "Pulls the most recent sets of bits for the specified versions."
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


while getopts ":wcb:l:r:v" options
do
    case "${options}" in
        w) # Wipe everything and pull it again.
            VAR[wipe]=true
            VAR[clean_rhcos]=true
            ;;
        c) # Removed unreferenced RHCOS images.
            VAR[clean_rhcos]=true
            ;;
        b) # Pull specific bits.
            VAR[specific]+=" ${OPTARG}"
            ;;
        l) # Pull or link to latest bits.
            VAR[latest]+=" ${OPTARG}"
            ;;
        r) # Pull the recent sets of bits
            VAR[recent]+=" ${OPTARG}"
            ;;
        v) # Print the set configuration variables.
            VAR[print_config]="true"
            ;;
        q) usage
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
        VAR[${key//:}]+=" $(eval printf \"$value\")"
    done < <( sed -E '/^#|^;|^\s*$/d' ${ini})
}

# Remove extra spaces from the values in VAR
for i in "${!VAR[@]}"
do
    VAR[${i}]="$( echo ${VAR[$i]} | xargs echo -n )"
done

## Print the variables to the screen and exit
#
[[ ${VAR[print_config],,} == true ]] && {
    printf "Configuration Variables (after evaluated)\n"
    printf "%0.s-" {1..30}
    printf "\n"

    for i in "${!VAR[@]}"
    do
        printf "%-30s: %s\n" "${i}" "${VAR[$i]}"
    done

    printf "\n"

    exit
}


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

## Pull a single one-off build
#
[[ -n ${VAR[specific]:+isset} ]] && {
    pull_builds=( ${VAR[specific]} )
}


## Wipe the repository and cache and pull them again based on the releases file.
#
# Dont wipe the rhcos images until after things are cached/mirrored.
# Instead check to see they are still used. If not, remove them.
#
[[ ${VAR[wipe],,} == true ]] && {
    # Wipe the files
    #
    wipe_registry ${VAR[registry_dir]}
    wipe_cache ${VAR[cache_www_dir]}

    # Parse the release file
    #
    while read -r bit
    do
        [[ $bit =~ latest- ]] && VAR[latest]+=" $bit"
        [[ $bit =~ recent- ]] && VAR[recent]+=" $bit"
        [[ ! ( $bit =~ latest- ) && ! ( $bit =~ recent- ) ]] && pull_builds+=( $bit ) 
    done < <( build_pull_list ${VAR[release_file]} )

    VAR[latest]="$( echo ${VAR[latest]} | xargs echo -n )"
    VAR[recent]="$( echo ${VAR[recent]} | xargs echo -n )"
}


## Pull the recent bits for builds
#
[[ -n ${VAR[recent]:+isset} ]] && {
    for bit in $( echo ${VAR[recent]} | tr ' ' '\n' | sort -u )
    do
        [[ $bit =~ nightly ]] \
        && {
            nbit+=" ${bit%%-nightly}"
        } || {
            gbit+=" ${bit}"
        }
    done

    nbit="$( echo ${nbit} | xargs echo -n )"
    gbit="$( echo ${gbit} | xargs echo -n )"

    pull_builds+=( $( build_pull_list -g "${gbit}" -n "${nbit}" ) )
}


## Pull bits
#

for bit in $( echo ${pull_builds[@]} | tr ' ' '\n' | sort -u )
do
    uniq_builds+=( $bit )
done

[[ -n ${uniq_builds:+isset} ]] && {
    for build in "${uniq_builds[@]}"
    do
        cache_files \
            -s \
            -p ${VAR[pullsecret_file]} \
            -o ${VAR[file_owner]} \
            -g ${VAR[file_group]} \
            -w ${VAR[cache_www_dir]} \
            -m ${VAR[local_registry]} \
            -r ${VAR[local_repo]} \
            -c ${VAR[installer_extract_cmd]} \
            ${build}
    done
}




## Pull or link latest builds
#
for bit in $( echo ${VAR[latest]} | sed 's/latest-//' | tr ' ' '\n' | sort -u )
do
    bit_status=$( link_latest_bits ${bit} )
    [[ -z ${bit_status:+isset} ]] && {
        cache_files \
            -s \
            -p ${VAR[pullsecret_file]} \
            -o ${VAR[file_owner]} \
            -g ${VAR[file_group]} \
            -w ${VAR[cache_www_dir]} \
            -m ${VAR[local_registry]} \
            -r ${VAR[local_repo]} \
            -c ${VAR[installer_extract_cmd]} \
            ${bit_status}

        link_latest_bits ${bit}
    }
done 


## Check for unused rhcos images
#
[[ ${VAR[clean_rhcos],,} == true ]] && {
    clean_rhcos ${VAR[cache_www_dir]}
}





