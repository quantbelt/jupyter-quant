ARG PYTHON_VERSION
FROM python:"${PYTHON_VERSION:-3.11}" as builder

COPY requirements.txt .
RUN pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

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

WORKDIR /home/$USER
USER $USER_ID:$USER_GID

# XDG env
ENV XDG_CACHE_HOME="${BASE_DATA}/cache"
ENV XDG_CONFIG_HOME="${BASE_DATA}/etc"
ENV XDG_DATA_HOME="${BASE_DATA}/share "
ENV XDG_STATE_HOME="${BASE_DATA}/state"
# base data directory
ENV BASE_DATA="/home/${USER}/.local"
ENV NOTEBOOK_DIR="/home/${USER}/Notebooks"
# ipython
ENV IPYTHONDIR="${BASE_DATA}/etc/ipython"
# jupyter
ENV JUPYTER_CONFIG_DIR="${BASE_DATA}/etc/jupyter"
ENV JUPYTER_DATA_DIR="${BASE_DATA}/share/jupyter"
ENV JUPYTERLAB_DIR="${BASE_DATA}/share/jupyter/lab"
ENV JUPYTERLAB_SETTINGS_DIR="${JUPYTER_CONFIG_DIR}/lab/user-settings"
ENV JUPYTERLAB_WORKSPACES_DIR="${JUPYTER_CONFIG_DIR}/lab/workspaces"
# matplotlib
ENV MPLCONFIGDIR="${BASE_DATA}/etc/matplotlib"
#shell
ENV SHELL="/bin/bash"

RUN --mount=type=bind,from=builder,source=/wheels,target=/wheels \
  pip install --user --no-cache-dir /wheels/* && \
  # Import matplotlib the first time to build the font cache.
  MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
  mkdir Notebooks && chown $USER_ID:$USER_GID Notebooks

COPY entrypoint.sh /

CMD jupyter-lab --no-browser --ip 0.0.0.0
ENTRYPOINT ["/entrypoint.sh"]
