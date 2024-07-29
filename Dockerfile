FROM centos:stream9 as base

ARG BOOST_VERSION=1.80.0
ARG GCC_VERSION=13
ARG NUM_JOBS=4
ARG QUANTLIB_VERSION=1.35
ENV BOOST_VERSION=${BOOST_VERSION}
ENV GCC_VERSION=${GCC_VERSION}
ENV NUM_JOBS=${NUM_JOBS}
ENV QUANTLIB_VERSION=${QUANTLIB_VERSION}

# use UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN dnf -y install gcc-toolset-${GCC_VERSION} cmake wget tar bzip2 && \
    dnf clean all
RUN echo '. /opt/rh/gcc-toolset-13/enable' >> /profile

FROM base as boost
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
    ./b2 install -j ${NUM_JOBS}

FROM base as quantlib
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
    make

FROM scratch as final
COPY --from=boost /output /boost
COPY --from=quantlib /output /quantlib

