# BuildBox project for VLC media player

This is a [BuildBox](https://buildbox.trusted-objects.com) project to build
[VLC media player](https://images.videolan.org/vlc/index.html).

For now the following targets are supported:

| Target name | Description |
| ----------- | ----------- |
| x86-linux | Linux x86 build |

## Usage

First of all, setup BuildBox following the
[installation guide](https://buildbox.trusted-objects.com/getting-started/install.html).

Then, build VLC:

```bash
git clone https://github.com/mathieu-abati/vlc.bbx.git
cd vlc.bbx
bbx project info
bbx target set x86-linux
bbx target build -v
```

To run built VLC, you can do like this, from the `vlc.bbx` project folder:

```bash
xhost +local:docker
bbx shell
export DISPLAY=:0
goto vlc
./bin/vlc
```

> **_NOTE:_** Doing this, VLC runs in the BuildBox container. So you don't have
> access to host filesystem, only to your project tree.

## Image

The BuildBox project automatically fetchs the *buildbox-vlc* container image.\
This image is defined in [Dockerfile](Dockerfile), and it setups the build
environment required for VLC.
