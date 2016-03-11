#!/bin/bash
. common_config.sh

#boot centos
nova boot --flavor 3 --nic net-id=bc6e2617-3f1c-47f0-b5aa-2bb1d99d0813 --image "CentOS 7" centos-test-29

until [[ "$(nova show centos-test-29 | awk '/status/ {print $4}')" == "ACTIVE" ]]; do
        sleep 10s
done

#boot windows
nova boot --flavor 3 --nic net-id=bc6e2617-3f1c-47f0-b5aa-2bb1d99d0813 --image "Windows Server 2008 Standard" windows-test-29

until [[ "$(nova show windows-test-29 | awk '/status/ {print $4}')" == "ACTIVE" ]]; do
        sleep 10s
done

#get instances IP
CENTOS_IP=$(nova show centos-test-29 | awk '/flat-provider-network network/{print $5}');
WINDOWS_IP=$(nova show windows-test-29 | awk '/flat-provider-network network/{print $5}');

#check ping
ping -c 3 $CENTOS_IP
ping -c 3 $WINDOWS_IP

#get instances data
nova show centos-test-29
nova show windows-test-29

#delete instances
nova delete centos-test-29
nova delete windows-test-29
