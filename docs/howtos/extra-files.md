# Copying files to the new installation

The `--extra-files <path>` option allows copying files to the target host after
installation.

The contents of the `<path>` is recursively copied and overwrites the targets
root (/). The contents _must_ be in a structure and permissioned as it should be
on the target.

In this way, there is no need to repeatedly pass arguments (eg: a fictional
argument: `--copy <source> <dest>`) to `nixos-anywhere` to complete the intended
outcome.

The path and directory structure passed to `--extra-files` should be prepared
beforehand.

This allows a simple programmatic invocation of `nixos-anywhere` for multiple
hosts.

## Simple Example

You want `/etc/ssh/ssh_host_*` and `/persist` from the local system on the
target. The `<path>` contents will look like this:

```console
$ cd /tmp
$ root=$(mktemp -d)
$ sudo cp --verbose --archive --parents /etc/ssh/ssh_host_* ${root}
$ cp --verbose --archive --link /persist ${root}
```

The directory structure would look like this:

```console
drwx------ myuser1 users   20  tmp.d6nx5QUwPN
drwxr-xr-x root    root     6  ├── etc
drwx------ myuser1 users  160  │   └── ssh
.rw------- root    root   399  │       ├── ssh_host_ed25519_key
.rw-r--r-- root    root    91  │       ├── ssh_host_ed25519_key.pub
drwxr-xr-x myuser1 users   22  └── persist
drwxr-xr-x myuser1 users   14      ├── all
drwxr-xr-x myuser1 users   22      │   ├── my
.rw-r--r-- myuser1 users    6      │   │   ├── test3
drwxr-xr-x myuser1 users   10      │   │   └── things
.rw-r--r-- myuser1 users    6      │   │       └── test4
.rw-r--r-- myuser1 users    6      │   └── test2
drwxr-xr-x myuser1 users    0      ├── blah
.rw-r--r-- myuser1 users    6      └── test
```

**NOTE**: Permissions will be copied, but ownership on the target will be root.

Then pass $root like:

> nixos-anywhere --flake ".#" --extra-files $root --target-host root@newhost

## Programmatic Example

```sh
for host in host1 host2 host3; do
    root="target/${host}"
    install -d -m755 ${root}/etc/ssh
    ssh-keygen -A -C root@${host} -f ${root}
    nixos-anywhere --extra-files "${root}" --flake ".#${host}" --target-host "root@${host}"
done
```

## Considerations

### Ownership

The new system may have differing UNIX user and group id's for users created
during installation.

When the files are extracted on the remote the copied data will be owned by
root.

If you wish to change the ownership after the files are copied onto the system,
you can use the `--chown` option.

For example, if you did `--chown /home/myuser/.ssh 1000:100`, this would equate
to running `chown -R /home/myuser/.ssh 1000:100` where the uid is 1000 and the
gid is 100. **Only do this when you can _guarantee_ what the uid and gid will
be.**

### Symbolic Links

Do not create symbolic links to reference data to copy.

GNU `tar` is used to do the copy over ssh. It is an archival tool used to
re/store directory structures as is. Thus `tar` copies symbolic links created
with `ln -s` by default. It does not follow them to copy the underlying file.

### Hard links

**NOTE**: hard links can only be created on the same filesystem.

If you have larger persistent data to copy to the target. GNU `tar` will copy
data referenced by hard links created with `ln`. A hard link does not create
another copy the data.

To copy a directory tree to the new target you can use the `cp` command with the
`--link` option which creates hard links.

#### Example

```sh
cd /tmp
root=$(mktemp -d)
cp --verbose --archive --link --parents /persist/home/myuser ${root}
```

`--parents` will create the directory structure of the source at the
destination.
