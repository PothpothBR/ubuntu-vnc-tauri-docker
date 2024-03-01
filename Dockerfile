FROM ubuntu:22.04

# prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# update dependencies
RUN apt update
RUN apt upgrade -y

# install xfce desktop
RUN apt install -y xfce4 xfce4-goodies

# install dependencies
RUN apt install -y \
  tightvncserver \
  novnc \
  net-tools \
  nano \
  vim \
  neovim \
  curl \
  wget \
  firefox \
  git \
  python3 \
  python3-pip

# xfce fixes
RUN update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal.wrapper

# setup Chromium
RUN git clone https://github.com/scheib/chromium-latest-linux.git /chromium
RUN /chromium/update.sh

# VNC and noVNC config
ARG USER=root
ENV USER=${USER}

ARG VNCPORT=5900
ENV VNCPORT=${VNCPORT}
EXPOSE ${VNCPORT}

ARG NOVNCPORT=9090
ENV NOVNCPORT=${NOVNCPORT}
EXPOSE ${NOVNCPORT}

ARG VNCPWD=changeme
ENV VNCPWD=${VNCPWD}

ARG VNCDISPLAY=1920x1080
ENV VNCDISPLAY=${VNCDISPLAY}

ARG VNCDEPTH=16
ENV VNCDEPTH=${VNCDEPTH}

# setup VNC
RUN mkdir -p /root/.vnc/
RUN echo ${VNCPWD} | vncpasswd -f > /root/.vnc/passwd
RUN chmod 600 /root/.vnc/passwd
RUN echo "#!/bin/sh \n\
xrdb $HOME/.Xresources \n\
xsetroot -solid grey \n\
#x-terminal-emulator -geometry 80x24+10+10 -ls -title "$VNCDESKTOP Desktop" & \n\
#x-window-manager & \n\
# Fix to make GNOME work \n\
export XKL_XMODMAP_DISABLE=1 \n\
/etc/X11/Xsession \n\
startxfce4 & \n\
" > /root/.vnc/xstartup
RUN chmod +x /root/.vnc/xstartup

# setup noVNC
RUN openssl req -new -x509 -days 365 -nodes \
  -subj "/C=US/ST=IL/L=Springfield/O=OpenSource/CN=localhost" \
  -out /etc/ssl/certs/novnc_cert.pem -keyout /etc/ssl/private/novnc_key.pem \
  > /dev/null 2>&1
RUN cat /etc/ssl/certs/novnc_cert.pem /etc/ssl/private/novnc_key.pem \
  > /etc/ssl/private/novnc_combined.pem
RUN chmod 600 /etc/ssl/private/novnc_combined.pem

ENTRYPOINT [ "/bin/bash", "-c", " \
  echo 'NoVNC Certificate Fingerprint:'; \
  openssl x509 -in /etc/ssl/certs/novnc_cert.pem -noout -fingerprint -sha256; \
  vncserver :0 -rfbport ${VNCPORT} -geometry $VNCDISPLAY -depth $VNCDEPTH -localhost; \
  /usr/share/novnc/utils/launch.sh --listen $NOVNCPORT --vnc localhost:$VNCPORT \
    --cert /etc/ssl/private/novnc_combined.pem \
" ]

# setup rust
RUN curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh -s - -y

# setup nvm
ARG NODE_VERSION=node
ENV NODE_VERSION=${NODE_VERSION}
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# setup pnpm
RUN wget -qO- https://get.pnpm.io/install.sh | ENV="$HOME/.bashrc" SHELL="$(which bash)" bash -

# install tauri dependencies
RUN apt install
  libwebkit2gtk-4.1-dev \
  build-essential \
  curl \
  wget \
  file \
  libssl-dev \
  libayatana-appindicator3-dev \
  librsvg2-dev
  
