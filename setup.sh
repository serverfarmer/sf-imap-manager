#!/bin/sh

/opt/farm/scripts/setup/extension.sh sf-net-utils
/opt/farm/scripts/setup/extension.sh sf-passwd-utils
/opt/farm/scripts/setup/extension.sh sf-farm-manager

ln -sf /opt/farm/ext/imap-manager/add-imap-user.sh /usr/local/bin/add-imap-user
