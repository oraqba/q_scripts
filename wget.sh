#!/bin/sh
#export https_proxy="http://u843191:Poiu0987%21@proxyp.cms.fra.dlh.de:8080/"
file=$@
read -s -p "Please enter your possword: " MOS_PASSWORD

get ()
{
arg1=$1
wget --http-user=jakub@nsb-software.de --http-password=$MOS_PASSWORD --no-check-certificate --output-document=$arg1 "https://updates.oracle.com/Orion/Download/download_patch/$arg1"
}

for i in $file
        do
                get $i
        done
