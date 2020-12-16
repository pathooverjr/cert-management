. ./config.sh

#VARS from config.sh
#  Using *** looking for spaces
echo "CLUSTER_NAME"
echo "***${CLUSTER_NAME}***"
echo "PK_PASSWD"
echo "***${PK_PASSWD}***"
echo "CH_PHRASE"
echo "***${CH_PHRASE}***"
echo "CN_HOST"
echo "***${CN_HOST}***"
echo "KEY_PATH"
echo "***${KEY_PATH}***"
echo "KS_PASSWD"
echo "***${KS_PASSWD}***"
echo "KEYSTORE"
echo "***${KEYSTORE}***"
echo "PRIVATE_KEYSTORE"
echo "***${PRIVATE_KEYSTORE}***"
echo "PRIVATE_KEYFILE"
echo "***${PRIVATE_KEYFILE}***"
echo "KEY_ALIAS_NAME"
echo "***${KEY_ALIAS_NAME}***"
echo "CERT"
echo "***${CERT}***"
echo "DIGIKEY_CA_INTERMEDIATE"
echo "***${DIGIKEY_CA_INTERMEDIATE}***"
echo "DIGIKEY_CA_ROOT"
echo "***${DIGIKEY_CA_ROOT}***"
echo "TRUSTSTORE"
echo "***${TRUSTSTORE}***"
echo "DNAME"
echo "***${DNAME}***"

echo "OPEN_SSL_GEN_PRIVATE_KEY"
echo "***${OPEN_SSL_GEN_PRIVATE_KEY}***"


if [ ! -f $DIGIKEY_CA_INTERMEDIATE ]; then 
  echo 'DIGIKEY_CA_INTERMEDIATE : " $DIGIKEY_CA_INTERMEDIATE " defined in config.sh does not exist.  Please update.'
  exit 0  
fi
  
if [ ! -f $DIGIKEY_CA_ROOT ]; then 
   echo 'DIGIKEY_CA_ROOT : " $DIGIKEY_CA_ROOT " defined in config.sh does not exist.  Please update.'

  exit 0  
fi

if [ "$OPEN_SSL_GEN_PRIVATE_KEY" == "NO" ] 
then
  #get private key off the jks and put in PEM file format
  #this normalizes the steps to generate the resulting jks no matter if
  #openssl or keytool used to generate the private key to begin withe
  #this normalizes the steps to generate the resulting jks no matter if
  #openssl or keytool used to generate the private key to begin with

  echo " "
  echo "We need to extract private key to normalize scripts to the same basis"
  echo "(a pem key file) just as if private key was generated using openssl."

  if [ -f $KEY_PATH/_$PRIVATE_KEYFILE.p12 ]; then rm $KEY_PATH/_$PRIVATE_KEYFILE.p12; fi
  
  echo "Generating : $KEY_PATH/_$PRIVATE_KEYFILE.p12"
  exit

  keytool -importkeystore -srckeystore $KEY_PATH/$PRIVATE_KEYSTORE -destkeystore $KEY_PATH/_$PRIVATE_KEYFILE.p12 -srcstoretype jks -deststoretype pkcs12 -alias $CLUSTER_NAME -deststorepass $KS_PASSWD -srcstorepass "$PK_PASSWD"

  openssl pkcs12 -in $KEY_PATH/_$PRIVATE_KEYFILE.p12 -out $KEY_PATH/$PRIVATE_KEYFILE -passin pass:"$KS_PASSWD" -passout pass:"$KS_PASSWD"

  echo " "
  echo "Extracted private key from java keystore $KEY_PATH/$PRIVATE_KEYSTORE to a file named $KEY_PATH/$PRIVATE_KEYFILE."
fi

echo " "
echo "Assembling java keystore = $KEY_PATH/$KEYSTORE using these components:"
echo " - private key = $KEY_PATH/$PRIVATE_KEYFILE"
echo " - cert returned by DigiKey = $KEY_PATH/$CERT"
echo " - DigiKey certs = $DIGIKEY_CA_CHAIN"
echo " "

rm $KEY_PATH/$KEYSTORE

# step 1 - take the pkey, and the cert from symantec, and the intermediate/root
#          bundle and gen a pkcs bundle with all this...
echo "..openssl export"

openssl pkcs12 -export -out $KEY_PATH/_${CLUSTER_NAME}.pkcs -inkey $KEY_PATH/$PRIVATE_KEYFILE -in $KEY_PATH/$CERT -certfile $SYMANTEC_CERTS -name $CLUSTER_NAME -passin pass:"$PK_PASSWD" -passout pass:"$PK_PASSWD"

# step 2 - convert the pkcs bundle to a keystore 
echo "..keytool import"
keytool -importkeystore -srckeystore $KEY_PATH/_${CLUSTER_NAME}.pkcs -srcstoretype pkcs12 -destkeystore $KEY_PATH/$KEYSTORE -deststoretype jks -deststorepass $KS_PASSWD -destalias $CLUSTER_NAME -srcalias $CLUSTER_NAME -srcstorepass "$KS_PASSWD"

echo " "
echo "====================================================================== "
echo " "
echo "Details for cluster $CLUSTER_NAME"
echo " "
echo "For all nodes ="
echo " "
echo " - Keystore = $KEY_PATH/$KEYSTORE"
echo " - Keystore password = $KS_PASSWD"
echo " "
echo " - Truststore = $TRUSTSTORE"
echo " - Truststore password = $KS_PASSWD"
echo " "
echo "====================================================================== "
echo " "
echo "Let's check the keystore we just built."
echo "Should see 1 entry for PrivateKeyEntry..."
echo "...and also a keychain length of 3"
echo " "
#./printKeystore.sh $KEY_PATH/$KEYSTORE
keytool -list -keystore $KEY_PATH/$KEYSTORE -storepass $KS_PASSWD
keytool -list -keystore $KEY_PATH/$KEYSTORE -storepass $KS_PASSWD -v |grep length
echo
