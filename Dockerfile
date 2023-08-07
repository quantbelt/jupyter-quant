ARG PYTHON_VERSION
FROM python:"${PYTHON_VERSION:-3.11}"

ENV USER="${USER:-gordon}"
ARG USER_ID="${USER_ID:-1000}"
ARG USER_GID="${USER_GID:-1000}"
#ADD https://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz /tmp
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
  openssh-client  curl git tzdata unzip less xclip \
  nano-tiny ffmpeg pandoc libsnappy-dev && \
  apt-get clean && rm -rf /var/lib/apt/lists/* && \
  groupadd --gid ${USER_GID} ${USER} && \
  useradd -ms /bin/bash --uid ${USER_ID} --gid ${USER_GID} ${USER} &&\
  echo "${USER} ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers
  # # TA-Lib
  # cd /tmp && curl -LO https://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz && \
  # tar xzf /tmp/ta-lib-0.4.0-src.tar.gz && \
  # cd /tmp/ta-lib && \
  # curl -LO  http://savannah.gnu.org/cgi-bin/viewcvs/*checkout*/config/config/config.guess && \
  # curl -LO  http://savannah.gnu.org/cgi-bin/viewcvs/*checkout*/config/config/config.sub && \
  # ./configure --prefix=/usr && make && make install && \
  # cd / && rm -rf /tmp/ta-lib

COPY entrypoint.sh /
WORKDIR /home/$USER

USER $USER_ID:$USER_GID
COPY --chown=$USER:$USER requirements.txt .

ENV PATH="$PATH:/home/$USER/.local/bin"
# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME="/home/${USER}/.cache/"
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

RUN pip install --user --no-cache-dir -r requirements.txt && \
  MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
  mkdir Notebooks && chown $USER_ID:$USER_GID Notebooks

CMD jupyter-lab --no-browser --ip 0.0.0.0
ENTRYPOINT ["/entrypoint.sh"]

VOLUME ["/home/$USER"]
