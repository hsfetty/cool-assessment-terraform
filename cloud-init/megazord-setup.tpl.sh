#!/usr/bin/env bash

# megazord-setup.sh - Performs setup and configuration of megazord service:
#  - Update the coredns Corefile to include the correct domain name
#  - Run cs2modrewrite.py to generate an .htaccess file
#  - Enable/start the megazord-composition service
#
# NOTES:
#  - In .htaccess, remove 'P' for proxy because it interferes with the webserver

set -o nounset
set -o errexit
set -o pipefail

#Location for the DNS server to redirect unwanted traffic
redirect_location="https://google.com"

echo "Writing CoreDNS Corefile..."

# shellcheck disable=SC2154
cat > /tools/Megazord-Composition/src/coredns/config/Corefile << CORE_BLOCK

.:53 {
	forward . 8.8.8.8
}
"${domain}" {
	forward . 172.19.0.5:53
}
CORE_BLOCK

echo "Generating .htaccess with cs2modrewrite.py"

# shellcheck disable=SC2154
python3 /tools/cs2modrewrite/cs2modrewrite.py -i "/opt/cobaltstrike/${domain}-$(date '+%Y-%m-%d')".profile -c https://"${domain}" -r "$redirect_location" -o /tools/Megazord-Composition/src/apache2/.htaccess

echo "htaccess file created at /tools/Megazord-Composition/src/apache2/.htaccess"

echo "creating pseudo-random string for payload endpoint"

endpoint="Alias /$(openssl rand -hex 6)/somethingelse '/var/www/uploads'"

uploads=$(grep 'Alias' < /tools/Megazord-Composition/src/apache2/apache2.conf)

#uploads=$(cat /tools/Megazord-Composition/src/apache2/apache2.conf | grep 'Alias' | cut -d ' ' -f 2 | cut -b 2-8)

sed -i "s/$uploads/$endpoint/" /tools/Megazord-Composition/src/apache2/apache2.conf

echo "\033[1;31m************************************************************"
echo ""
echo "\033[1;31m$endpoint"
echo ""
echo "\033[1;31m************************************************************"

echo "payload endpoint updated to $endpoint"

echo "Extracting certificate and key from keystore"
# The certificate and key are expected to be in /opt/cobaltstrike because that directory gets mounted
# into the cobalt container when the megazord-composition.service is ran

# path to keystore file
keystore_path = "${c2_profile_location}/${domain}.store"

# extract certificate from keystore and output into /opt/cobaltstrike
keytool -export -alias ${domain} -keystore ${keystore_path} -rfc -file "/opt/cobaltstrike/cobalt.cert"

echo "certificate extracted to /opt/cobaltstrike/cobalt.cert"

# Extract private key from keystore and output into /opt/cobaltstrike
openssl pkcs12 -in ${keystore_path} -nodes -nocerts -out "/opt/cobaltstrike/cobalt.key"

echo "key extraced to /opt/cobaltstrike/cobalt.key"

echo "Starting the megazord composition service"

systemctl daemon-reload
systemctl enable megazord-composition.service
systemctl start megazord-composition.service

echo "megazord-composition.service has been started"
