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
        VAR[${key//:}]=$value
    done < <( sed -E '/^#|^;|^\s*$/d' ${ini})
}


## Read the remaining functions from the functions directory
#
: ${fundir:=functions}

for fun in ${fundir}/*.funct
do
    source ${fun}
done

# example "This is a test" 
# example wow yet another test


: ${DEBUG:=${VAR[debug]}}

[[ -n ${DEBUG:+isset} ]] && {
    for var in ${!VAR[@]}
    do
        printf "%-20s: %s\n" "${var}" "${VAR[$var]}"
    done
}

wipe_cache


#build_pull_list -g "4.3 4.4" -n "4.5 4.6" ${VAR[release_file]}

exit

#

declare -a build_pull

parse_release_file -g 4.4 -n 4.6 releases.txt

#build_pull+=( $( parse_release_file -g "4.3 4.4" -n "4.5 4.6" releases.txt ) )
#build_pull+=( $( parse_release_file -g "4.3 4.4" releases.txt ) )



## Get list of GA builds to pull
build_ga_max=4
ga_versions="4.3 4.4 4.5"

for gav in ${ga_versions}
do
    build_pull+=( $( list_builds -q ${build_ga_max} ${gav} ) )
done



build_nightly_max=4
build_nightly_max_check=20
nightly_versions="4.3 4.4 4.5 4.6"

for nv in ${nightly_versions}
do
    nbuilds=$( list_builds -n -q ${build_nightly_max_check} ${nv} )

    tcount=0
    for build in \
        4.5.0-0.nightly-2020-06-20-194346 \
        4.5.0-0.nightly-2020-06-04-025914 \
        4.5.0-0.nightly-2020-06-20-025721 \
        4.5.0-0.nightly-2020-06-16-045437 \
        4.5.0-0.nightly-2020-06-15-194331 \
        4.4.0-0.nightly-2020-06-22-065157 \
        4.4.0-0.nightly-2020-06-21-210301 \
        4.4.0-0.nightly-2020-06-20-163213 \
        $nbuilds
    do
        check_in_array "${build}" "${build_pull[@]}"
        in_array=$?

        [[ ${in_array} -eq 0 ]] && (( tcount++ ))

        [[ ${in_array} -ne 0 ]] && [[ $tcount -lt $build_nightly_max ]] && {
echo "build  $build"
                ttext=$( check_nightly_status ${build} )
                echo ${ttext} | grep --quiet --extended-regexp '(Failed|Unable to find release tag)'
                [[ $? -ne 0 ]] \
                    && {
                        build_pull+=( ${build} )
echo "adding $build"
                        (( tcount++ ))
                    }
            }
    done
done


for i in ${build_pull[@]}
do
    echo "--: $i :--"
done

check_in_array "4.5" "${build_pull[@]}"
echo $?

check_in_array "4.5.0-0.nightly-2020-06-20-025721" "${build_pull[@]}"
echo $?




exit
list_builds -n -q 4 4.5
check_nightly_status 4.5.0-0.nightly-2020-06-05-214616
#check_nightly_status 4.5.0-0.nightly-2020-06-05-202236
#check_nightly_status 4.5.0-0.nightly-2020-06-05-163714
#check_nightly_status 4.5.0-0.nightly-2020-06-05-155714
check_nightly_status 4.5.0-0.nightly-2020-06-11-035450


exit
#versions=$( list_builds -n 4.3 )
#echo ${versions}

list_builds -q 20 -n 4.5

check_nightly_status 4.5.0-0.nightly-2020-06-03-105031
exit



#check_nightly_status 4.5.0-0.nightly-2020-05-05-205255
#check_nightly_status -v 12345 4.5.0-0.nightly-2020-05-05-205255
#check_nightly_status -u https://test.org/::version::/::bits:: -v 12345 4.5.0-0.nightly-2020-05-05-205255
#check_nightly_status -u https://testurl 4.5.0-0.nightly-2020-05-05-205255

#status=$( check_nightly_status 4.5.0-0.nightly-2020-05-05-205255 )
#echo $status
#status=$( check_nightly_status 4.4.0-0.nightly-2020-05-01-231319 )
#echo $status



cache_files -s 4.3.8
exit
echo "-----"
cache_files -r 4.3.8
echo "-----"
cache_files -d /tmp 4.3.0-0.nightly-2020-03-04-235307
echo "-----"
cache_files -rd /tmp 4.3.0-0.nightly-2020-03-04-235307







