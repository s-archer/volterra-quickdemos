remove symlink /etc/resolv.conf
replace with vi /etc/resolv.conf and add:

nameserver 127.0.0.53
nameserver 10.0.102.165  (or whatever the master node IP is)