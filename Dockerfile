FROM ghcr.io/xu-cheng/texlive-full:20230301

COPY \
  LICENSE \
  README.md \
  entrypoint.sh \
  /root/

ENTRYPOINT ["/root/entrypoint.sh"]
