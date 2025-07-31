# Use Debian slim base image
FROM debian:bookworm-slim

# Install FRR and required tools
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl gpg procps traceroute mtr-tiny iptables-persistent \
    iputils-ping tcpdump bridge-utils iproute2 lsb-release \
    openssh-server snmpd telnetd \
    && curl -s https://deb.frrouting.org/frr/keys.gpg | gpg --dearmor > /usr/share/keyrings/frrouting.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/frrouting.gpg] https://deb.frrouting.org/frr $(lsb_release -s -c) frr-stable" > /etc/apt/sources.list.d/frr.list \
    && apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends frr frr-pythontools \
    && apt-get purge -y --auto-remove && apt-get clean && rm -rf /var/lib/apt/lists/*

# Enable FRR daemons
RUN sed -i 's/^bgpd=no/bgpd=yes/; \
             s/^ospfd=no/ospfd=yes/; \
             s/^ldpd=no/ldpd=yes/; \
             s/^mgmtd=no/mgmtd=yes/; \
             s/^mplsd=no/mplsd=yes/; \
             s/^nhrpd=no/nhrpd=yes/' /etc/frr/daemons

# Enable MPLS sysctl
RUN mkdir -p /etc/sysctl.d && \
    echo "net.mpls.conf.*.input = 1" >> /etc/sysctl.d/90-mpls.conf && \
    echo "net.mpls.platform_labels = 100000" >> /etc/sysctl.d/90-mpls.conf

# Create FRR config files
RUN touch /etc/frr/frr.conf /etc/frr/vtysh.conf && \
    chown frr:frrvty /etc/frr/frr.conf /etc/frr/vtysh.conf && \
    chmod 640 /etc/frr/frr.conf /etc/frr/vtysh.conf

# Prepare for SSH
RUN mkdir -p /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

# Copy secure runtime entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
