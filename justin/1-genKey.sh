. ./config.sh

mkdir -p $KEY_PATH

#obsolete
#
#gen key using openssl
#openssl genrsa -des3 -out $KEY_PATH/$KEY_FILENAME  2048
#gen the csr using openssl
#openssl req -new -key $KEY_PATH/$KEY_FILENAME -out $KEY_PATH/$KEY_FILENAME.csr

if [ -e $KEY_PATH/$PRIVATE_KEYSTORE ]
then
  echo "Not generating key...target keystore exists: $KEY_PATH/$PRIVATE_KEYSTORE" 
  exit -1
fi

if [ "x${DNAME}" == "x" ]
then
  echo "set DNAME env var in config sh"
  exit -1
fi

#gen key using java keytool
keytool -genkeypair -alias $CLUSTER_NAME -keyalg RSA -keysize 2048 -validity 365 -keystore $KEY_PATH/$PRIVATE_KEYSTORE -storepass $PK_PASSWD -keypass $PK_PASSWD -dname "$DNAME"

echo "Keystore ="
ls -la $KEY_PATH/$PRIVATE_KEYSTORE
