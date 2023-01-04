#! /bin/bash

#ga_url="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/"
#nightly_url="https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/"
#nightly_ci_url="https://openshift-release.svc.ci.openshift.org/releasestream/::version::/release/::bits::"

## Read the remaining functions from the functions directory
#
: ${fundir:=functions}

for fun in ${fundir}/*.funct
do
    source ${fun}
done

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







