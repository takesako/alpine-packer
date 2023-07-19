#!/bin/sh -x
sed -r 's;#(.*[0-9]/community);\1;g' -i /etc/apk/repositories
sed -r 's;(.*/edge/main);#\1;g' -i /etc/apk/repositories
apk update
