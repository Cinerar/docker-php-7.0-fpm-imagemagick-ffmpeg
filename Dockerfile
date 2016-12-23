FROM ubuntu:14.04

ENV         DEBIAN_FRONTEND=noninteractive \
            FFMPEG_VERSION=3.1.4 \
            FAAC_VERSION=1.28    \
            FDKAAC_VERSION=0.1.4 \
            LAME_VERSION=3.99.5  \
            OGG_VERSION=1.3.2    \
            OPUS_VERSION=1.1.1   \
            THEORA_VERSION=1.1.1 \
            YASM_VERSION=1.3.0   \
            VORBIS_VERSION=1.3.5 \
            VPX_VERSION=1.6.0    \
            XVID_VERSION=1.3.4   \
            X265_VERSION=2.0     \
            X264_VERSION=20160826-2245-stable \
            PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
            SRC=/usr/local

RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d && \
    apt-get -y update && \
    apt-get -y --force-yes install software-properties-common python-software-properties && \
    add-apt-repository ppa:ondrej/php && \
    apt-get -y --force-yes update && \
    apt-get install -y --force-yes \
    curl \
    git-core \
    python-pip \
    php7.0-fpm php7.0-mcrypt php7.0-mbstring php7.0-curl php7.0-mysql php7.0-gd php7.0-intl php7.0-xsl \
    php7.0-cgi php7.0-common php7.0-cli php7.0-bz2 php7.0-zip php7.0-dev && \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer && \
    chmod +x /usr/local/bin/composer && \
    curl -L https://phar.phpunit.de/phpunit.phar -o phpunit.phar && \
    chmod +x phpunit.phar && \
    mv phpunit.phar /usr/local/bin/phpunit && \
    chmod +x /usr/local/bin/phpunit && \
    git clone git://github.com/xdebug/xdebug.git && \
    cd xdebug && phpize && ./configure --enable-xdebug && make && make install && cd .. && rm -rf xdebug && \
    sed "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" -i /etc/php/7.0/fpm/php.ini

RUN curl -L https://www.imagemagick.org/download/ImageMagick.tar.gz -o ImageMagick.tar.gz && \
    tar xvzf ImageMagick.tar.gz && cd ImageMagick* && \
    ./configure --with-librsvg && make && make install
    
RUN buildDeps="autoconf \
                    automake \
                    cmake \
                    curl \
                    bzip2 \
                    g++ \
                    gcc \
                    git \
                    libtool \
                    make \
                    nasm \
                    perl \
                    pkg-config \
                    python \
                    libssl-dev \
                    zlib1g-dev" && \
        export MAKEFLAGS="-j$(($(nproc) + 1))" && \
        apt-get -yqq --force-yes update && \
        apt-get install -yq --force-yes --no-install-recommends ${buildDeps} ca-certificates && \

        DIR=$(mktemp -d) && cd ${DIR} && \
        ## yasm http://yasm.tortall.net/
        curl -sL https://github.com/yasm/yasm/archive/v${YASM_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        ./autogen.sh && \
        ./configure --prefix="${SRC}" --bindir="${SRC}/bin" --datadir=${DIR} && \
        make && \
        make install && \
        make distclean && \
        rm -rf ${DIR} && \
        DIR=$(mktemp -d) && cd ${DIR} && \
        ## x264 http://www.videolan.org/developers/x264.html
        curl -sL https://ftp.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-${X264_VERSION}.tar.bz2 | \
        tar -jx --strip-components=1 && \
        ./configure --prefix="${SRC}" --bindir="${SRC}/bin" --enable-static && \
        make && \
        make install && \
        make distclean && \
        rm -rf ${DIR} && \
        DIR=$(mktemp -d) && cd ${DIR} && \
        ## x265 http://x265.org/
        curl -sL https://download.videolan.org/pub/videolan/x265/x265_${X265_VERSION}.tar.gz  | \
        tar -zx && \
        cd x265_${X265_VERSION}/build/linux && \
        ./multilib.sh && \
        make -C 8bit install && \
        rm -rf ${DIR} && \
        DIR=$(mktemp -d) && cd ${DIR} && \
        ## libogg https://www.xiph.org/ogg/
        curl -sL http://downloads.xiph.org/releases/ogg/libogg-${OGG_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        ./configure --prefix="${SRC}" --bindir="${SRC}/bin" --disable-shared --datadir=${DIR} && \
        make && \
        make install && \
        make distclean && \
        rm -rf ${DIR} && \
        DIR=$(mktemp -d) && cd ${DIR} && \
        ## libopus https://www.opus-codec.org/
        curl -sL http://downloads.xiph.org/releases/opus/opus-${OPUS_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        autoreconf -fiv && \
        ./configure --prefix="${SRC}" --disable-shared --datadir="${DIR}" && \
        make && \
        make install && \
        make distclean && \
        rm -rf ${DIR} && \
        DIR=$(mktemp -d) && cd ${DIR} && \
        ## libvorbis https://xiph.org/vorbis/
        curl -sL http://downloads.xiph.org/releases/vorbis/libvorbis-${VORBIS_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        ./configure --prefix="${SRC}" --with-ogg="${SRC}" --bindir="${SRC}/bin" \
        --disable-shared --datadir="${DIR}" && \
        make && \
        make install && \
        make distclean && \
        rm -rf ${DIR} && \
        DIR=$(mktemp -d) && cd ${DIR} && \
        ## libtheora http://www.theora.org/
        curl -sL http://downloads.xiph.org/releases/theora/libtheora-${THEORA_VERSION}.tar.bz2 | \
        tar -jx --strip-components=1 && \
        ./configure --prefix="${SRC}" --with-ogg="${SRC}" --bindir="${SRC}/bin" \
        --disable-shared --datadir="${DIR}" && \
        make && \
        make install && \
        make distclean && \
        rm -rf ${DIR} && \
        DIR=$(mktemp -d) && cd ${DIR} && \
        ## libvpx https://www.webmproject.org/code/
        curl -sL https://codeload.github.com/webmproject/libvpx/tar.gz/v${VPX_VERSION} | \
        tar -zx --strip-components=1 && \
        ./configure --prefix="${SRC}" --enable-vp8 --enable-vp9 --disable-examples --disable-docs && \
        make && \
        make install && \
        make clean && \
        rm -rf ${DIR} && \
        DIR=$(mktemp -d) && cd ${DIR} && \
        ## libmp3lame http://lame.sourceforge.net/
        curl -sL https://downloads.sf.net/project/lame/lame/${LAME_VERSION%.*}/lame-${LAME_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        ./configure --prefix="${SRC}" --bindir="${SRC}/bin" --disable-shared --enable-nasm --datadir="${DIR}" && \
        make && \
        make install && \
        make distclean&& \
        rm -rf ${DIR} && \
        DIR=$(mktemp -d) && cd ${DIR} && \
        ## faac https://sourceforge.net/projects/faac/ +  http://stackoverflow.com/a/4320377
        curl -sL https://downloads.sf.net/faac/faac-${FAAC_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        sed -i '126d' common/mp4v2/mpeg4ip.h && \
        ./bootstrap && \
        ./configure --prefix="${SRC}" --bindir="${SRC}/bin" --datadir="${DIR}" && \
        make && \
        make install && \
        rm -rf ${DIR} && \
        DIR=$(mktemp -d) && cd ${DIR} && \
        ## xvid https://www.xvid.com/
        curl -sL http://downloads.xvid.org/downloads/xvidcore-${XVID_VERSION}.tar.gz | \
        tar -zx && \
        cd xvidcore/build/generic && \
        ./configure --prefix="${SRC}" --bindir="${SRC}/bin" --datadir="${DIR}" && \
        make && \
        make install && \
        rm -rf ${DIR} && \
        DIR=$(mktemp -d) && cd ${DIR} && \
        ## fdk-aac https://github.com/mstorsjo/fdk-aac
        curl -sL https://github.com/mstorsjo/fdk-aac/archive/v${FDKAAC_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        autoreconf -fiv && \
        ./configure --prefix="${SRC}" --disable-shared --datadir="${DIR}" && \
        make && \
        make install && \
        make distclean && \
        rm -rf ${DIR} && \
        DIR=$(mktemp -d) && cd ${DIR} && \
        ## ffmpeg https://ffmpeg.org/
        curl -sL http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        ./configure --prefix="${SRC}" \
        --extra-cflags="-I${SRC}/include" \
        --extra-ldflags="-L${SRC}/lib" \
        --bindir="${SRC}/bin" \
        --disable-doc \
        --extra-libs=-ldl \
        --enable-version3 \
        --enable-libfaac \
        --enable-libfdk_aac \
        --enable-libmp3lame \
        --enable-libopus \
        --enable-libtheora \
        --enable-libvorbis \
        --enable-libvpx \
        --enable-libx264 \
        --enable-libx265 \
        --enable-libxvid \
        --enable-gpl \
        --enable-avresample \
        --enable-postproc \
        --enable-nonfree \
        --disable-debug \
        --enable-small \
        --enable-openssl && \
        make && \
        make install && \
        make distclean && \
        hash -r && \
        cd tools && \
        make qt-faststart && \
        cp qt-faststart ${SRC}/bin && \
        rm -rf ${DIR} && \
        ## cleanup
       cd && \
       apt-get purge -y --force-yes ${buildDeps} && \
#       apt-get autoremove -y --force-yes && \
#       apt-get clean -y --force-yes && \
       rm -rf /var/lib/apt/lists && \
       ffmpeg -buildconf

EXPOSE 9000

RUN find / -iname *fpm*


