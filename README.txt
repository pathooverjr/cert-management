This is the readme file included with the zip file containing the keystore that includes
the Intermediate and Root certificate

The included files are intended to help with the creation of a keystore that contains the DigiCert CA chains (intermediate and root files)
Both DigiCert CA files (DigiCert-CAChains.jks and DigiCert-CAChains.p12) have a default password of changeme.

You will need to change the password to your required password. Change the file name from "DigiCert-CAChains" to your keystore name with the same extension (jks or p12)

To change the jks keyStore password by using this command: keytool -storepasswd -new newpassword -keystore DigiCert-CAChains.jks -storepass changeme
To change the p12 keyStore password by using this command: keytool -storepasswd -new newpassword -keystore DigiCert-CAChains.p12 -storepass changeme

To create an alias using keytool:

keytool -genkey -alias server -keyalg RSA -keysize 2048 -keystore DigiCert-CAChains.jks

To generate a certificate signing request (CSR) from keystore:

keytool -certreq -alias server -file csr.txt -keystore DigiCert-CAChains.jks

To import the issued certificate:

keytool -import -alias server -file your_cert_name.p7b -keystore DigiCert-CAChains.jks

NOTE: Change server to your alias name 
NOTE: Change csr.txt to your csr name
NOTE: Change your_cert_name to your certificate name


Instructions for how to create an alias, CSR, and to install your certificate is available at DigiCert, https://www.digicert.com/ssl-certificate-installation.htm
For help with SSL certificates, please go to our site at https://myfedex.sharepoint.com/teams/dcoe/SitePages/Certificates---FAQs.aspx