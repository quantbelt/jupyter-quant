###############################################################################
# Builder stage
###############################################################################
# hadolint global ignore=DL3003,DL3008,SC2028
ARG IMG_PYTHON_VERSION=3.12
FROM python:$IMG_PYTHON_VERSION AS builder

ENV APT_PROXY_FILE=/etc/apt/apt.conf.d/01proxy
ARG TALIB_VERSION=ta-lib-0.6.2-linux
ARG GH_URL_BASE=https://github.com/quantbelt/jupyter-quant/releases/download/${TALIB_VERSION}
ARG TALIB_FILE="${TALIB_VERSION}_"
ARG TALIB_URL="${GH_URL_BASE}/${TALIB_FILE}"

COPY README.md LICENSE.txt pyproject.toml /
COPY jupyter_quant/__init__.py /jupyter_quant/

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN if [ -n "$APT_PROXY" ]; then \
      echo "Acquire::http { Proxy \"${APT_PROXY}\"; }"  \
      | tee "${APT_PROXY_FILE}" \
    ;fi && \
  echo "deb http://deb.debian.org/debian bookworm contrib" | tee /etc/apt/sources.list.d/contrib.list && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
  libatlas-base-dev msttcorefonts pkg-config libfreetype6-dev libhdf5-dev cmake && \
  apt-get clean && rm -rf /var/lib/apt/lists/* && \
  # # TA-Lib
  cd /tmp && \
  curl -LO "${TALIB_URL}$(uname -m).tgz" && \
  curl -LO "${TALIB_URL}$(uname -m).tgz.sha256" && \
  sha256sum -c "${TALIB_FILE}$(uname -m).tgz.sha256" && \
  cd / && tar xzf "/tmp/${TALIB_FILE}$(uname -m).tgz" && \
  export PREFIX=/usr/local/ta-lib && \
  export TA_LIBRARY_PATH="$PREFIX/lib" && \
  export TA_INCLUDE_PATH="$PREFIX/include" && \
  # end TA-Lib
  pip wheel --no-cache-dir --wheel-dir /wheels . && \
  rm /wheels/jupyter_quant-*.whl


###############################################################################
# Final stage
###############################################################################
ARG IMG_PYTHON_VERSION=3.12
FROM python:${IMG_PYTHON_VERSION}-slim

ENV APT_PROXY_FILE=/etc/apt/apt.conf.d/01proxy

ENV USER=gordon
ARG USER_ID="${USER_ID:-1000}"
ARG USER_GID="${USER_GID:-1000}"
ENV IMAGE_VERSION=2502.1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PIP_USER=true
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
    openssh-client sshpass sudo curl graphviz git tzdata unzip less xclip nano-tiny \
    ffmpeg pandoc stow jq bash-completion procps fonts-jetbrains-mono \
    fonts-dejavu-core fonts-firacode && \
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
  pip install --user --no-deps --compile --no-cache-dir /wheels/* && \
  # Import matplotlib the first time to build the font cache.
  MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
  mkdir "${JUPYTER_SERVER_ROOT}"

COPY entrypoint.sh /
WORKDIR ${JUPYTER_SERVER_ROOT}

CMD ["jupyter-lab", "--no-browser", "--ip=0.0.0.0"]
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 8888

LABEL org.opencontainers.image.source=https://github.com/quantbelt/jupyter-quant
LABEL org.opencontainers.image.url=https://github.com/quantbelt/jupyter-quant/pkgs/container/jupyter-quant
LABEL org.opencontainers.image.description="A dockerized Jupyter quant research enviroment. "
LABEL org.opencontainers.image.licenses="Apache License Version 2.0"
LABEL org.opencontainers.image.version=${IMAGE_VERSION}
