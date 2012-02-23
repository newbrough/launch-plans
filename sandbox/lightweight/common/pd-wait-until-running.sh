#!/bin/bash

ERROR=1
TIMEOUT=600
USAGE="usage: $0 [options]

Options:
[-v|--virtualenv path/to/virtualenv]
[-b|--host brokerhostname]
[-u|--username username]
[-p|--password password]
[-d|--processdispatcher pdname]
[-x|--exchange xchg]
[-i|--upid id]
"
# Parse command line arguments
while [ "$1" != "" ]; do
    case $1 in
        -v | --virtualenv )     shift
                                virtualenv=$1
                                ;;
        -b | --host )           shift
                                host=$1
                                ;;
        -u | --username )       shift
                                username=$1
                                ;;
        -p | --password )       shift
                                password=$1
                                ;;
        -d | --processdispatcher )       shift
                                processdispatcher=$1
                                ;;
        -x | --exchange )       shift
                                exchange=$1
                                ;;
        -i | --upid )           shift
                                upid=$1
                                ;;
        -h | --help )           echo "$USAGE"
                                exit
                                ;;
        * )                     echo "$USAGE"
                                exit 1
    esac
    shift
done

if [ -z "$virtualenv" ]; then
    echo "You must set a virtualenv"
    echo $USAGE
    exit $ERROR
fi

if [ -z "$processdispatcher" ]; then
    echo "Your process dispatcher must be set"
    echo $USAGE
    exit $ERROR
fi

if [ -z "$upid" ]; then
    #Try to get id from upid from bootout.json from readypgm
    upid=`cat bootout.json | awk '/upid/ {print $2}' | tr -d '",'`
    if [ -z "$upid" ]; then
        echo "You must provide a upid for the process"
        echo $USAGE
        exit $ERROR
    fi
fi

ACTIVATE="${virtualenv}/bin/activate"

if [ ! -f "$ACTIVATE" ]; then
    echo "'${ACTIVATE}' can't be accessed. Is your virtualenv set correctly?"
    exit $ERROR
fi

source $ACTIVATE

CEICTL="ceictl"
if [ ! `which $CEICTL` ]; then
    echo "'$CEICTL' isn't in search path. Is your virtualenv set correctly?"
    exit $ERROR
fi

while true ; do
    status=`$CEICTL --yaml -u $username -p $password -b $host -x $exchange process describe $upid | awk '/^state: / {print $2}'`
    echo "$status" >> statuslog.log
    if [ $? -ne 0 ]; then
        exit $ERROR
    elif [ "$status" = "500-RUNNING" ]; then
        break
    elif [ "$status" = "850-FAILED" ]; then
        echo "Service $upid is in a failed state."
        exit $ERROR
    elif [ $ATTEMPTS -le 0 ]; then
        echo "Service $upid took too long to reach a running state"
        exit $ERROR
    fi
    let TIMEOUT=$TIMEOUT-1
    sleep 1
done
exit