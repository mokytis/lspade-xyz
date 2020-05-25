#!/bin/bash

function usage {
	cat << EOF
Usage: $0 [OPTIONS]... [FILE]...

Sign and date a text file.

With no FILE, or when FILE is -, read standard input.

When no FILE is speicifed and only an SSID is provided the system will search your saved Wi-Fi networks for encryption type and psk.
If no match is found it will be assumed that there is no encryption on the Wi-Fi network.

  -o --output   file to store output
  -d --date     custom date to append to file
  -h --help     show this help
  --html        add html wrapper
EOF
}

echo_error() {
	cat <<< "$@" 1>&2;
}

function exit_error {
	echo_error $1
	usage
	exit 1
}


# =Argument Parsing=
# based on SO answer https://stackoverflow.com/a/14203146

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
	-o|--output)
		OUTPUT_FILE="$2"
		shift # past argument
		shift # past value
		;;
	-d|--date)
		DATE="$2"
		shift # past argument
		shift # past value
		;;
	--html)
        HTML="YES";
        HTML_TITLE="$2"
        shift
        shift
		;;
	-h|--help)
		exit_error
		;;
	*)    # unknown option
		POSITIONAL+=("$1") # save it in an array for later
		shift # past argument
		;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

INPUT_FILE=${POSITIONAL[0]}

# =End Argument Parsing=

# Check that an input file is supplied
if [ "$INPUT_FILE"  == "-" ]; then
    INPUT_FILE = ""

fi

if [ -z $OUTPUT_FILE ]; then
    OUTPUT_FILE="${INPUT_FILE:-$(date '+%Y-%m-%d-%s%N')}.asc"
fi

TMP_FILE=$(mktemp)

# Create the tmp file from either stdin or the given file

while read line
do
  echo "$line" >> $TMP_FILE
done < "${INPUT_FILE:-/dev/stdin}"
echo -e "\n\nCorrect as of ${DATE:-$(date --utc)}" >> $TMP_FILE


OUTPUT_FILE=${OUTPUT_FILE:-$INPUT_FILE.asc}
gpg --clear-sign --output $OUTPUT_FILE $TMP_FILE

if [ "$HTML" == "YES" ]; then
    cat << EOF > $OUTPUT_FILE
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>$HTML_TITLE</title>
</head>
<body>
<pre>
$(cat $OUTPUT_FILE)
</pre>
</body>
</html>
EOF
fi

rm $TMP_FILE

