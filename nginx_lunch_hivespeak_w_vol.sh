#! /bin/sh
#
# make sure to have docker installed before running this script!
# refer to following url to build the docker image before running this script
# https://github.com/yang-neu/dockerfiles/nginx_build_lunch.sh

set -e

CONTNAME=bee_ollelife
IMGNAME=ub18_snap_systemctl_ng

WWW_DIR=$(pwd)

SUDO=""
if [ -z "$(id -Gn|grep docker)" ] && [ "$(id -u)" != "0" ]; then
    SUDO="sudo"
fi

# start the detached container
$SUDO docker run \
    --name=$CONTNAME \
    -ti \
    -p 80:80 \
    -p 443:443 \
    --tmpfs /run \
    --tmpfs /run/lock \
    --tmpfs /tmp \
    --cap-add SYS_ADMIN \
    --device=/dev/fuse \
    --security-opt apparmor:unconfined \
    --security-opt seccomp:unconfined \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -v /lib/modules:/lib/modules:ro \
    -v $WWW_DIR:/var/hivespeak:ro \
    -d $IMGNAME 

# wait for snapd to start
TIMEOUT=100
SLEEP=0.1
echo -n "Waiting up to $(($TIMEOUT/10)) seconds for snapd startup "
while [ "$($SUDO docker exec $CONTNAME sh -c 'systemctl status snapd.seeded >/dev/null 2>&1; echo $?')" != "0" ]; do
    echo -n "."
    sleep $SLEEP 
    if [ "$TIMEOUT" -le "0" ]; then
        echo " Timed out!"
    fi
    TIMEOUT=$(($TIMEOUT-1))
done
echo " done"

$SUDO docker exec $CONTNAME snap install core --edge 
echo "container $CONTNAME started ..."
echo "modify /etc/nginx/sites-available/default to change www root to /var/hiveseak/html"
