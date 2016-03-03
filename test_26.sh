#!/bin/bash
# test_26
for i in $(cat ./images.txt); do
	cp ./etc/tempest.conf.0 ./etc/tempest.conf
	pom='s/image_ref =/image_ref ='
	pom+=$i
	pom+='/g'
	echo $pom
	perl -pi -e "$pom" ./etc/tempest.conf
	pom='s/image_ref_alt =/image_ref_alt ='
        pom+=$i
        pom+='/g'
	perl -pi -e "$pom" ./etc/tempest.conf
	(exec ./run_tempest.sh tempest.scenario.test_server_basic_ops)

done
