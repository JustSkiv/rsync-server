## rsync-server

A `rsyncd`/`sshd` server in Docker.


### tl;dr

Start a server (both `sshd` and `rsyncd` are supported)

```
$ docker run \
    --name rsync-server \ # Name it
    -p 8000:873 \ # rsyncd port
    -p 9000:22 \ # sshd port
    -e SSH_AUTH_USERNAME="<your_username>" # username to auth by ssh
    -e SSH_AUTH_KEY="<you_ssh_key>" \ # ssh key
    -v /you/local/path:/data
    justskiv/rsync-test-server
```

#### `rsyncd`

Please note that `/volume` is the `rsync` volume pointing to `/data`. The data
will be at `/data` in the container. Use the `VOLUME` parameter to change the
destination path in the container. Even when changing `VOLUME`, you will still
`rsync` to `/volume`.

```
$ rsync -av /your/folder/ rsync://user@localhost:8000/volume
Password: pass
sending incremental file list
./
foo/
foo/bar/
foo/bar/hi.txt

sent 166 bytes  received 39 bytes  136.67 bytes/sec
total size is 0  speedup is 0.00
```


#### `sshd`

Please note that you are connecting as the `root` and not the user specified in
the `USERNAME` variable. If you don't supply a key file you will be prompted
for the `PASSWORD`.

```
$ rsync -av -e "ssh -i /your/private.key -p 9000 -l root" /your/folder/ localhost:/data
sending incremental file list
./
foo/
foo/bar/
foo/bar/hi.txt

sent 166 bytes  received 31 bytes  131.33 bytes/sec
total size is 0  speedup is 0.00
```


### Advanced Usage

Variable options (on run)

* `SSH_AUTH_KEY` - the `rsync` password. Required.
* `SSH_AUTH_USERNAME` - username to authenticate by ssh . defaults to `docker`
* `VOLUME`   - the path for `rsync`. defaults to `/data`
* `ALLOW`    - space separated list of allowed sources. defaults to `192.168.0.0/16 172.16.0.0/12`.


##### Simple server on port 873

```
$ docker run -p 873:873 justskiv/rsync-test-server \
    -e SSH_AUTH_KEY="<you_ssh_key>" \ # ssh key
```


##### Use a volume for the default `/data`

```
$ docker run -p 873:873 -v /your/folder:/data justskiv/rsync-test-server
```

##### Run on a custom port

```
$ docker run \
    -p 9999:873 \
    -v /your/folder:/data \
    -e SSH_AUTH_KEY="<you_ssh_key>" \ # ssh key
    justskiv/rsync-test-server
```

```
$ rsync rsync://admin@localhost:9999
volume            /data directory
```


##### Modify the default volume location

```
$ docker run \
    -p 9999:873 \
    -v /your/folder:/myvolume \
    -e VOLUME=/myvolume \
    -e SSH_AUTH_KEY="<you_ssh_key>" \ # ssh key
    justskiv/rsync-test-server
```

```
$ rsync rsync://admin@localhost:9999
volume            /myvolume directory
```

##### Allow additional client IPs

```
$ docker run \
    -p 9999:873 \
    -v /your/folder:/myvolume \
    -e SSH_AUTH_KEY="<you_ssh_key>" \ # ssh key
    -e VOLUME=/myvolume \
    -e ALLOW=192.168.8.0/24 192.168.24.0/24 172.16.0.0/12 127.0.0.1/32 \
    justskiv/rsync-test-server
```


##### Over SSH

If you would like to connect over ssh, you have to give your public key as an env variable
 `SSH_AUTH_KEY`

Also you can set username to auth: `SSH_AUTH_USERNAME`

Please note that when using `sshd` **you will be specifying the actual folder
destination as you would when using SSH.** On the contrary, when using the
`rsyncd` daemon, you will always be using `/volume`, which maps to `VOLUME`
inside of the container.

```
docker run \
    -v /your/folder:/myvolume \
    -e SSH_AUTH_USERNAME="username" # username to auth by ssh
    -e SSH_AUTH_KEY="<you_ssh_key>" \ # ssh key
    -e VOLUME=/myvolume \
    -e ALLOW=192.168.8.0/24 192.168.24.0/24 172.16.0.0/12 127.0.0.1/32 \
    -p 9000:22 \
    justskiv/rsync-test-server
```

```
$ rsync -av -e "ssh -i /your/private.key -p 9000" /your/folder/ username@localhost:/data
```
