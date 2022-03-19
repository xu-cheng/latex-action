FROM ghcr.io/xu-cheng/texlive-full:latest

COPY \
  LICENSE \
  README.md \
  entrypoint.sh \
  /root/

RUN chmod +x /opt/texlive/texdir/texmf-dist/scripts/arara/arara.sh

ENTRYPOINT ["/root/entrypoint.sh"]
