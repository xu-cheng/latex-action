FROM alpine:latest

RUN apk --no-cache add \
        ghostscript \
        gnupg \
        perl \
        python \
        tar \
        wget \
        xz

ENV PATH="/opt/texlive/texdir/bin/x86_64-linuxmusl:${PATH}"
WORKDIR /root

COPY texlive_pgp_keys.asc texlive.profile setup.sh /root/
RUN /root/setup.sh

COPY LICENSE README.md /root/
COPY entrypoint.sh /root/entrypoint.sh
ENTRYPOINT ["/root/entrypoint.sh"]
