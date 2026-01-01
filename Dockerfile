###############################################################################
# Builder stage
###############################################################################
# hadolint global ignore=DL3003,DL3008,SC2028,DL3013
ARG IMG_PYTHON_VERSION=3.13
FROM python:$IMG_PYTHON_VERSION AS builder

# Use TARGETARCH build argument
ARG TARGETARCH
# Set environment variable for use in this stage
ENV ARCH=$TARGETARCH

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /builder
COPY . .

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN python3 -m pip install --no-cache-dir -U \
  build pip setuptools wheel setuptools_scm && \
  python3 -m build && \
  pip wheel --no-cache-dir --wheel-dir /wheels . && \
  rm /wheels/jupyter_quant-*.whl


###############################################################################
# Final stage
###############################################################################
ARG IMG_PYTHON_VERSION=3.13
FROM python:${IMG_PYTHON_VERSION}-slim

# Use TARGETARCH build argument
ARG TARGETARCH
# Set environment variable for use in this stage
ENV ARCH=$TARGETARCH

ARG DEBIAN_FRONTEND=noninteractive

ENV APT_PROXY_FILE=/etc/apt/apt.conf.d/01proxy

ENV USER=gordon
ARG USER_ID="${USER_ID:-1000}"
ARG USER_GID="${USER_GID:-1000}"
ENV IMAGE_VERSION=2502.1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PIP_USER=true
ENV PIP_NO_CACHE_DIR=1
ENV PATH="$PATH:/home/$USER/.local/bin"

# base data directory
ENV BASE_DATA="/home/${USER}/.local"
ENV BASE_CONFIG="/home/${USER}/.config"

# XDG env
ENV XDG_CACHE_HOME="${BASE_DATA}/cache"
ENV XDG_CONFIG_HOME="${BASE_CONFIG}"
ENV XDG_DATA_HOME="${BASE_DATA}/share"
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
# shell
ENV SHELL="/bin/bash"

COPY 99-arial-alias.conf /etc/fonts/conf.d/

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN if [ -n "$APT_PROXY" ]; then \
      echo "Acquire::http { Proxy \"${APT_PROXY}\"; }"  \
      | tee "${APT_PROXY_FILE}" \
    ;fi && \
  apt-get update && \
  apt-get install --no-install-recommends -y \
    openssh-client sshpass sudo curl graphviz git tzdata unzip less xclip nano-tiny \
    ffmpeg pandoc stow jq bash-completion procps fontconfig fonts-jetbrains-mono \
    fonts-dejavu-core fonts-firacode fonts-liberation2 && \
  apt-get clean && rm -rf /var/lib/apt/lists/* && \
  if [ -f "${APT_PROXY_FILE}" ]; then \
    rm "${APT_PROXY_FILE}" \
  ;fi && \
  groupadd --gid "${USER_GID}" "${USER}" && \
  useradd -ms /bin/bash --uid "${USER_ID}" --gid "${USER_GID}" "${USER}" && \
  echo "${USER} ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers && \
  fc-cache -fv && \
  python -c "import compileall; compileall.compile_path(maxlevels=10)"

USER $USER_ID:$USER_GID

COPY --chown=${USER}:${USER} matplotlibrc ${BASE_CONFIG}/matplotlib/matplotlibrc

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN --mount=type=bind,from=builder,source=/wheels,target=/wheels \
  pip install --user --no-deps --compile --no-cache-dir /wheels/* && \
  fc-cache -fv && \
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
