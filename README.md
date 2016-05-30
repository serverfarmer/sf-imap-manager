sf-imap-manager extension provides scripts for IMAP servers management,
that can be used with sf-imap-server and/or sf-imap-storage extensions.


add-imap-user.sh script can be used in 2 different modes:

```
add-imap-user.sh username mailserver.office storageserver.dc1
```

This mode assumes, that current server (on which you execute this script)
is the farm manager (and possibly backup collector), but IMAP accounts
storage (for at least this account) is delegated to some other server.

```
add-imap-user.sh username mailserver.office
```

This mode assumes, that current server is the farm manager and is also
responsible for IMAP accounts storage. Just like before, you can have
many IMAP storage servers in the farm.
