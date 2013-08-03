#!/bin/bash
# can set this to a path to the bin
etcd_bin=`which etcd`
state_dir="/tmp/_etcd_nodes"

if [ -z $etcd_bin ] ; then
  echo etcd not found in path. please add it to path or mod this scirpt to use the path to etcd
  exit 1
fi

if [ -z $2 ]; then
  cluster_size=3
else
  cluster_size=$2
fi

if [ ! -d $state_dir ] ; then
  mkdir -p $state_dir/.created
fi

function stop {
  for i in $state_dir/* ; do
    if [ -f $i/pid ] ; then
      echo "killing node $i"
      kill `cat $i/pid` 1>&2 > /dev/null
      if [ "$?" == "0" ]; then
        echo "Successs!"
        rm $i/pid
      fi
    fi
  done
}

function status {
  for i in $state_dir/* ; do
    if [ -f $i/pid ] ; then
      ps -p `cat $i/pid`
    fi
  done
}

function force_stop {
  killall -9 etcd
  if [ "$?" == 0 ] ; then
    for i in $state_dir/* ; do
      echo "cleaning up $i/pid"
      rm $i/pid
    done
  fi
}

function start {
  for i in `seq $cluster_size` ; do
    if [ "$i" == "1" ] ;  then
      # master is 1
      $etcd_bin -s 700$i -c 400$i -d $state_dir/node$i &
    else
      $etcd_bin -s 700$i -c 400$i -C 127.0.0.1:7001 -d $state_dir/node$i &
    fi
    echo $! >  $state_dir/node$i/pid
  done
}

case $1 in
  start)
    start
  ;;
  stop)
    stop
  ;;
  force_stop)
    force_stop
  ;;
  restart)
    stop && start
  ;;
  status)
    status
  ;;
  *)
    echo specify start/stop/restart/force_stop
    echo "  start can take an additional argument tho specify the cluster size"
  ;;
esac

