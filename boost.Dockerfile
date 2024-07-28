FROM centos:stream9 as builder

ARG BOOST_VERSION=1.80.0
ARG GCC_VERSION=13
ARG NUM_JOBS=4
ENV BOOST_VERSION=${BOOST_VERSION}
ENV GCC_VERSION=${GCC_VERSION}
ENV NUM_JOBS=${NUM_JOBS}

# use UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN dnf -y install gcc-toolset-${GCC_VERSION} cmake wget tar bzip2 && \
    dnf clean all

# Install Boost
# https://www.boost.org/doc/libs/1_80_0/more/getting_started/unix-variants.html
WORKDIR /tmp
RUN echo 'export BOOST_VERSION_MOD=$(echo $BOOST_VERSION | tr . _)' >> /profile
RUN echo '. /opt/rh/gcc-toolset-13/enable' >> /profile

RUN . /profile && \
    wget https://boostorg.jfrog.io/artifactory/main/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_MOD}.tar.bz2

RUN . /profile && \
    tar --bzip2 -xf boost_${BOOST_VERSION_MOD}.tar.bz2

RUN . /profile && \
    cd boost_${BOOST_VERSION_MOD} && \
    ./bootstrap.sh --prefix=/boost_out

RUN . /profile && \
    cd boost_${BOOST_VERSION_MOD} && \
    ./b2 install -j ${NUM_JOBS}

FROM scratch as final
COPY --from=builder /boost_out /

