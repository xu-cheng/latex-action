#!/bin/sh

set -e

echo "==> Install TeXLive"
mkdir -p /tmp/install-tl
cd /tmp/install-tl
MIRROR_URL="$(wget -q -S -O /dev/null http://mirror.ctan.org/ 2>&1 | sed -ne 's/.*Location: \(\w*\)/\1/p')"
wget -nv "${MIRROR_URL}systems/texlive/tlnet/install-tl-unx.tar.gz"
wget -nv "${MIRROR_URL}systems/texlive/tlnet/install-tl-unx.tar.gz.sha512"
wget -nv "${MIRROR_URL}systems/texlive/tlnet/install-tl-unx.tar.gz.sha512.asc"
gpg --import /root/texlive_pgp_keys.asc
gpg --verify ./install-tl-unx.tar.gz.sha512.asc
sha512sum -c ./install-tl-unx.tar.gz.sha512
mkdir -p /tmp/install-tl/installer
tar --strip-components 1 -zxf /tmp/install-tl/install-tl-unx.tar.gz \
  -C /tmp/install-tl/installer
/tmp/install-tl/installer/install-tl --profile=/root/texlive.profile

echo "==> Install Packages"
tlmgr update --self
tlmgr install \
  biber \
  biblatex \
  latexmk \
  texliveonfly

echo "==> Clean up"
rm -rf \
  /opt/texlive/texdir/install-tl \
  /opt/texlive/texdir/install-tl.log \
  /opt/texlive/texdir/texmf-dist/doc \
  /opt/texlive/texdir/texmf-dist/source \
  /opt/texlive/texdir/texmf-var/web2c/tlmgr.log \
  /root/.gnupg \
  /root/setup.sh \
  /root/texlive.profile \
  /root/texlive_pgp_keys.asc \
  /tmp/install-tl
