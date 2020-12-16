#!/bin/bash
# This script uses a keystore already containing the correct CA chain
# Source config.sh
. ./config.sh

# Main branch statement 
#
# If the keystore doesn't exist OR we're starting over with CLOBBER_KEYSTORE set to Y in config.sh then
#  
# Create the new keystore by copying and renaming the DIGICERT_CA_CHAIN_BUNDLE to whatever we set $KEYSTORE
#  
# When we generate the CSR from the keystore derived from the CA bundle our private key is created
# and added to the copy placed in $COMPLETE and it already contains the CA chain, aka the intermediate and root CA certificates
# 



if [ ! -f $KEYSTORE ] || [ ${CLOBBER_KEYSTORE} == 'Y'] ; then 
  echo "Starting script to create new keystore and generate CSR."
 
  if [ ! -d $INFILES ]; then 
    # TODO 
    echo "Directory $INFILES does not exist."
    echo "Please create a directory called $INFILES and copy DigiCert-CAChains.p12"
    echo "and/or DigiCert-CAChains.jks there."
    echo "These files can be found at Keyword->DigiCert->Documents"
    echo "currently using DigiCert CA SHA2 to SHA2.zip"
    echo "Note: Secure Site OV and Secure Site EV have different intermediate CA certs"
    exit -1
  fi
  
  if [ ! -e $KEY_PATH ]; then
      echo "Creating the directory for the keystore at:"
      echo $KEY_PATH 
      mkdir -p $KEY_PATH
      if [ $? -ne 0 ] ; then
      echo "Fatal script error: Failed to create directory: $KEY_PATH"
        exit -1
      fi
  fi

  
  echo "Generating New keystore file from source with CA-Chains already present."
  echo "Checking that $DIGICERT_CA_CHAIN_BUNDLE exists..."
  if [ ! -f $DIGICERT_CA_CHAIN_BUNDLE ]; then 
    echo "Fatal Error: Expecting script variable DIGICERT_CA_CHAIN_BUNDLE defined in config.sh"
    echo "to exist at the following:   $DIGICERT_CA_CHAIN_BUNDLE"
    echo "Please update. " 
    echo $DIGICERT_CA_CHAIN_BUNDLE
    exit -1  
  fi
  echo "$DIGICERT_CA_CHAIN_BUNDLE exists..."
  # You will need to change the password to your required password. 
  # Change the file name from "DigiCert-CAChains" to your keystore name 
  # with the same extension (jks or p12)
  echo "Checking that $KEYSTORE exists which means CLOBBER_KEYSTORE was set..."
  # if the keystore already exists assume clobber was set so backup
  # existing keystore just in case 
  if [ -f $KEYSTORE ]  ; then 
    echo "$KEYSTORE exists..."
    ## Get current date ##
    _now=$(date +"%m_%d_%Y")
    _keystore_extension="${KEYSTORE##*.}"
    _keystore_backup="${KEYSTORE##*/}_$_now.$_keystore_extension"
    echo "Replacing existing keystore and generating new CSR"
    printf "%s to %s\n" $KEYSTORE $_keystore_backup
    cp $KEYSTORE $_keystore_backup
    rm $KEYSTORE
    # TODO backup and rm previous CSR if exists, because we are starting over
    # or just allow over write below
  else
    echo "$KEYSTORE does not exist, creating new keystore..."
  fi
    
  echo "Creating $KEYSTORE from a copy of $DIGICERT_CA_CHAIN_BUNDLE..."
  cp $DIGICERT_CA_CHAIN_BUNDLE $KEYSTORE

  # To change the jks keyStore password by using this command: 
  # keytool -storepasswd -new newpassword -keystore DigiCert-CAChains.jks -storepass changeme
  # To change the p12 keyStore password by using this command: 

  keytool -storepasswd -new $KS_PASSWD -keystore $KEYSTORE -storepass $DIGICERT_DEFAULT_KEYSTORE_CA_BUNDLE_PASSWORD

  # To create an alias using keytool:

  #keytool -genkey -alias $KEY_ALIAS_NAME -keyalg RSA -keysize 2048 -keystore $KEYSTORE -storepass $KS_PASSWD

  #keytool -genkey -alias $KEY_ALIAS_NAME -keyalg RSA -keysize 2048 -keystore $KEYSTORE -storepass $KS_PASSWD
  keytool -genkeypair -alias $KEY_ALIAS_NAME -keyalg RSA -keysize 2048 -validity 365 -keystore $KEYSTORE -storepass $KS_PASSWD -keypass $KS_PASSWD -dname "$DNAME"
  # generate private key pair
  #keytool -genkeypair -alias $KEY_ALIAS_NAME -keyalg RSA -keysize 2048 -validity 365 -keystore $KEYSTORE -storepass $KS_PASSWD -keypass $KS_PASSWD -dname "$DNAME"
  # To generate a certificate signing request (CSR) from keystore:

  keytool -certreq -alias $KEY_ALIAS_NAME -file $COMPLETE/${KEY_ALIAS_NAME}_CSR.txt -keystore $KEYSTORE -storepass $KS_PASSWD -dname "$DNAME"

else  # keystore file exists
  echo "Starting script to renew a certificate and generate renewal CSR OR"
  echo "Import an issued certificate from a previously generated CSR"
  exit 0
  # If the CSR already exists import the certificate from the CA
  if [ -e $COMPLETE/${KEY_ALIAS_NAME}_CSR.txt ] ; then
      # If we have a renewal keystore then import the certificate here
      echo "Importing an issued certificate to the $KEYSTOREmini weld torch
      "
      # To import the issued certificate:
      keytool -import -alias $KEY_ALIAS_NAME -file $CERT -keystore $KEYSTORE
  
      # TODO: Export a copy to p12 format 
  else
      echo "Renewing a certificate..."
      #generate renewal CSR    
  fi
fi  # end if keystore file exists




