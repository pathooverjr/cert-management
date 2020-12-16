. ./config.sh

mkdir -p $KEY_PATH

#gen csr using java keytool
keytool -certreq -alias $CLUSTER_NAME -file $KEY_PATH/$CLUSTER_NAME.csr -keystore $KEY_PATH/$PRIVATE_KEYSTORE -storepass $KS_PASSWD -dname $DNAME
