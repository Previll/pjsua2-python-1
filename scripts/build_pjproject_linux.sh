#!/bin/bash
set -euo pipefail
PJPROJECT_VERSION=${PJPROJECT_VERSION:-2.17}
MAX_CALLS=${MAX_CALLS:-512}
RECORDERS=$((MAX_CALLS * 2))
IOQUEUE=$((MAX_CALLS * 4))
CONF_PORTS=$((MAX_CALLS * 4 + 4))
WORKDIR=$(pwd)

# deps assumed installed by CI image (cibuildwheel manylinux): gcc, make, etc.

rm -rf pjproject "pjproject-${PJPROJECT_VERSION}"

curl -fsSL "https://github.com/pjsip/pjproject/archive/refs/tags/${PJPROJECT_VERSION}.tar.gz" \
  | tar -xz
mv pjproject-${PJPROJECT_VERSION} pjproject

cd pjproject

./configure \
  --enable-shared \
  --enable-epoll \
  --disable-video \
  --disable-libwebrtc \
  --disable-sound \
  --disable-opencore-amr \
  --with-opus=/usr \
  CFLAGS="-fPIC -DNDEBUG -O2 -DPJMEDIA_HAS_WSOLA=0 \
          -DPJSUA_MAX_CALLS=${MAX_CALLS} \
          -DPJSUA_MAX_RECORDERS=${RECORDERS} \
          -DPJ_IOQUEUE_MAX_HANDLES=${IOQUEUE} \
          -DPJMEDIA_CONF_MAX_PORTS=${CONF_PORTS}"

make dep
make -j"$(nproc)"
make install
ldconfig

cd pjsip-apps/src/swig
make python

cd python
python setup.py build_ext --inplace

cd "${WORKDIR}"
mkdir -p src/pjsua2_python
rm -f src/pjsua2_python/*.so src/pjsua2_python/pjsua2.py
shopt -s nullglob
so_files=(pjproject/pjsip-apps/src/swig/python/*.so)
if (( ${#so_files[@]} == 0 )); then
  echo "ERROR: No .so bindings were produced in pjproject/pjsip-apps/src/swig/python"
  exit 1
fi
cp "${so_files[@]}" src/pjsua2_python/
cp pjproject/pjsip-apps/src/swig/python/*.py src/pjsua2_python/ 2>/dev/null || true
if [ ! -f src/pjsua2_python/__init__.py ]; then
  cat <<'EOF' > src/pjsua2_python/__init__.py
"""Python package for prebuilt PJSUA2 bindings."""
EOF
fi
