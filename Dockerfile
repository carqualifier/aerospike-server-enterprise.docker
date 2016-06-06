FROM aerospike/aerospike-tools

COPY instance/*.sh /aerospike/instance/*
RUN chmod u+x /aerospike/instance/*

ADD run.sh /aerospike/run

WORKDIR /aerospike

ENTRYPOINT ["run"]
