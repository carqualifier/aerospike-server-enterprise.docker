#!/bin/bash

ASD=/usr/bin/asd
ASDN=$(basename $ASD)
CONFIG_FILE=/opt/aerospike/etc/aerospike.conf
OPTS="--config-file $CONFIG_FILE"
COLD_OPTS="$OPTS --cold-start"
PIDDIR="/var/run/aerospike"
PIDFILE=$PIDDIR/asd.pid
ASD_USER="aerospike"
ASD_GROUP=$ASD_USER
EDITION="enterprise"

INITFNS=/etc/aerospike/initfns
if [ -f $INITFNS ]; then . $INITFNS; fi

. /lib/lsb/init-functions

set_shmall() {
	mem=`/sbin/sysctl -n kernel.shmall`
	min=4294967296
	if [ ${#mem} -le ${#min} ]; then
	    if [ $mem -lt $min ]; then
		echo "kernel.shmall too low, setting to 4G pages = 16TB"
		/sbin/sysctl -w kernel.shmall=$min
	    fi
	fi
}

set_shmmax() {
	mem=`/sbin/sysctl -n kernel.shmmax`
	min=1073741824
	if [ ${#mem} -le ${#min} ]; then
	    if [ $mem -lt $min ]; then
		echo "kernel.shmmax too low, setting to 1GB"
		/sbin/sysctl -w kernel.shmmax=$min
	    fi
	fi
}

#We are adding create_piddir as /var/run is tmpfs on Debian 7+/Ubuntu 12+. This causes
#the piddir to be removed on reboot
create_piddir() {
	if [ ! -d $PIDDIR ]
	then
		(mkdir $PIDDIR && chown $ASD_USER:$ASD_GROUP $PIDDIR) &> /dev/null
	fi
}

start() {
	start-stop-daemon --start --quiet --name $ASDN --pidfile $PIDFILE --exec $ASD -- $OPTS
}

coldstart() {
	start-stop-daemon --start --quiet --name $ASDN --pidfile $PIDFILE --exec $ASD -- $COLD_OPTS
}

stop() {
	[ -f $PIDFILE ] && pid=`cat $PIDFILE`
	start-stop-daemon --stop --quiet --pidfile $PIDFILE --name $ASDN
	rv=$?
	[ $pid ] && while [ -e /proc/$pid ]; do sleep 0.1; done
	return $rv
}

case "$1" in
	start|coldstart)
		ulimit -n 100000
		logger -t aerospike "ulimit -n=" `ulimit -n`
		set_shmall
		set_shmmax
		create_piddir

		[ -n "$LD_PRELOAD" ] && export LD_PRELOAD
		log_daemon_msg "${1^}ing aerospike"
		$1
		case $? in
			0)
				log_end_msg 0
				;;
			1)
				echo "aerospike already started"
				log_end_msg 0
				;;
			*)
				log_end_msg 1
				;;
		esac
		;;
	stop)
		log_daemon_msg "Stopping aerospike"
		$1
		case $? in
			0)
				log_end_msg 0
				;;
			1)
				echo "aerospike already stopped"
				log_end_msg 0
				;;
			*)
				log_end_msg 1
				;;
		esac
		;;
	stop)
		log_daemon_msg "Halt aerospike: " "asd"
		if start-stop-daemon --stop --quiet --name $ASDN  ; then
			log_end_msg 0
		else
			log_end_msg 1
		fi
		;;
	status)
		status_of_proc -p $PIDFILE $ASDN aerospike
		;;
	restart)
		[ -n "`pgrep $ASDN`" ] && $0 stop
		$0 start
		;;
	*)
		echo $"Usage: $0 {start|stop|status|coldstart|restart}"
		exit 2
		;;
esac
