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
	usage
	exit 1
}

while getopts "hoal:f:" flag; do
case "$flag" in
	h) usage; exit;;
	l) length=$OPTARG;;
	f) redirects_file=$OPTARG;;
esac
done

if [ -z "$1" ]; then
	echo "Position argument URL is required"
	exit_error
else
	dest_url=$1
fi

if [ -z "$redirects_file" ]; then
	redirects_file="_redirects"
fi

if [ -z "$length" ]; then
	length=2
fi

if [ -n "$(url_in_file $dest_url $redirects_file)" ]; then
	short_uri=$(grep "\s$dest_url$" $redirects_file | awk '{print $1;}')
else
	short_uri=$(new_link $dest_url $redirects_file $length)
	echo -e "$short_uri\t\t$dest_url" >> $redirects_file
fi

echo "$short_uri $dest_url"

