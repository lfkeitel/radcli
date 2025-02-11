#!/bin/bash

# Copyright (C) 2014 Nikos Mavrogiannopoulos
#
# License: BSD

srcdir="${srcdir:-.}"

echo "***********************************************"
echo "This test will use a radius server on localhost"
echo "and which can be executed with ns.sh   "
echo "***********************************************"

PID=$$
CLI_ADDRESS=10.203.1.1
ADDRESS=10.203.2.1
TMPFILE=tmp$$.out

function finish {
	rm -f servers-temp$PID 
	rm -f $TMPFILE
	rm -f radiusclient-temp$PID.conf
}

. ${srcdir}/ns.sh

sed -e 's/localhost/'$ADDRESS'/g' -e 's/servers-temp/servers-temp'$PID'/g' <$srcdir/radiusclient.conf >radiusclient-temp$PID.conf
sed 's/localhost/'$ADDRESS'/g' <$srcdir/servers >servers-temp$PID

echo ../src/radiusclient -D -i -f radiusclient-temp$PID.conf  User-Name=test Password=test | tee $TMPFILE
${CMDNS1} ../src/radiusclient -D -i -f radiusclient-temp$PID.conf  User-Name=test Password=test | tee $TMPFILE
if test $? != 0;then
	echo "Error in PAP auth"
	exit 1
fi

grep "^Message-Authenticator            = " $TMPFILE >/dev/null 2>&1
if test $? != 0;then
	echo "Error in request info data (Message-Authenticator)"
	cat $TMPFILE
	exit 1
fi

grep "^Framed-Protocol                  = 'PPP'$" $TMPFILE >/dev/null 2>&1
if test $? != 0;then
	echo "Error in data received by server (Framed-Protocol)"
	cat $TMPFILE
	exit 1
fi

grep "^Framed-IP-Address                = '192.168.1.190'$" $TMPFILE >/dev/null 2>&1
if test $? != 0;then
	echo "Error in data received by server (Framed-IP-Address)"
	cat $TMPFILE
	exit 1
fi

grep "^Framed-Route                     = '192.168.100.5/24'$" $TMPFILE >/dev/null 2>&1
if test $? != 0;then
	echo "Error in data received by server (Framed-Route)"
	cat $TMPFILE
	exit 1
fi

grep "^Request-Info-Secret = testing123$" $TMPFILE >/dev/null 2>&1
if test $? != 0;then
	echo "Error in request info data (secret)"
	cat $TMPFILE
	exit 1
fi

grep "^Request-Info-Vector = " $TMPFILE >/dev/null 2>&1
if test $? != 0;then
	echo "Error in request info data (vector)"
	cat $TMPFILE
	exit 1
fi

exit 0
