Just in case anyone was curious about the source of the cue test data in this
folder:

```
find /mnt/junk/music -type f | grep .cue\$ | sort -R | head -n1
```
