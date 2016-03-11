#!/bin/bash
#setup
. common_config.sh

MYRA=($(nova server-group-create test-31-server-group affinity| awk '{print $2}'))
GROUP_ID=${MYRA[1]}

nova quota-class-update --ram 102400 default
nova flavor-create test_31_1 42 32768 20 2
nova boot --flavor 42 --hint group=$GROUP_ID --nic net-id=bc6e2617-3f1c-47f0-b5aa-2bb1d99d0813 --image "CentOS 7" centos-test-31

#wait for boot
until [[ "$(nova  show centos-test-31 | awk '/status/ {print $4}')" == "ACTIVE" ]]; do
        sleep 10s
done

#get hypervisor name
HYPERV_HOST_NAME=$(nova show centos-test-31 | awk '/OS-EXT-SRV-ATTR:hypervisor_hostname/ {print $4}');

#get free ram
FREE_RAM=$(nova hypervisor-show $HYPERV_HOST_NAME| awk '/free_ram_mb/ {print $4}');

if (($FREE_RAM>0)); then
#crate new flavor
nova flavor-create test_31_2 43 $((1024 + $FREE_RAM)) 20 2

#boot windows with remaining ram + 1 GB
nova boot --flavor 43 --hint group=$GROUP_ID --nic net-id=bc6e2617-3f1c-47f0-b5aa-2bb1d99d0813 --image "Windows Server 2008 Standard " windos-test-31
#get instances IP
WINDOWS_IP=$(nova show windows-test-31 | awk '/flat-provider-network network/{print $5}');
#check ping
ping -c 3 $WINDOWS_IP
#get instances data
nova show windows-test-31
#clean up
nova flavor-delete 43
nova delete windows-test-31
else
 echo "Memory overcommit passed on first test step, free mem = $FREE_RAM" 
fi


#get instances IP
CENTOS_IP=$(nova show centos-test-31 | awk '/flat-provider-network network/{print $5}');

#check ping
sleep 30s
ping -c 3 $CENTOS_IP

#get instances data
nova show centos-test-31

#clean up
nova server-group-delete $GROUP_ID
nova flavor-delete 42

#delete instances
nova delete centos-test-31

