#!/bin/bash

function check_cluster() {
# Verify the provided cluster name is valid
# Check that the cluster name has a matching config file
  configEnv="config-$clusterName.sh"
  if [ ! -f "$workingDir/$configEnv" ]
  then 
    echo "The cluster $clusterName does not have a matching config*.sh file"
    echo "Verify the cluster name is correct and that there is a matching config file."
    echo "exiting..."
    exit 0
  else
    echo "The cluster $clusterName is valid and has a matching config file.  Continuing..."
  fi

}

function quit() {
  echo "Exiting program."
  exit 0
}

function cr_concat_cer_file() {
# This function will create the concatenated.cer file
# which is a combination of the IntermediateCA*.cer and Root.cer files
  # Verify that the IntermediateCA*.cer file exists and there is only 1 file
  cd $symantecCertDir
  filecount=`ls -1q IntermediateCA*.cer.txt | wc -l `
  case $filecount in 
    0) echo "No IntermediateCA.cer.txt files exists, exiting..."
    exit 1;;
    1) echo "1 IntermediateCA.cer.txt files exists, continuing..."
       intermediateCerFile="$(ls IntermediateCA*.cer.txt)"
       dos2unix $intermediateCerFile;;
    *) echo "More than 1 IntermediateCA.cer.txt files exists, exiting..."
       exit 1;;
  esac

  # Verify that the RootCert.cer file exists
  if [ -e RootCert.cer ]
  then
    echo "RootCert.cer file exists, continuing..."
    rootCertFile=RootCert.cer
    dos2unix $rootCertFile
  else
    echo "No RootCert.cer file exits, exiting..."
    exit 1;
  fi

# Create concatenated file
tempfile=tempfile.txt
concatFile=concatenated-Verisign-IntermediateRootBundle.cer
if [ -e $concatFile ] ; then
  echo "Removing existing file:  $concatFile"
  rm $concatFile
fi

cp $intermediateCerFile $tempfile
echo -e "\r" >>$tempfile
cat $rootCertFile >> $tempfile
sed -e "s///" $tempfile >> $concatFile
rm $tempfile

if [ -e $workingDir/$concatFile ] ; then
  echo "removing existing file:  $workingDir/$concatFile"
fi

echo "copying file: $concatFile to $workingDir"
cp $concatFile $workingDir
cd $workingDir

}

# this function copies the cert.cer.txt file from Symantec to
# the working directory with the correct environment name.
cp_cert_cer_file() {

cd $workingDir

oldSymantecfile=`ls cassandra*-Symantec.cer `
certCerFile="cert.cer.txt"
if [ -e $oldSymantecfile ] ; then
  echo "Removing existing file: $workingDir/$oldSymantecfile"
  rm $oldSymantecfile 
fi

cd $symantecCertDir
if [ -e $certCerFile ] ; then
  echo "copying file: $certCerFile to $workingDir/$certDir/$envSymantecCerFile"
  cp $certCerFile $workingDir/$certDir/$envSymantecCerFile
else
  echo "The $certCerFile file does not exist...exiting"
  exit 1;
fi

cd $workingDir

}

# This function populates the config.sh file with the correct environment
update_config_file() {

cd $workingDir
echo ". ./$configEnv" > config.sh
echo "echo \"Config for cluster '\$CLUSTER_NAME' is sourced.\"" >> config.sh
chmod 755 config.sh
echo "config.sh file has been successfully updated."

}

# this function run the existing script:  createTruststoreAll.sh
# which creates the truststore-cassandra-symantec.jks file to be used cluster wide.
cr_truststore() {

cd $workingDir
./createTruststoreAll.sh

}

# This function runs the existing script: 3-createKeystoreForCluster.sh
# which creates the updated keystore file to be used cluster wide.
cr_keystore() {

cd $workingDir
./3-createKeystoreForCluster.sh

# Determine if this is a new cert or a renewal
# If this is a renewal cert then call the import_old_keystore function
# If this is a new cert there is no existing truststore to import
read -p "Is this a certificate renewal?: Y/N: " answer
case $answer in
  "Y" | "y" | "YES" | "yes") echo "Importing old truststore contents for renewal certificate..."
  import_old_keystore;;
  "N" | "n" | "NO" | "no") echo "This is not a renewal certificate so the old truststore contents will not be imported..."
  cp "truststore-cassandra-symantec.jks" $certDir;;
  *) echo "The input of: $answer is not a valid response, please enter: Y/N"
     echo "exiting..."
     exit 1;;
esac

}

# This function is used for renewing a certificate.
# The old truststore is imported into the new truststore
import_old_keystore() {
cd $workingDir

# Get name of old truststore file
read -p "Enter the filename of the currently active truststore for the env:  $certEnv:  " oldTrustFile

# If old truststore file exists, export the cer from the old truststore and import it into the new truststore
if [ -e $oldTrustFile ] ; then
  echo "Exporting cer from active truststore..."
  keytool -export -keystore $oldTrustFile -alias myKey -file oldTruststore.cer -storepass $password
  keytool -importcert -file oldTruststore.cer -keystore truststore-cassandra-symantec.jks -alias –oldCer -storepass $password
else
  echo "File:  $oldTrustFile does not exist.  Make sure this file exists in the directory: $workingDir"
  echo "exiting..."
  exit 1
fi

cp "truststore-cassandra-symantec.jks" $certDir
rm oldTruststore.cer

}

# This function creates a pem file which is generated from the truststore.jks file
cr_pem_file() {

cd $workingDir
# Get current(new) truststore
truststore="truststore-cassandra-symantec.jks"

# If truststore does not exist, exit script
# FIX THIS
#if [ -e $truststore ] ; then
#  echo "File:  $truststore does not exist.  Make sure this file is successfully created in the cr_keystore operation."
#  echo "exiting..."
#  exit 1
#fi

# Create the pem file
keytool -export -keystore truststore-cassandra-symantec.jks -alias mykey -file mycert.cer -storepass $password
openssl x509 -inform der -in mycert.cer -out truststore.pem

cp "truststore.pem" $certDir

# Delete truststore.pem file from $workingDir
rm "truststore.pem"
rm mycert.cer

}

# This function creates the password file
cr_password_file() {

passwordfile="$certDir/$certDir-passwords.txt"

# Check for existing password file
cd $workingDir
if [ -f $passwordfile ]; then
  echo "deleting existing file: $passwordfile"
  rm -f $passwordfile
fi

# create password file
echo "Creating password file: $passwordfile"
touch $passwordfile
echo "Challenge Phrase: $CH_PHRASE" >> $passwordfile
echo "Private Key password: $PK_PASSWD" >> $passwordfile
echo "Keystore password: $KS_PASSWD" >> $passwordfile
echo "Truststore password: $KS_PASSWD" >> $passwordfile

}

# This function creates the tar file of all files created in the workingDir directory
cr_tar_for_deploy() {

cd $workingDir
echo "Creating tar file of $certDir..."
tar cvf "$certDir".tar $certDir

}

# Set certificate environmnet
workingDir=$(pwd)
certDir=""
symantecCertDir=""
envSymantecCerFile=""
configEnv=""
clusterName=""
# Get the cluster name for the certificates to be created
read -p "Enter the cluster name you are creating certificates for: " clusterName
check_cluster
certDir="$clusterName"
symantecCertDir="SymantecCertFiles/$clusterName"
envSymantecCerFile="cassandra-$clusterName-Symantec.cer"

source $configEnv
# Set keystore password
password=$KS_PASSWD

# Set private key password
pkpassword=$PK_PASSWD

# Set challenge phrase
challengephrase=$CH_PHRASE

operation=""
while [ ! "$operation" == "quit" ]; do

  read -p "Enter a command [ run_all | cr_concat_cer_file | cp_cert_cer_file | update_config_file | cr_truststore | cr_keystore | cr_pem_file | cr_password_file | cr_tar_for_deploy | quit ]: " operation

  if [ "$operation" == "run_all" ]; then
    cr_concat_cer_file
    cp_cert_cer_file
    update_config_file
    cr_truststore
    cr_keystore
    cr_pem_file
    cr_password_file
    cr_tar_for_deploy
  elif [ "$operation" == "cr_concat_cer_file" ]; then
    cr_concat_cer_file
  elif [ "$operation" == "cp_cert_cer_file" ]; then
    cp_cert_cer_file
  elif [ "$operation" == "update_config_file" ]; then
    update_config_file
  elif [ "$operation" == "cr_truststore" ]; then
    cr_truststore
  elif [ "$operation" == "cr_keystore" ]; then
    cr_keystore
  elif [ "$operation" == "cr_pem_file" ]; then
    cr_pem_file
  elif [ "$operation" == "cr_password_file" ]; then
    cr_password_file
  elif [ "$operation" == "cr_tar_for_deploy" ]; then
    cr_tar_for_deploy
  elif [ "$operation" == "quit" ]; then
    quit
  else
   echo "Invalid command option, try again"
  fi
done
