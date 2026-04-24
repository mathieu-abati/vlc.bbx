FROM buildbox:latest

RUN sed -i 's/Types: deb/Types: deb deb-src/' /etc/apt/sources.list.d/debian.sources
RUN apt update --yes
RUN apt install --yes \
	autopoint \
	lua5.2 \
	meson \
	yasm
RUN apt build-dep --yes vlc
RUN apt install --yes \
	libxcb-xkb-dev \
	libqt5quick5 \
	libqt5quickwidgets5 \
	qtquickcontrols2-5-dev \
	qtbase5-dev \
	qtdeclarative5-dev \
	libqt5svg5-dev
