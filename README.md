# BuildBox project for VLC media player

This is a [BuildBox](https://buildbox.trusted-objects.com) project to build
[VLC media player](https://images.videolan.org/vlc/index.html).

For now the following targets are supported:

| Target name | Description |
| ----------- | ----------- |
| x86-linux | Linux x86 build |

## Build and run VLC

### Prerequisites

First of all, setup BuildBox following the
[installation guide](https://buildbox.trusted-objects.com/getting-started/install.html).

Prepare VLC project:

```bash
bbx clone https://github.com/mathieu-abati/vlc.bbx.git
cd vlc.bbx
bbx project info
```

### Build VLC for Linux x86 64

```bash
bbx target set x86-linux
bbx target build -v
```

### Run built VLC media player

```bash
xhost +local:docker
bbx target test
```

> **_NOTE:_** Doing this, VLC runs in the BuildBox container. So you don't have
> access to host filesystem, only to your project tree.

### Create VLC AppImage

AppAimages are standalone executable files. You can generate one for VLC by
running:

```
bbx target dist
```

The generated AppImage will be available in your `vlc.bbx` project directory,
at `x86-linux/dist/VLC-x86_64.AppImage`.

## BuildBox container image for VLC

The BuildBox project automatically fetchs the *buildbox-vlc* container image.

This image is derived from BuildBox base image, and is defined in
[Dockerfile](Dockerfile).
It setups the build environment required for VLC.

[Visit DockerHub page](https://hub.docker.com/repository/docker/mathieuabati/buildbox-vlc/general)
