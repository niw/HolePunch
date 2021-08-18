HolePunch
=========

NAME
----

`holepunch` -- A simple command line tool to punch hole to reduce disk
usage on APFS volume for such as a raw disk image.

SYNOPSIS
--------

```
holepunch [-pnvh] path
```

DESCRIPTION
-----------

`holepunch` is a simple command line tool that is using `F_PUNCHHOLE` to
punch a region of the file at `path` that only contains `0x00`
to reduce actual disk usage of the file on APFS volume.

The following options are available:

`-p, --show-progress`

Show progress while reading the file.

`-n, --dry-run`

Dry run. Do not actually punch hole.

`-v, --verbose`

Shows verbose messages.

`-h, --help`

Shows a help message.

USAGE
-----

It requires macOS 11.0 and later also it only works for the files
on APFS volume.

Install Xcode and build `holepunch` by using `swift build` command.

```
$ swift build -c release
```

Debug build may be very slow so recommend to use release build for
actual usage.

EXAMPLES
--------

On APFS volume, all files can be a sparse file, which unused area that
only contains `0x00` can be not actually using a disk space.

For example, [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop)
creates a raw disk image file at `~/Library/Containers/com.docker.docker/.../Docker.raw`
on APFS volume.

If you use `ls` or such tool, its file size shows more than actual disk
usage.

```
$ ls -l ~/Library/Containers/com.docker.docker/.../Docker.raw
-rw-r--r--  ... 60G ... .../Library/Containers/com.docker.docker/.../Docker.raw
```

The actual disk usage is much smaller than. You can see it by using
`du` or such tool.

```
$ du -h ~/Library/Containers/com.docker.docker/.../Docker.raw
2.7G	.../Library/Containers/com.docker.docker/.../Docker.raw
```

You can see this behavior on Finder by using "Get Info" menu item.
It may show file size like "63,999,836,160 bytes (2.85 GB on disk)".

This is because Docker Desktop for Mac is using same approach to punch
hole where a part of the disk image only contains `0x00` to reduce
actual disk usage.

See [Disk utilization in Docker for Mac](https://docs.docker.com/desktop/mac/space/#delete-unnecessary-containers-and-images)
for more details.

However, Docker Desktop for Mac is, actually, often, somehow, suppose
to do this online but often doesn't.

This tool is actually reading the file and find a region of `0x00`
and punch hole each region to actually reduce disk usage.

For example, after removing unused Docker images and stop Docker Desktop
for Mac, run following command.

```
$ holepunch --show-progress ~/Library/Containers/com.docker.docker/.../Docker.raw
```

SEE ALSO
--------

`fcntl(2)`, `copyfile(3)`
