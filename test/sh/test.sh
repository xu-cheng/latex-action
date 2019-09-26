pwd
MIRROR_URL="$(cat test/sh/multiple-redirect.txt | sed -ne 's/.*Location: \(\w*\)/\1/p' | head -n 1)"
EXPECTED='http://mirrors.ibiblio.org/pub/mirrors/CTAN/'

if [ "${MIRROR_URL}" != "${EXPECTED}" ]; then
    echo "TEST FAIL!"
    echo "${MIRROR_URL}"
    exit 1
else
    echo "TEST PASS."
    exit 0
fi