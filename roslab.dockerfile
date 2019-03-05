FROM ubuntu:16.04

################################## JUPYTERLAB ##################################

ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN apt-get -o Acquire::ForceIPv4=true update && apt-get -yq dist-upgrade \
 && apt-get -o Acquire::ForceIPv4=true install -yq --no-install-recommends \
	locales cmake git build-essential \
    python-pip \
	python3-pip python3-setuptools \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN pip3 install jupyterlab==0.35.4 bash_kernel==0.7.1 tornado==5.1.1 \
 && python3 -m bash_kernel.install

ENV SHELL=/bin/bash \
	NB_USER=jovyan \
	NB_UID=1000 \
	LANG=en_US.UTF-8 \
	LANGUAGE=en_US.UTF-8

ENV HOME=/home/${NB_USER}

RUN adduser --disabled-password \
	--gecos "Default user" \
	--uid ${NB_UID} \
	${NB_USER}

EXPOSE 8888

CMD ["jupyter", "lab", "--no-browser", "--ip=0.0.0.0", "--NotebookApp.token=''"]

################################# CMAKE_UPDATE #################################

RUN apt remove -y --purge --auto-remove cmake

RUN apt-get update \
 && apt-get install -yq --no-install-recommends wget libcurl4-openssl-dev zlib1g-dev\
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir /temp_cmake && cd /temp_cmake \
 && wget https://cmake.org/files/v3.13/cmake-3.13.4.tar.gz \
 && tar -xzvf cmake-3.13.4.tar.gz \
 && cd cmake-3.13.4 \
 && ./bootstrap --system-curl && make -j4 && make install \
 && rm -fr /temp_cmake

##################################### APT ######################################

RUN apt-get -o Acquire::ForceIPv4=true update \
 && apt-get -o Acquire::ForceIPv4=true install -yq --no-install-recommends \
    libboost-all-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

################################### SOURCE #####################################

RUN git clone https://bitbucket.org/gtborg/gtsam.git /gtsam \
 && cd /gtsam \
 && mkdir build \
 && cd build \
 && cmake  ../ \
 && make -j4 install \
 && rm -fr /gtsam

##################################### COPY #####################################

RUN mkdir ${HOME}/gp-slam

COPY . ${HOME}/gp-slam

#################################### CMAKE #####################################

RUN mkdir ${HOME}/gp-slam/build \
 && cd ${HOME}/gp-slam/build \
 && cmake  .. \
 && make -j2

##################################### TAIL #####################################

RUN chown -R ${NB_UID} ${HOME}

USER ${NB_USER}

WORKDIR ${HOME}/gp-slam
