reason_to_drain(){
  echo Draining because: $1
  exit 1
}


date
cat /project/testfile
ret_code=$?

if [ $ret_code -ne 0 ]; then
  reason_to_drain "project FS is gone"
fi

ls /cvmfs/soft.mugqic
IS_EVICTED=$(/usr/bin/cvmfs_talk -i soft.mugqic evict /CentOS6/modulefiles/mugqic/java/openjdk-jdk1.8.0_72 2>&1)

head  /cvmfs/soft.mugqic/CentOS6/modulefiles/mugqic/java/openjdk-jdk1.8.0_72 > /dev/null
ret_code=$?

if [[ $ret_code -ne 0 ]]  || [[ "$IS_EVICTED" != "OK" ]]; then
  reason_to_drain "soft.mugqic is broken"
fi

exit 0
