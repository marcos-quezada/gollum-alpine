FROM alpine AS pandoc-builder

RUN apk --no-cache add \
         alpine-sdk \
         bash \
         ca-certificates \
         cabal \
         fakeroot \
         ghc \
         git \
         gmp-dev \
         lua5.3-dev \
         pkgconfig \
         zlib-dev

# Install newer cabal-install version
COPY cabal.root.config /root/.cabal/config
RUN cabal update \
  && cabal install cabal-install \
  && mv /root/.cabal/bin/cabal /usr/local/bin/cabal

# Get sources
ARG pandoc_commit=master
RUN git clone --branch=$pandoc_commit --depth=1 --quiet \
        https://github.com/jgm/pandoc /usr/src/pandoc

# Install Haskell dependencies
WORKDIR /usr/src/pandoc
RUN cabal --version \
  && ghc --version \
  && cabal new-update \
  && cabal new-clean \
  && cabal new-configure \
           --flag embed_data_files \
           --flag bibutils \
           --constraint 'hslua +system-lua +pkg-config' \
           --enable-tests \
           . pandoc-citeproc \
  && cabal new-build . pandoc-citeproc

FROM pandoc-builder AS pandoc-binaries
RUN find dist-newstyle \
         -name 'pandoc*' -type f -perm +400 \
         -exec cp '{}' /usr/bin/ ';' \
  && strip /usr/bin/pandoc /usr/bin/pandoc-citeproc

FROM ruby:2.6.5-alpine3.10

COPY --from=pandoc-binaries /usr/bin/pandoc* /usr/bin/

RUN apk add --no-cache \
         gmp \
         libffi \
         lua5.3 \
         lua5.3-lpeg
# Copy wiki admin files
COPY admin /wiki_admin/

# Create a volume and
WORKDIR /wiki

ENTRYPOINT ["/bin/sh", "-c", "/wiki_admin/start_gollum.sh /wiki_admin/gollum_config.yml -DFOREGROUND"]
EXPOSE 1990
