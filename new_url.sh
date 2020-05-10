#!/bin/bash


function random_uri {
	length=$1
	echo "/$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c $length ; echo '')"
}

function new_link {
	dest=$1
	redirects_file=$2
	length=$3
	while : ; do
		uri=$(random_uri $length)
		search=$(awk '{print $1;}' $redirects_file | cut -d "/" -f 2 | grep "^$uri$")
		[[ "$search" == "" ]] && break
	done
	echo $uri
}

function url_in_file {
	url=$1
	redirects_file=$2
	echo $(awk '{print $2;}' $redirects_file | grep "^$url$")
}

function usage {
	cat << EOF
Usage $0 URL [args]

Arguments:
  -h show this help
  -o override existing short url
  -a append new short url
  -l <length> (default=2)
  -f <redirects file> (default=_redirects)
EOF
}

function exit_error {
	echo $1
	usage
	exit 1
}


POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
	-l|--length)
		length="$2"
		shift # past argument
		shift # past value
		;;
	-f|--file)
		redirects_file="$2"
		shift # past argument
		shift # past value
		;;
	-h|--help)
		exit_error
		;;
	-a|--append)
		append=YES
		shift # past argument
		;;
	-o|--override)
		override=YES
		shift # past argument
		;;
	*)    # unknown option
		POSITIONAL+=("$1") # save it in an array for later
		shift # past argument
		;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

echo ${POSITIONAL[0]}


if [ -z "$1" ]; then
	exit_error "Position argument URL is required"
else
	dest_url=$1
fi

if [ "$override" == "YES" ] && [ "$append" == "YES" ]; then
	exit_error "--override and --append cannot both be set."
fi

if [ -z "$redirects_file" ]; then
	redirects_file="_redirects"
fi

if [ -z "$length" ]; then
	length=2
fi

if [ -n "$(url_in_file $dest_url $redirects_file)" ]; then
	if [ "$override" == "YES" ]; then
		grep -v "$dest_url" $redirects_file > tmp
		mv tmp $redirects_file
		short_uri=$(new_link $dest_url $redirects_file $length)
		echo -e "$short_uri\t\t$dest_url" >> $redirects_file
	elif [ "$append" == "YES" ]; then
		old_short_uri=$(grep "\s$dest_url$" $redirects_file | awk '{print $1;}' | paste -sd "," -)
		new_short_uri=$(new_link $dest_url $redirects_file $length)
		echo -e "$short_uri\t\t$dest_url" >> $redirects_file
		short_uri="$old_short_uri,$new_short_uri"
	else
		short_uri=$(grep "\s$dest_url$" $redirects_file | awk '{print $1;}' | paste -sd "," -)
	fi
else
	short_uri=$(new_link $dest_url $redirects_file $length)
	echo -e "$short_uri\t\t$dest_url" >> $redirects_file
fi

echo "$short_uri"

