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
cat > /tools/megazord-composition/src/coredns/config/Corefile << CORE_BLOCK

.:53 {
	forward . 8.8.8.8
}
"${domain}" {
	forward . 172.19.0.5:53
}
CORE_BLOCK

echo "Generating .htaccess with cs2modrewrite.py"

# shellcheck disable=SC2154
python3 /tools/cs2modrewrite/cs2modrewrite.py \
	-i "/opt/cobaltstrike/${domain}-$(date '+%Y-%m-%d')".profile \
	-c https://"${domain}" -r "$redirect_location" \
	-o /tools/megazord-composition/src/apache2/.htaccess

echo "file created at /tools/Megazord-Composition/src/apache2/.htaccess"

echo "Generating pseudo-random string for payload endpoint"

endpoint="/$(openssl rand -hex 6)/somethingelse"
new_line="Alias ${endpoint} '/var/www/uploads'"

uploads=$(grep 'Alias' \
	< /tools/megazord-composition/src/apache2/apache2.conf)

sed -i "s|${uploads}|${new_line}|" \
	/tools/megazord-composition/src/apache2/apache2.conf

echo -e "\033[1;31m************************************************************"
echo ""
echo -e "\033[1;31m${endpoint}"
echo ""
echo -e "\033[1;31m************************************************************"

echo "payload endpoint updated to ${endpoint}"

echo "Starting the megazord composition service"

systemctl daemon-reload
systemctl enable megazord-composition.service
systemctl start megazord-composition.service

echo "megazord-composition.service has been started"
