#!/bin/bash

#setup
export OS_USERNAME="pandrzejewski"
export OS_PASSWORD=CwQ7k6pyNtNg
export OS_PROJECT_NAME='admin'
export OS_REGION_NAME="RegionOne"
export OS_AUTH_URL=https://identity.mgmt.dev.spnt.pl:5000/v2.0

#boot centos
nova --insecure boot --flavor 3 --nic net-id=bc6e2617-3f1c-47f0-b5aa-2bb1d99d0813 --image "CentOS 7" centos-test-29

until [[ "$(nova --insecure show centos-test-29 | awk '/status/ {print $4}')" == "ACTIVE" ]]; do
        sleep 10s
done

#boot windows
nova --insecure boot --flavor 3 --nic net-id=bc6e2617-3f1c-47f0-b5aa-2bb1d99d0813 --image "Windows Server 2008 Standard" windows-test-29

until [[ "$(nova --insecure show windows-test-29 | awk '/status/ {print $4}')" == "ACTIVE" ]]; do
        sleep 10s
done

#get instances IP
CENTOS_IP=$(nova --insecure show centos-test-29 | awk '/flat-provider-network network/{print $5}');
WINDOWS_IP=$(nova --insecure show windows-test-29 | awk '/flat-provider-network network/{print $5}');

#check ping
ping -c 3 $CENTOS_IP
ping -c 3 $WINDOWS_IP

#get instances data
nova --insecure show centos-test-29
nova --insecure show windows-test-29

#delete instances
nova --insecure delete centos-test-29
nova --insecure delete windows-test-29
