#!/bin/bash

function start_dump_script_vars()
{    
    # These two lines are used to dump the scripts variables up to the next declare statement
    tmpfile=$(mktemp)
    declare -p >"$tmpfile"

}

function end_dump_script_vars()
{
    declare -p | diff "$tmpfile" -
    rm -f "$tmpfile"
}

function set_cert_name()
{
    echo "Setting certificate name returned from CA"
    # If the global exists -v and is not empty -z
    if [ -v CN_HOST ] && [ ! -z ${CN_HOST} ] ; then 
        CERT=${CN_HOST//./_}
        echo "CERT set to $CERT"
        TESTFILE=$INFILES/$CERT.pem
        
        if [ -f $TESTFILE ] ; then
            CERT_TYPE="pem"
            CERT="$CERT.$CERT_TYPE"
        fi
        if [ -f $INFILES/$CERT.p7b ] ; then
            CERT_TYPE="p7b"
            CERT="$CERT.$CERT_TYPE"
        fi
        if [ -f $INFILES/$CERT.p12 ] ; then
            CERT_TYPE="p12"
            CERT="$CERT.$CERT_TYPE"
        fi
        if [ -f $INFILES/$CERT.cer ] ; then
            CERT_TYPE="cer"
            CERT="$CERT.$CERT_TYPE"
        fi
        echo "CERT set to $CERT"
    else
        echo "CN_HOST not set in config.sh"
        exit -1
    fi
}