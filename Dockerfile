# Use Debian slim base image
FROM debian:bookworm-slim
 
# Install FRR and minimal tools, keep tcpdump
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gpg \
    procps \
    mtr \
    iputils-tracepath \
    iptables-persistent \
    iputils-ping \
    tcpdump \
    bridge-utils \
    iproute2 \
    lsb-release \
    tcpdump && \
    curl -s https://deb.frrouting.org/frr/keys.gpg | gpg --dearmor > /usr/share/keyrings/frrouting.gpg && \
    FRRVER="frr-stable" && \
    echo "deb [signed-by=/usr/share/keyrings/frrouting.gpg] https://deb.frrouting.org/frr $(lsb_release -s -c) $FRRVER" > /etc/apt/sources.list.d/frr.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends frr frr-pythontools && \
    apt-get purge -y --auto-remove && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
 
# Enable FRR daemons
RUN sed -i 's/^bgpd=no/bgpd=yes/; \
             s/^ospfd=no/ospfd=yes/; \
             s/^ldpd=no/ldpd=yes/; \
             s/^mgmtd=no/mgmtd=yes/; \
             s/^mplsd=no/mplsd=yes/; \
             s/^nhrpd=no/nhrpd=yes/' /etc/frr/daemons
 
# Enable MPLS sysctl settings
RUN mkdir -p /etc/sysctl.d && \
    echo "net.mpls.conf.*.input = 1" >> /etc/sysctl.d/90-mpls.conf && \
    echo "net.mpls.platform_labels = 100000" >> /etc/sysctl.d/90-mpls.conf
 
# Create empty FRR configs with proper permissions
RUN touch /etc/frr/frr.conf && \
    touch /etc/frr/vtysh.conf && \
    chown frr:frrvty /etc/frr/frr.conf /etc/frr/vtysh.conf && \
    chmod 640 /etc/frr/frr.conf /etc/frr/vtysh.conf

# Add entrypoint script
RUN echo '#!/bin/bash\n\
set -e\n\
if [ -f /etc/iptables/rules.v4 ]; then\n\
    iptables-restore < /etc/iptables/rules.v4\n\
    echo "[+] Restored iptables rules from /etc/iptables/rules.v4"\n\
fi\n\
service frr start\n\
exec "$@"' > /entrypoint.sh && chmod +x /entrypoint.sh 
 
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
