#!/bin/bash
set -e

# Create necessary runtime directories
mkdir -p /var/run/frr
chown -R frr:frr /var/run/frr
chmod 775 /var/run/frr

# Create service accounts
for user in snmp ssh telnet noc; do
    if ! id "$user" &>/dev/null; then
        useradd -m -s /bin/bash "$user"
    fi
done

# Add noc to required groups
usermod -aG frr,frrvty noc
usermod -s /bin/vtysh noc

# Set passwords
if [[ -n "${NOC_USER_PASSWORD}" ]]; then
    ENCRYPTED=$(openssl passwd -6 "${NOC_USER_PASSWORD}")
    for user in snmp ssh telnet noc; do
        usermod -p "$ENCRYPTED" "$user"
    done
    echo "[+] Passwords set for service users"
fi

# Configure SNMP
echo "rocommunity public" > /etc/snmp/snmpd.conf

# Start services
service ssh start
service snmpd start
service lldpd start
service frr start

# Keep container running
exec "$@"