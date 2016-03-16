#!/bin/bash
#setup
. common_config.sh
echo Creating new key pair
nova keypair-delete KEY_TEST_33
nova keypair-add KEY_TEST_33 > KEY_TEST_33.pem
chmod 600 KEY_TEST_33.pem

echo Creating new security group
nova secgroup-create SECURITY_GROUP_33 "Grupa testowa 33"
SEC_GROUP_ID=($(nova secgroup-create SECURITY_GROUP_33 "Grupa testowa 33"|grep "SECURITY_GROUP_33"|awk '{print $2}'))
nova secgroup-add-rule $SEC_GROUP_ID tcp 22 22 0.0.0.0/0
nova secgroup-add-rule $SEC_GROUP_ID icmp -1 -1 0.0.0.0/0

echo Starting new Centos 7.2 instance
INSTANCE_ID=($(nova boot --flavor 2 --nic net-id=$TEST_NETWORK_ID --key-name KEY_TEST_33 \
	--security-groups $SEC_GROUP_ID \
	--image "CentOS 7.2" centos-test-33 | awk '/id/ {print $4}'))

#wait for boot
until [[ "$(nova show $INSTANCE_ID | awk '/status/ {print $4}')" == "ACTIVE" ]]; do
        sleep 10s
done

#get instances IP
CENTOS_IP=$(nova show $INSTANCE_ID | awk '/flat-provider-network network/{print $5}');

echo Centos ip: $CENTOS_IP

until [[ "$(ping -c 1 $CENTOS_IP|awk '/1 received/ {print $2}')" ==  "packets" ]]; do
	sleep 10s
	echo -n .
done
echo

rm ~/.ssh/known_hosts
echo Waiting for ssh 
until [[ -n "$(ssh -o 'StrictHostKeyChecking no' -i KEY_TEST_33.pem centos@$CENTOS_IP 'echo 21271' 2>&1|grep '21271')" ]]; do
        sleep 10s
        echo -n .
done
echo

ssh -o 'StrictHostKeyChecking no' -i KEY_TEST_33.pem centos@$CENTOS_IP "echo '21271'>timestamp.tst"
#'touch timestamp.tst'

#echo EXIT
#exit 1

echo Creating snapshot of Centos instance

nova image-create $INSTANCE_ID centos_7_2_snapshot

#wait for snapshot
echo "Waiting for snaphot"
until [[ "$(nova image-list|awk '/centos_7_2_snapshot/ {print $6}')" == "ACTIVE" ]]; do
        sleep 10s
	echo -n .
done
echo "Snapshot created"

#remove instance
nova delete $INSTANCE_ID

#create instance from snaphot
echo Starting new Centos 7.2 instance from snapshot
INSTANCE_ID=($(nova boot --flavor 2 --nic net-id=$TEST_NETWORK_ID --key-name KEY_TEST_33 \
        --security-groups $SEC_GROUP_ID \
        --image "centos_7_2_snapshot" centos-test-33-from-snap | awk '/id/ {print $4}'))

#wait for boot
until [[ "$(nova show $INSTANCE_ID | awk '/status/ {print $4}')" == "ACTIVE" ]]; do
        sleep 10s
	echo -n .
done
echo

#get instances IP
CENTOS_IP=$(nova show $INSTANCE_ID | awk '/flat-provider-network network/{print $5}');

echo Centos ip: $CENTOS_IP

echo Waiting for ping
until [[ "$(ping -c 1 $CENTOS_IP|awk '/1 received/ {print $2}')" ==  "packets" ]]; do
        sleep 10s
        echo -n .
done
echo

rm ~/.ssh/known_hosts
echo Waiting for ssh 
until [[ -n "$(ssh -o 'StrictHostKeyChecking no' -i KEY_TEST_33.pem centos@$CENTOS_IP 'echo 21271' 2>&1|grep '21271')" ]]; do
        sleep 10s
        echo -n .
done
echo

#check for timestamp file
FILE_EXIST_ON_INST=($(ssh -o "StrictHostKeyChecking no" -i KEY_TEST_33.pem centos@$CENTOS_IP "ls timestamp.tst" 2>&1))
if [[ "$FILE_EXIST_ON_INST" == "timestamp.tst" ]]
then
	echo Timestamp EXISTS, test passed
else
	echo ERROR timestamp not found
fi

#echo EXIT
#exit 1

#delete instances
echo Cleaning up

nova delete $INSTANCE_ID
sleep 5s
nova secgroup-delete $SEC_GROUP_ID
nova image-delete centos_7_2_snapshot
