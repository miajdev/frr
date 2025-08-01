#!/bin/bash
set -e

# Create service accounts
for user in snmp ssh telnet noc; do
    if ! id "$user" &>/dev/null; then
        useradd -m -s /bin/bash "$user"
    fi
done

# Set passwords from environment variable at runtime
if [[ -n "${NOC_USER_PASSWORD}" ]]; then
    ENCRYPTED=$(openssl passwd -6 "${NOC_USER_PASSWORD}")
    for user in snmp ssh telnet noc; do
        usermod -p "$ENCRYPTED" "$user"
    done
    echo "[+] Passwords set for service users"
else
    echo "[!] WARNING: NOC_USER_PASSWORD not set, service users have no password"
fi

# Configure SNMP (public access read-only)
echo "rocommunity public" > /etc/snmp/snmpd.conf

# Start services
service ssh start
service snmpd start
service lldpd start
service frr start

exec "$@"
