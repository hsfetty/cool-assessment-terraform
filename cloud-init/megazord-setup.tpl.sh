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
python3 /tools/cs2modrewrite/cs2modrewrite.py -i "${c2_profile_location}/SourcePoint-$(date '+%Y-%m-%d')".profile -c https://"${domain}" -r "$redirect_location" -o /tools/Megazord-Composition/src/apache2/.htaccess

echo "htaccess file created at /tools/Megazord-Composition/src/apache2/.htaccess"

echo "Starting the megazord composition service"

systemctl daemon-reload
systemctl enable megazord-composition.service
systemctl start megazord-composition.service

echo "megazord-composition.service has been started"
