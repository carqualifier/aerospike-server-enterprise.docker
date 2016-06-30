#
# Aerospike Server Enterprise Edition Dockerfile
#
# http://github.com/aerospike/aerospike-server-enterprise.docker
#


FROM ubuntu:14.04

# Add Aerospike package
ADD aerospike-server.deb /tmp/aerospike-server.deb

# Add the Aerospike run script
ADD aerospike.sh /usr/bin/aerospike

# Work from /tmp
WORKDIR /tmp

# Install Aerospike
RUN \
  chmod +x /usr/bin/aerospike \
  && dpkg -i aerospike-server.deb \
  && apt-get update -y \
  && apt-get install monit -y \
  && mkdir -p /var/monit/ \
  && chmod 0700 /etc/monit/monitrc \
  && apt-get purge -y --auto-remove \
  && rm -rf aerospike-server.deb

# Add the Aerospike configuration
ADD aerospike.conf /etc/aerospike/aerospike.conf
ADD aerospike.conf /opt/aerospike/etc/aerospike.conf

COPY monitrc /etc/monit/
RUN chmod 0700 /etc/monit/monitrc \
    && chmod 0770 /opt/aerospike/etc/aerospike.conf



# Mount the Aerospike data directory
VOLUME ["/opt/aerospike/data"]
VOLUME ["/opt/aerospike/etc"]

# Expose Aerospike ports
#
#   3000 – service port, for client connections
#   3001 – fabric port, for cluster communication
#   3002 – mesh port, for cluster heartbeat
#   3003 – info port
#
EXPOSE 3000 3001 3002 3003 9918

# Execute the run script
# We use the `ENTRYPOINT` because it allows us to forward additional
# arguments to `aerospike`
CMD ["/usr/bin/monit", "-I"]
