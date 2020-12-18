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
    if [[ -v CN_HOST  &&  ! -z ${CN_HOST} ]] ; then 
        CERT=${CN_HOST//./_}
        CERT_PATH=$COMPLETE
        echo "CERT set to $CERT"
        UNZIP_DIR=""
        # There's an unknown _NUMBER prefex on the files issued by DigiCert
        # Here we're looping through the possibilities of which there should be only one
        TEST_PATH=$CERT_PATH/${CERT}_*
        echo "Checking for cert directory $TEST_PATH"
        for f in $TEST_PATH
        do
            echo "Found $f"
            if [[ -d $f ]] ; then
               
                CERT_PATH=$f
                
                TEST_PATH=$CERT_PATH/${CERT}_*
                echo "Checking for cert directory $TEST_PATH"
                for f2 in $TEST_PATH
                do
                 
                # Check one more level, because when I unzipped the file that was the structure
                if [[ -d $f2 ]] ; then
                   2echo "Found $f2"
                    CERT_PATH=$f2
                fi
                done
            fi
        done
        echo "CERT_PATH set to $CERT_PATH"
        TESTFILE=$CERT_PATH/$CERT.pem
        
        if [[ -f $TESTFILE ]] ; then
            CERT_TYPE="pem"
            CERT="$CERT.$CERT_TYPE"
        fi
        if [[ -f $CERT_PATH/$CERT.p7b ]] ; then
            CERT_TYPE="p7b"
            CERT="$CERT.$CERT_TYPE"
        fi
        if [[ -f $CERT_PATH/$CERT.p12 ]] ; then
            CERT_TYPE="p12"
            CERT="$CERT.$CERT_TYPE"
        fi
        if [[ -f $CERT_PATH/$CERT.cer ]] ; then
            CERT_TYPE="cer"
            CERT="$CERT.$CERT_TYPE"
        fi
        echo "CERT set to $CERT"
    else
        echo "CN_HOST not set in config.sh"
        exit -1
    fi
}


function import_ca_certs()
{

    #openssl x509 -in $CERT_PATH/$CERT -noout -issuer
    CA_INTERMEDIATE=`openssl x509 -in $CERT_PATH/$CERT -noout -issuer`
    echo "$CA_INTERMEDIATE"
    CA_INTERMEDIATE=${CA_INTERMEDIATE:7}
    echo "Issuer for $CERT  is : $CA_INTERMEDIATE"
    CA_INTERMEDIATE_FILE=`findIssuer "$CA_INTERMEDIATE"`
    echo "CA_INTERMEDIATE is $CA_INTERMEDIATE_FILE"
    # delete first
    echo "deleting existing intermediate first"
    echo "Running: keytool -delete -alias 'intermediate' -keystore $KEYSTORE -storepass KS_PASSWD"
    keytool -delete -alias "intermediate" -keystore $KEYSTORE -storepass $KS_PASSWD
     echo "delete op returned $?"
    # import CA_INTERMEDIATE_FILE
    # check that it's not already imported
    echo "Importing $CA_INTERMEDIATE_FILE into $KEYSTORE"
    # keytool -import -trustcacerts -alias "intermediate" -file $CA_INTERMEDIATE_FILE -keystore $KEYSTORE -storepass $KS_PASSWD 
    echo "Running: keytool -import -trustcacerts -alias 'intermediate' -file $CA_INTERMEDIATE_FILE -keystore $KEYSTORE -storepass KS_PASSWD"
    keytool -import -trustcacerts -alias "intermediate" -file $CA_INTERMEDIATE_FILE -keystore $KEYSTORE -storepass $KS_PASSWD
    # Find CA Root
    # may wnat to check global keystore for root because script will prompt during root import if so
    echo "Finding Root..."
    CA_ROOT=`openssl x509 -in $CA_INTERMEDIATE_FILE -noout -issuer`
    echo "$CA_ROOT"
    CA_ROOT=${CA_ROOT:7}
    echo "CA_ROOT is $CA_ROOT"
    CA_ROOT_FILE=`findIssuer "$CA_ROOT"`
    echo "CA_ROOT_FILE is $CA_ROOT_FILE"
    # delete first
    echo "deleting existing root first"
    echo "Running: keytool -delete -alias "root" -keystore $KEYSTORE -storepass KS_PASSWD"
    keytool -delete -alias "root" -keystore $KEYSTORE -storepass $KS_PASSWD
    echo "delete op returned $?"
    #import CA_ROOT_FILE
   
    #check that it's not already imported
    echo "Importing $CA_ROOT_FILE into $KEYSTORE"
     #keytool -import -trustcacerts -alias "root" -file $CA_ROOT_FILE -keystore $KEYSTORE -storepass $KS_PASSWD 
    echo "Running: keytool -import -trustcacerts -alias 'root' -file $CA_ROOT_FILE -keystore $KEYSTORE -storepass KS_PASSWD"
    keytool -import -trustcacerts -alias "root" -file $CA_ROOT_FILE -keystore $KEYSTORE -storepass $KS_PASSWD
   
}
function findIssuer()
{
    #echo "Looking for CA with subject: $1"
    local CA_FILE=""
    for ca in $INFILES/*.cer
    do
        #echo "Found $ca"
        CA_SUBJECT=`openssl x509 -in $ca -noout -subject`
        CA_SUBJECT=${CA_SUBJECT:8}
        #echo "Subject is : $CA_SUBJECT"
        if [[ "$CA_SUBJECT" == "$1" ]] ; then
           local CA_FILE=$ca
           #echo "CA_FILE is $CA_FILE"
        fi
    done
    for ca in $INFILES/*.pem
    do
        #echo "Found $ca"
        CA_SUBJECT=`openssl x509 -in $ca -noout -subject`
        CA_SUBJECT=${CA_SUBJECT:8}
        #echo "Subject is : $CA_SUBJECT"
        if [[ "$CA_SUBJECT" == "$1" ]] ; then
           local CA_FILE=$ca
           #echo "CA_FILE is $CA_FILE"
        fi
    done
    if [[ -f $CA_FILE ]] ; then
        echo "$CA_FILE"
        if [[ -z $CA_FILE ]] ; then
        exit 1
        fi
    else
    exit 1
    fi

}

function export_jks_2_p12()
{

    keytool -importkeystore -srckeystore $KEYSTORE -destkeystore $KEY_PATH/node-${CLUSTER_NAME}.p12 -deststoretype pkcs12 -srcstorepass $KS_PASSWD -deststorepass $KS_PASSWD
 
}

function import_issued_cert()
{

    echo "Importing an issued certificate to the $KEYSTORE"
    echo "Running: keytool -import -alias $KEY_ALIAS_NAME -file $CERT_PATH/$CERT -keystore $KEYSTORE -storepass XXXXXXX"
    # To import the issued certificate:
    keytool -import -alias $KEY_ALIAS_NAME -file $CERT_PATH/$CERT -keystore $KEYSTORE -storepass $KS_PASSWD
     
}

function generate_renewal_csr()
{
    echo "Renewing a certificate..."
}