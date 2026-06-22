#!/bin/bash
PJPROJECT_VERSION="2.17"
MAX_CALLS=512
RECORDERS=1024
IOQUEUE=2048
CONF_PORTS=2052
WORKDIR=$(pwd)

# deps assumed installed by CI image (cibuildwheel manylinux): gcc, make, etc.

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
python3 setup.py build_ext --inplace

cd "${WORKDIR}"
mkdir -p src/pjsua2_python
cp pjproject/pjsip-apps/src/swig/python/*.so src/pjsua2_python/
