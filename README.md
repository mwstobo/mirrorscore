# mirrorscore
Simple tool that reads an `/etc/pacman.d/mirrorlist` file from stdin and outputs the mirrors sorted ascending by score.
```
cat /etc/pacman.d/mirrorlist | mirrorscore
```

Mirror scores can be found here: [https://www.archlinux.org/mirrors/status/](https://www.archlinux.org/mirrors/status/)
