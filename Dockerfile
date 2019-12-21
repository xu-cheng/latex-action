# SHA hash is from Docker tag 20191201
FROM xucheng/texlive-full@sha256:85a768164d545a2947316554e0139367d6c6119df7982a953e05d58a62cc87c9

COPY \
  LICENSE \
  README.md \
  entrypoint.sh \
  /root/

ENTRYPOINT ["/root/entrypoint.sh"]
