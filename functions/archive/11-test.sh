#! /bin/bash

declare -A VAR

while read -r a b
do
	VAR[${a//:}]=$b
done < <( sed -E '/^#|^;|^\s*$/d' $1)


for i in "${!VAR[@]}"
do
	echo "--: $i :-----: ${VAR[$i]} :--"
done

