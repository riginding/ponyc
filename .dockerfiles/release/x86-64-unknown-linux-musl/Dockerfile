FROM alpine:3.10

ENV PATH "/root/.pony/ponyup/bin:$PATH"

RUN apk add --update \
    curl \
    build-base \
    binutils-gold \
    libexecinfo-dev

RUN curl -s --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/ponylang/ponyup/master/ponyup-init.sh | sh \
 && ponyup update ponyc release --libc=musl \
 && ponyup update stable release \
 && ponyup update corral release \
 && ponyup update changelog-tool release

CMD ponyc
