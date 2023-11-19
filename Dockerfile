###############################################################################
# Builder stage
###############################################################################
ARG IMG_PYTHON_VERSION
FROM python:"${IMG_PYTHON_VERSION}" AS builder

ENV APT_PROXY_FILE=/etc/apt/apt.conf.d/01proxy

COPY requirements.txt /.

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN if [ -n "$APT_PROXY" ]; then \
      echo "Acquire::http { Proxy \"${APT_PROXY}\"; }"  \
      | tee "${APT_PROXY_FILE}" \
    ;fi && \
  echo "deb http://deb.debian.org/debian bookworm contrib" | tee /etc/apt/sources.list.d/contrib.list && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
  libsnappy-dev libatlas-base-dev gfortran msttcorefonts pkg-config \
  libfreetype6-dev hdf5-tools cmake && \
  apt-get clean && rm -rf /var/lib/apt/lists/* && \
  # # TA-Lib
  cd /tmp && \
  curl -LO https://github.com/gnzsnz/jupyter-quant/releases/download/ta-lib-0.4.0-linux/ta-lib-0.4.0-linux_"$(uname -m)".tgz && \
  curl -LO https://github.com/gnzsnz/jupyter-quant/releases/download/ta-lib-0.4.0-linux/ta-lib-0.4.0-linux_"$(uname -m)".tgz.sha256 && \
  sha256sum -c ta-lib-0.4.0-linux_"$(uname -m)".tgz.sha256 && \
  cd / && tar xzf /tmp/ta-lib-0.4.0-linux_"$(uname -m)".tgz && \
  export PREFIX=/usr/local/ta-lib && \
  export TA_LIBRARY_PATH="$PREFIX/lib" && \
  export TA_INCLUDE_PATH="$PREFIX/include" && \
  # end TA-Lib
  pip wheel --no-cache-dir --wheel-dir /wheels -r /requirements.txt

###############################################################################
# Final stage
###############################################################################
ARG IMG_PYTHON_VERSION
FROM python:"${IMG_PYTHON_VERSION}"-slim

ENV APT_PROXY_FILE=/etc/apt/apt.conf.d/01proxy

ENV USER="${USER:-gordon}"
ARG USER_ID="${USER_ID:-1000}"
ARG USER_GID="${USER_GID:-1000}"
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PIP_USER true
ENV PATH="$PATH:/home/$USER/.local/bin"

# base data directory
ENV BASE_DATA="/home/${USER}/.local"
ENV BASE_CONFIG="/home/${USER}/.config"

# XDG env
ENV XDG_CACHE_HOME="${BASE_DATA}/cache"
ENV XDG_CONFIG_HOME="${BASE_CONFIG}"
ENV XDG_DATA_HOME="${BASE_DATA}/share "
ENV XDG_STATE_HOME="${BASE_DATA}/state"
# ipython
ENV IPYTHONDIR="${BASE_CONFIG}/ipython"
# jupyter
ENV JUPYTER_CONFIG_DIR="${BASE_CONFIG}/jupyter"
ENV JUPYTER_DATA_DIR="${BASE_DATA}/share/jupyter"
ENV JUPYTERLAB_DIR="${BASE_DATA}/share/jupyter/lab"
ENV JUPYTERLAB_SETTINGS_DIR="${JUPYTER_CONFIG_DIR}/lab/user-settings"
ENV JUPYTERLAB_WORKSPACES_DIR="${JUPYTER_CONFIG_DIR}/lab/workspaces"
ENV JUPYTER_SERVER_ROOT="/home/${USER}/Notebooks"
# matplotlib
ENV MPLCONFIGDIR="${BASE_CONFIG}/matplotlib"
# ta-lib
ENV TA_PREFIX=/usr/local/ta-lib
ENV TA_LIBRARY_PATH=$TA_PREFIX/lib
ENV TA_INCLUDE_PATH=$TA_PREFIX/include
# shell
ENV SHELL="/bin/bash"

COPY --from=builder /usr/share/fonts/truetype /usr/share/fonts/truetype
COPY --from=builder /usr/local/ta-lib/ /usr/local/ta-lib/

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN if [ -n "$APT_PROXY" ]; then \
      echo "Acquire::http { Proxy \"${APT_PROXY}\"; }"  \
      | tee "${APT_PROXY_FILE}" \
    ;fi && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
  openssh-client sudo curl git tzdata unzip less xclip nano-tiny ffmpeg \
  pandoc stow jq bash-completion && \
  apt-get clean && rm -rf /var/lib/apt/lists/* && \
  if [ -f "${APT_PROXY_FILE}" ]; then \
    rm "${APT_PROXY_FILE}" \
  ;fi && \
  groupadd --gid "${USER_GID}" "${USER}" && \
  useradd -ms /bin/bash --uid "${USER_ID}" --gid "${USER_GID}" "${USER}" && \
  echo "${USER} ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers && \
  python -c "import compileall; compileall.compile_path(maxlevels=10)"

USER $USER_ID:$USER_GID

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN --mount=type=bind,from=builder,source=/wheels,target=/wheels \
  pip install --user --no-cache-dir /wheels/* && \
  # Import matplotlib the first time to build the font cache.
  MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
  mkdir "${JUPYTER_SERVER_ROOT}" && \
  python -c "import compileall; compileall.compile_dir('${BASE_DATA}/lib/python$(echo "$PYTHON_VERSION" | cut -d '.' -f1,2)/site-packages', force=True)"

COPY entrypoint.sh /
WORKDIR ${JUPYTER_SERVER_ROOT}

CMD ["jupyter-lab", "--no-browser", "--ip=0.0.0.0"]
ENTRYPOINT ["/entrypoint.sh"]

LABEL org.opencontainers.image.source=https://github.com/gnzsnz/jupyter-quant
LABEL org.opencontainers.image.url=https://github.com/gnzsnz/jupyter-quant/pkgs/container/jupyter-quant
LABEL org.opencontainers.image.description="A dockerized Jupyter quant research enviroment. "
LABEL org.opencontainers.image.licenses="Apache License Version 2.0"
LABEL org.opencontainers.image.version=${IMAGE_VERSION}
