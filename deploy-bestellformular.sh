#!/bin/bash

# Script that deploys the Bestellformular files to Aleph and the UB webserver

basedir=$PWD

DO_DEPLOY_ALEPH=1
DO_DEPLOY_ALEPH_SCHOOL=0
DO_DEPLOY_ALEPH_TEST=0
DO_DEPLOY_WWW=1
DO_DEPLOY_WWW_TEST=0

echo $basedir

if [ "$DO_DEPLOY_ALEPH" == "1" ]; then
   echo "Deploying files to Aleph-Server"
   scp $basedir/aleph/* aleph@aleph.unibas.ch:/exlibris/aleph/u22_1/alephe/apache/htdocs/
fi

if [ "$DO_DEPLOY_ALEPH_SCHOOL" == "1" ]; then
   echo "Deploying files to Alephschool-Server"
   scp $basedir/aleph/* aleph@alephschool.unibas.ch:/exlibris/aleph/u22_1/alephe/apache/htdocs/
fi

if [ "$DO_DEPLOY_ALEPH_TEST" == "1" ]; then
   echo "Deploying files to Alephtest-Server"
   scp $basedir/aleph/* aleph@alephtest.unibas.ch:/exlibris/aleph/u22_1/alephe/apache/htdocs/
fi

if [ "$DO_DEPLOY_WWW" == "1" ]; then
   echo "Deploying files to UB-Webserver"
   scp $basedir/webserver/* webmaster@ub-webvm.ub.unibas.ch:/export/www/cgi-bin/cms/
fi

if [ "$DO_DEPLOY_WWW_TEST" == "1" ]; then
   echo "Deploying files to Test-UB-Webserver"
   scp $basedir/webserver/* webmaster@ub-webqm.ub.unibas.ch:/export/www/cgi-bin/cms/
fi


~                                                                                                                                                                                                           
~                                                                                                                                                                                                           
~                                                                                                                                                                                                           
~                                                                                                                                                                                                           
~                                                                                                                                                                                                           
~                                                                                                                                                                                                           
~                                                                                                                                                                                                           
~                                                                                                                                                                                                           
~                                              
