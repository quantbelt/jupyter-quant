# Jupyter Quant

A dockerized Jupyter quant research enviroment.

## Highlights

- Designed for [ephemeral](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#create-ephemeral-containers) containers. Relevant data for your enviroment will survive your container.
- Optimized for size, it's a 2GB image vs 4GB for jupyter/scipy-notebook
- Includes all major python packages for data and timeseries analysis, see [requirements](https://github.com/gnzsnz/jupyter-quant/blob/master/requirements.txt)
- Includes jedi language server
- It does NOT include conda/mamba. All packages are installed with pip under ~/.local/lib/python. Which should be mounted in a dedicated volume to preserver your enviroment.
- Includes Cython, Numba, bottleneck and numexpr to speed up things
- The usual suspects are included, numpy, pandas, sci-py, scikit-learn
- Includes tools for quant analysis, statsmodels, pymc, arch, py_vollib, zipline-reloaded, PyPortfolioOpt, etc.
- ib_insync for Interactive Broker connectivity. Works well with [IB Gateway](https://github.com/gnzsnz/ib-gateway-docker)
- sudo, so you can install new packages if needed.
- bash and stow, so you can BYODF (bring your own dot files). Plus common command line utilities like git, less, nano (tiny), jq, ssh, curl, bash completion and others.
- Support for [apt cache](https://github.com/gnzsnz/apt-cacher-ng). If you have other linux boxes using you can leverage your cache. apt cache support major linux distributions not only debian/ubuntu.
- It does not include a build environment. If you need to install a package that does not provide wheels you can build your wheels, as explained in [common tasks](#common-tasks)

## Quick Start

Create a `docker-compose.yml` file with this content

```yml
version: "3.6"
services:
  jupyter-quant:
    image: gnzsnz/jupyter-quant:${IMAGE_VERSION}
    environment:
      APT_PROXY: ${APT_PROXY:-}
      BYODF: ${BYODF:-}
    restart: unless-stopped
    ports:
      - ${LISTEN_PORT}:8888
    volumes:
      - quant_conf:/home/gordon/.config
      - quant_data:/home/gordon/.local
      - ${PWD}/Notebooks:/home/gordon/Notebooks

volumes:
  quant_conf:
  quant_data:
```

You can use `.env-dist` as your starting point.

```bash
cp .env-dist .env
# verify everything looks good
docker compose config
docker compose up
```

## Volumes

The image is designed to work with 3 volumes:

1.  `quant_data` - volume for ~/.local folder. It contains caches and all python packages. This enables to add additional packages through pip.
1.  `quant_conf` - volume for ~/.config, all config goes here. This includes jupyter, ipython, matplotlib, etc
1.  Bind mount (but you could use a named volume) - volume for all notebooks, under `~/Notebooks`.

This allows to have ephemeral containers and to keep your notebooks (3), your config (2) and your additional packages (1). Eventually you would need to update the image, in this case your notebooks (3) can move without issues, your config (2) should still work but no warranty, and your packages could still be used. Eventually you would need to refresh (1) and less frecuently (2)

## Common tasks

- get running server URL
  
```bash
docker exec -it jupyterquant jupyter-server list
Currently running servers:
http://40798f7a604a:8888/?token=ebf9e870d2aa0ed877590eb83b4d3bbbdfbd55467422a167 :: /home/gordon/Notebooks
```

or

```bash
docker logs -t jupyter-quant 2>&1 | grep '127.0.0.1:8888/lab?token='
```

You will need to change hostname (40798f7a604a in this case) or 127.0.0.1 by your docker host ip.

- show jupyter config

```bash
docker exec -it jupyter-quant jupyter-server --show-config
```

- set password

```bash
docker exec -it jupyter-quant jupyter-server password
```

- get help

```bash
docker exec -it jupyter-quant jupyter-server --help
docker exec -it jupyter-quant jupyter-lab --help
```

- get installed packages

```bash
docker exec -it jupyter-quant pip list
# outdated packages
docker exec -it jupyter-quant pip list -o
```

- the image's entrypoint supports jupyter-lab parameters, for example

```bash
docker run -it --rm gnzsnz/jupyter-quant --core-mode
docker run -it --rm gnzsnz/jupyter-quant --show-config-json
```

- or run a command in the container

```bash
docker run -it --rm gnzsnz/jupyter-quant bash
```

- build wheels outside the container and import wheels to container

```bash
# make sure python version match .env-dist
docker run -it --rm -v $PWD/wheels:/wheels python:3.11 bash
pip wheel --no-cache-dir --wheel-dir /wheels numpy
```

This will build wheels for numpy (ot any other package that you need) and save the file in $PWD/wheels. Then you can copy the wheels in your notebooks mount (3 above) and install it within the container. You can even drag and drop into jupyter.

- Install your dotfiles.

`git clone` your dotfiles to `Notebook/etc/dotfiles`, set enviroment variable `BYODF=/home/gordon/Notebook/etc/dotfiles` in your docker compose. When the container starts up stow will create links like `/home/gordon/.bashrc`
