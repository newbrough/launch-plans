#!/bin/bash
# ignore errors when sourceing bootenv.sh
set +e
. bootenv.sh
set -e

ERROR=1
USAGE="usage: $0 start|stop|status config.yml"


if [ -z "$1" ]; then
    echo "You must specify whether to start or stop"
    echo $USAGE
    exit $ERROR
fi
ACTION="$1"

if [ -z "$2" ]; then
    echo "You must provide a config"
    echo $USAGE
    exit $ERROR
fi
CONFIG="`pwd`/$2"

VENV="${virtualenv}"
EXCHANGE="${rabbitmq_exchange}"

ACTIVATE="${VENV}/bin/activate"

if [ ! -f "$ACTIVATE" ]; then
    echo "'${ACTIVATE}' can't be accessed. Is your virtualenv set correctly?"
    exit $ERROR
fi

source $ACTIVATE

if [ ! `which epu-harness` ]; then
    echo "'epu-harness' isn't in search path. Is your virtualenv set correctly?"
    echo "Your virtualenv is at '${VENV}', and your PATH is : $PATH"
    exit $ERROR
fi

ACTION=`echo $ACTION | tr '[A-Z]' '[a-z]'`

if [ "${ACTION}" = "start" ]; then
    EXTRA=bootconf.json
else
    EXTRA=""
fi

echo "${ACTION}ing epu-harness"
echo epu-harness -x $EXCHANGE -c $CONFIG $ACTION $EXTRA 
epu-harness -x $EXCHANGE -c $CONFIG $ACTION $EXTRA 
if [ $? -ne 0 ]; then
  exit 1
fi

exit
