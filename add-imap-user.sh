#!/bin/bash
. /opt/farm/scripts/functions.uid
. /opt/farm/scripts/functions.custom
. /opt/farm/scripts/functions.keys
# create IMAP/fetchmail account:
# - first on local management server (to preserve UID)
# - then on specified mail server (sf-imap-server extension required)
# - last on specified backup server (if not the same)
# Tomasz Klim, 2014-2016


MINUID=1400
MAXUID=1599


type=`/opt/farm/scripts/config/detect-hostname-type.sh $2`

if [ "$2" = "" ]; then
	echo "usage: $0 <user> <mail-server[:port]> [backup-server[:port]]"
	exit 1
elif ! [[ $1 =~ ^[a-z0-9]+$ ]]; then
	echo "error: parameter $1 not conforming user name format"
	exit 1
elif [ -d /srv/imap/$1 ]; then
	echo "error: user $1 exists"
	exit 1
elif [ "$type" != "hostname" ] && [ "$type" != "ip" ]; then
	echo "error: parameter $2 not conforming hostname format, or given hostname is invalid"
	exit 1
fi

uid=`get_free_uid $MINUID $MAXUID`

if [ $uid -lt 0 ]; then
	echo "error: no free UIDs"
	exit 1
fi

mailserver=$2
backupserver=$3

if [ -z "${mailserver##*:*}" ]; then
	mailhost="${mailserver%:*}"
	mailport="${mailserver##*:}"
else
	mailhost=$mailserver
	mailport=22
fi

if [ "$backupserver" != "" ] && [ "$backupserver" != "$mailserver" ]; then
	type=`/opt/farm/scripts/config/detect-hostname-type.sh $backupserver`

	if [ "$type" != "hostname" ] && [ "$type" != "ip" ]; then
		echo "error: parameter $3 not conforming hostname format, or given hostname is invalid"
		exit 1
	fi

	if [ -z "${backupserver##*:*}" ]; then
		backuphost="${backupserver%:*}"
		backupport="${backupserver##*:}"
	else
		backuphost=$backupserver
		backupport=22
	fi
fi

path=/srv/imap/$1
useradd -u $uid -d $path -m -g imapusers -s /bin/false imap-$1
chmod 0711 $path
date +"%Y.%m.%d %H:%M" >$path/from.date

touch $path/.fetchmailrc
touch $path/.ignorepatterns
touch $path/.uidl

mkdir -p $path/Maildir/cur $path/Maildir/new $path/Maildir/tmp $path/logs

chmod -R 0700 $path/Maildir
chmod 0750 $path/logs
chmod 0660 $path/.ignorepatterns
chmod 0600 $path/.fetchmailrc $path/.uidl

rm $path/.bash_logout $path/.bashrc $path/.profile
chown -R imap-$1:imapusers $path

mailkey=`ssh_management_key_storage_filename $mailhost`
rsync -e "ssh -i $mailkey -p $mailport" -av $path root@$mailhost:/srv/imap
ssh -i $mailkey -p $mailport root@$mailhost "useradd -u $uid -d $path -M -g imapusers -G www-data -s /bin/false imap-$1"
ssh -i $mailkey -p $mailport root@$mailhost "echo \"# */5 * * * * imap-$1 /opt/farm/ext/imap-server/cron/fetchmail.sh imap-$1 $1\" >>/etc/crontab"
ssh -i $mailkey -p $mailport root@$mailhost "passwd imap-$1"

if [ "$backupserver" != "" ] && [ "$backupserver" != "$mailserver" ]; then
	backupkey=`ssh_management_key_storage_filename $backuphost`
	ssh -i $backupkey -p $backupport root@$backuphost "useradd -u $uid -d $path -M -g imapusers -s /bin/false imap-$1"
	rsync -e "ssh -i $backupkey -p $backupport" -av $path root@$backuphost:/srv/imap
fi
