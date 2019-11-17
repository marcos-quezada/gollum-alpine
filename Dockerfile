FROM ruby:2.6.5-alpine3.10

ENV PANDOC_VERSION 2.7.3
ENV PANDOC_DOWNLOAD_URL https://hackage.haskell.org/package/pandoc-$PANDOC_VERSION/pandoc-$PANDOC_VERSION.tar.gz
ENV PANDOC_ROOT /usr/local/pandoc

ENV PATH $PATH:$PANDOC_ROOT/bin

# The default mirror (dl-cdn.alpinelinux.org) has issues sometimes for me
# More mirrors available here: mirrors.alpinelinux.org
RUN apk update
RUN apk add --no-cache --virtual build-deps build-base
RUN apk add --no-cache icu-dev icu-libs cmake git

RUN gem install gollum
RUN gem install github-markdown

# Install/Build Packages for pandoc
RUN apk add --no-cache --virtual linux-headers sed ttf-droid ttf-droid-nonlatin alpine-sdk coreutils
RUN apk add --no-cache ghc musl-dev zlib zlib-dev cabal curl bash

RUN curl -fsSL "$PANDOC_DOWNLOAD_URL" -o pandoc.tar.gz
RUN tar xvzf pandoc.tar.gz
RUN rm -f pandoc.tar.gz
WORKDIR /pandoc-$PANDOC_VERSION
RUN cabal update
RUN cabal install cabal-install
RUN cabal install --only-dependencies
RUN cabal configure --prefix=$PANDOC_ROOT
RUN cabal build
RUN cabal copy
WORKDIR /

RUN apk del --purge build-deps cmake build-base build-deps icu-dev alpine-sdk cabal coreutils ghc libffi musl-dev zlib-dev
RUN rm -Rf /root/.cabal/ /root/.ghc/ /root/pandoc-$PANDOC_VERSION

ENV PATH $PATH:$PANDOC_ROOT/bin

# Copy wiki admin files
COPY admin /wiki_admin/

# Create a volume and
WORKDIR /wiki

ENTRYPOINT ["/bin/sh", "-c", "/wiki_admin/start_gollum.sh /wiki_admin/gollum_config.yml -DFOREGROUND"]
EXPOSE 1990
