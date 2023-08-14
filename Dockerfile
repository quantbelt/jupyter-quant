ARG PYTHON_VERSION
FROM python:"${PYTHON_VERSION:-3.11}" as builder

COPY requirements.txt .
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
  libsnappy-dev libatlas-base-dev gfortran \
  pkg-config libfreetype6-dev hdf5-tools && \
  apt-get clean && rm -rf /var/lib/apt/lists/* && \
  # # TA-Lib
  cd /tmp && \
  curl -LO https://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz && \
  tar xzf /tmp/ta-lib-0.4.0-src.tar.gz && \
  cd /tmp/ta-lib && \
  curl -LO  http://savannah.gnu.org/cgi-bin/viewcvs/*checkout*/config/config/config.guess && \
  curl -LO  http://savannah.gnu.org/cgi-bin/viewcvs/*checkout*/config/config/config.sub && \
  ./configure --prefix=/usr && make && make install && \
  cd / && rm -rf /tmp/ta-lib && \
  pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

ARG PYTHON_VERSION
FROM python:"${PYTHON_VERSION:-3.11}"-slim

ENV USER="${USER:-gordon}"
ARG USER_ID="${USER_ID:-1000}"
ARG USER_GID="${USER_GID:-1000}"
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PATH="$PATH:/home/$USER/.local/bin"

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
  openssh-client  curl git tzdata unzip less xclip nano-tiny ffmpeg pandoc && \
  groupadd --gid ${USER_GID} ${USER} && \
  useradd -ms /bin/bash --uid ${USER_ID} --gid ${USER_GID} ${USER} && \
  echo "${USER} ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers

USER $USER_ID:$USER_GID

# base data directory
ENV BASE_DATA="/home/${USER}/.local"
# XDG env
ENV XDG_CACHE_HOME="${BASE_DATA}/cache"
ENV XDG_CONFIG_HOME="${BASE_DATA}/etc"
ENV XDG_DATA_HOME="${BASE_DATA}/share "
ENV XDG_STATE_HOME="${BASE_DATA}/state"
# ipython
ENV IPYTHONDIR="${BASE_DATA}/etc/ipython"
# jupyter
ENV JUPYTER_CONFIG_DIR="${BASE_DATA}/etc/jupyter"
ENV JUPYTER_DATA_DIR="${BASE_DATA}/share/jupyter"
ENV JUPYTERLAB_DIR="${BASE_DATA}/share/jupyter/lab"
ENV JUPYTERLAB_SETTINGS_DIR="${JUPYTER_CONFIG_DIR}/lab/user-settings"
ENV JUPYTERLAB_WORKSPACES_DIR="${JUPYTER_CONFIG_DIR}/lab/workspaces"
ENV JUPYTER_SERVER_ROOT="/home/${USER}/Notebooks"
# matplotlib
ENV MPLCONFIGDIR="${BASE_DATA}/etc/matplotlib"
#shell
ENV SHELL="/bin/bash"

RUN --mount=type=bind,from=builder,source=/wheels,target=/wheels \
  pip install --user --no-cache-dir /wheels/* && \
  # Import matplotlib the first time to build the font cache.
  MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
  mkdir ${JUPYTER_SERVER_ROOT}

COPY entrypoint.sh /
WORKDIR ${JUPYTER_SERVER_ROOT}

CMD jupyter-lab --no-browser --ip 0.0.0.0
ENTRYPOINT ["/entrypoint.sh"]
