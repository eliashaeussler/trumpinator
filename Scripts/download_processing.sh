#!/bin/bash
zipfile="processing-3.1.1-linux32.tgz"

if [ ! -e $zipfile ]
then
  wget http://download.processing.org/$zipfile
fi

tar zxvf $zipfile > /dev/null
