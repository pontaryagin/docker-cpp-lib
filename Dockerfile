FROM registry.access.redhat.com/ubi9/ubi as base

ARG BOOST_VERSION=1.80.0 \
    GCC_VERSION=13 \
    NUM_JOBS=4 \
    QUANTLIB_VERSION=1.35 \
    EIGEN_VERSION=3.4.0 \
    GTEST_VERSION=1.15.2

ENV BOOST_VERSION=${BOOST_VERSION} \
    GCC_VERSION=${GCC_VERSION} \
    NUM_JOBS=${NUM_JOBS} \
    QUANTLIB_VERSION=${QUANTLIB_VERSION} \
    EIGEN_VERSION=${EIGEN_VERSION} \
    GTEST_VERSION=${GTEST_VERSION}

RUN dnf -y install gcc-toolset-${GCC_VERSION} cmake wget tar bzip2 git && \
    dnf clean all
RUN echo '. /opt/rh/gcc-toolset-13/enable' >> /profile

FROM base as boost_build
WORKDIR /work
RUN echo 'export BOOST_VERSION_MOD=$(echo $BOOST_VERSION | tr . _)' >> /profile

RUN . /profile && \
    wget https://boostorg.jfrog.io/artifactory/main/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_MOD}.tar.bz2

RUN . /profile && \
    tar --bzip2 -xf boost_${BOOST_VERSION_MOD}.tar.bz2 && \
    mv boost_${BOOST_VERSION_MOD} boost

WORKDIR /work/boost

RUN . /profile && \
    ./bootstrap.sh --prefix=/output

RUN . /profile && \
    ./b2 install -j ${NUM_JOBS} && \
    rm -rf ./*

FROM scratch as boost
COPY --from=boost_build /output /

FROM base as quantlib_build
COPY --from=boost /output /boost_output
WORKDIR /work
RUN wget https://github.com/lballabio/QuantLib/releases/download/v${QUANTLIB_VERSION}/QuantLib-${QUANTLIB_VERSION}.tar.gz

RUN tar -xf QuantLib-${QUANTLIB_VERSION}.tar.gz && \
    mv QuantLib-${QUANTLIB_VERSION} QuantLib

WORKDIR /work/QuantLib

RUN . /profile && \
    ./configure --with-boost-include=/boost_output/include \
                --prefix=/output 

RUN . /profile && \
    make install -j ${NUM_JOBS} && \
    rm -rf ./*

FROM scratch as quantlib
COPY --from=quantlib_build /output /

FROM base as eigen_build
WORKDIR /work
RUN wget https://gitlab.com/libeigen/eigen/-/archive/${EIGEN_VERSION}/eigen-${EIGEN_VERSION}.tar.gz
RUN tar -xf eigen-${EIGEN_VERSION}.tar.gz && \
    mv eigen-${EIGEN_VERSION} eigen

RUN . /profile && \
    mkdir build && \
    cd build && \
    cmake /work/eigen -DCMAKE_INSTALL_PREFIX=/output && \
    make install -j ${NUM_JOBS} && \
    rm -rf ./*

FROM scratch as eigen
COPY --from=eigen_build /output /

FROM base as gtest_build
WORKDIR /work
RUN git clone https://github.com/google/googletest.git -b v${GTEST_VERSION}

RUN . /profile && \
    cd googletest && \
    mkdir build && \
    cd build && \
    cmake /work/googletest -DCMAKE_INSTALL_PREFIX=/output && \
    make install -j ${NUM_JOBS} && \
    rm -rf ./*

FROM scratch as gtest
COPY --from=gtest_build /output /

FROM scratch as final
COPY --from=boost / /
COPY --from=quantlib / /
COPY --from=eigen / /
COPY --from=gtest / /
