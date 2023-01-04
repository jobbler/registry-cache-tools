#! /bin/bash



while getopts ":t:" options
do
    case "${options}" in
        t) echo "Option T - ${OPTARG}"
            ;;
    esac
done

echo "::: ${OPTIND}"
shift $((OPTIND -1))

argument=$1

echo "Argument: ${argument}"
