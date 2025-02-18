# Jupyter Quant

A dockerized Jupyter quant research environment.

## Highlights

- It can be used as a docker image or pypi package.
- Includes tools for quant analysis, statsmodels, pymc, arch, py_vollib,
  zipline-reloaded, PyPortfolioOpt, etc.
- The usual suspects are included, numpy, pandas, sci-py, scikit-learn,
  yellowbricks, shap, optuna.
- [ib_async](https://github.com/ib-api-reloaded/ib_async) for Interactive Broker
  connectivity. Works well with
  [IB Gateway](https://github.com/gnzsnz/ib-gateway-docker) docker image.
  [ib_insync](https://github.com/erdewit/ib_insync/) has been invaluable all
  this time, RIP Ewald.
- Includes all major Python packages for statistical and time series analysis,
  see [requirements](https://github.com/gnzsnz/jupyter-quant/blob/master/requirements.txt).
  For an extensive list check
  [list installed packages](#list-installed-packages) section.
- [Zipline-reloaded](https://github.com/stefan-jansen/zipline-reloaded/),
  [pyfolio-reloaded](https://github.com/stefan-jansen/pyfolio-reloaded)
  and [alphalens-reloaded](https://github.com/stefan-jansen/alphalens-reloaded).
- [ib_fundamental](https://github.com/quantbelt/ib_fundamental) for IBKR
  fundamental data.
- You can install it as a python package, just `pip install -U jupyter-quant`
- Designed for [ephemeral](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#create-ephemeral-containers)
  containers. Relevant data for your environment will survive your container.
- Optimized for size, it's a 2GB image vs 4GB for jupyter/scipy-notebook
- Includes jedi language server, jupyterlab-lsp, black and isort.
- It does NOT include conda/mamba. All packages are installed with pip under
  `~/.local/lib/python`. Which should be mounted in a dedicated volume to
  preserve your environment.
- Includes Cython, Numba, bottleneck and numexpr to speed up things
- sudo, so you can install new packages if needed.
- bash and stow, so you can [BYODF](#install-your-dotfiles) (bring your
  dotfiles). Plus common command line utilities like git, less, nano (tiny), jq,
  [ssh](#install-your-ssh-keys), curl, bash completion and others.
- Support for [apt cache](https://github.com/gnzsnz/apt-cacher-ng). If you have
  other Linux boxes using it can leverage your package cache.
- It does not include a built environment. If you need to install a package
  that does not provide wheels you can build your wheels, as explained
  in [common tasks](#build-wheels-outside-the-container)

## Quick Start

To use `jupyter-quant` as a [pypi package](https://pypi.org/project/jupyter-quant/)
see [install quant package](#install-jupyter-quant-package).

Create a `docker-compose.yml` file with this content

```yml
services:
  jupyter-quant:
    image: gnzsnz/jupyter-quant:${IMAGE_VERSION}
    environment:
      APT_PROXY: ${APT_PROXY:-}
      BYODF: ${BYODF:-}
      SSH_KEYDIR: ${SSH_KEYDIR:-}
      START_SCRIPTS: ${START_SCRIPTS:-}
      TZ: ${QUANT_TZ:-}
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

1. `quant_data` - volume for ~/.local folder. It contains caches and all Python
   packages. This enables to install additional packages through pip.
2. `quant_conf` - volume for ~/.config, all config goes here. This includes
   jupyter, ipython, matplotlib, etc
3. Bind mount (but you could use a named volume) - volume for all notebooks,
   under `~/Notebooks`.

This allows to have ephemeral containers and to keep your notebooks (3), your
config (2) and your additional packages (1). Eventually, you would need to
update the image, in this case, your notebooks (3) can move without issues,
your config (2) should still work but no warranty and your packages in
`quant_data` could still be used but you should refresh it with a new image.
Eventually, you would need to refresh (1) and less frequently (2)

## Common tasks

### Get running server URL

```bash
docker exec -it jupyterquant jupyter-server list
Currently running servers:
http://40798f7a604a:8888/?token=
ebf9e870d2aa0ed877590eb83b4d3bbbdfbd55467422a167 :: /home/gordon/Notebooks
```

or

```bash
docker logs -t jupyter-quant 2>&1 | grep '127.0.0.1:8888/lab?token='
```

You will need to change hostname (40798f7a604a in this case) or 127.0.0.1 by
your docker host ip.

### Show jupyter config

```bash
docker exec -it jupyter-quant jupyter-server --show-config
```

### Set password

```bash
docker exec -it jupyter-quant jupyter-server password
```

### Get command line help

```bash
docker exec -it jupyter-quant jupyter-server --help
docker exec -it jupyter-quant jupyter-lab --help
```

### List installed packages

```bash
docker exec -it jupyter-quant pip list
# outdated packages
docker exec -it jupyter-quant pip list -o
```

### Pass parameters to jupyter-lab

```bash
docker run -it --rm gnzsnz/jupyter-quant --core-mode
docker run -it --rm gnzsnz/jupyter-quant --show-config-json
```

### Run a command in the container

```bash
docker run -it --rm gnzsnz/jupyter-quant bash
```

### Build wheels outside the container

Build wheels outside the container and import wheels into the container

```bash
# make sure python version match .env-dist
docker run -it --rm -v $PWD/wheels:/wheels python:3.11 bash
pip wheel --no-cache-dir --wheel-dir /wheels numpy
```

This will build wheels for numpy (or any other package that you need) and save
the file in `$PWD/wheels`. Then you can copy the wheels in your notebook mount
(3 above) and install it within the container. You can even drag and drop into
Jupyter.

### Install your dotfiles

`git clone` your dotfiles to `Notebook/etc/dotfiles`, set environment variable
`BYODF=/home/gordon/Notebook/etc/dotfiles` in your `docker-compose.yml` When
the container starts up stow will create links like `/home/gordon/.bashrc`

### Install your SSH keys

You need to define environment variable `SSH_KEY_DIR` which should point to a
location with your keys. The suggested place is
`SSH_KEYDIR=/home/gordon/Notebooks/etc/ssh`, make sure the director has the
right permissions. Something like `chmod 700 Notebooks/etc/ssh` should work.

The `entrypoint.sh` script will create a symbolic link pointing to
`$SSH_KEYDIR` on `/home/gordon/.ssh`.

Within Jupyter's terminal, you can then:

```shell
# start agent
eval $(ssh-agent)
# add keys to agent
ssh-add
# open a tunnel
ssh -fNL 4001:localhost:4001 gordon@bastion-ssh
```

### Run scripts at start up

If you define `START_SCRIPTS` env variable with a path, all scripts on that
directory will be executed at start up. The sample `.env-dist` file contains
a commented line with `START_SCRIPTS=/home/gordon/Notebooks/etc/start_scripts`
as an example and recommended location.

Files should have a `.sh` suffix and should run under `bash`. in directory
[start_scripts](https://github.com/quantbelt/jupyter-quant/tree/master/start_scripts)
you will find example scripts to load ssh keys and install python packages.

### Install jupyter-quant package

Jupyter-quant is available as a package in [pypi](https://pypi.org/project/jupyter-quant/).
It's a meta-package that pulls all dependencies in it's highest possible version.

Dependencies:

- hdf5 (see below)
- TA-lib see [instructions](https://pypi.org/project/TA-Lib/)

```bash
# ubuntu/debian, see install instructions above for TA-lib
sudo apt-get install libhdf5-dev

# osx
brew install hdf5 ta-lib
```

Install [pypi package](https://pypi.org/project/jupyter-quant/).

```bash
pip install -U jupyter-quant
```

Additional options supported are

```bash
pip install -U jupyter-quant[bayes] # to install pymc & arviz/graphviz

pip install -U jupyter-quant[sk-util] # to install skfolio & sktime
```

`jupyter-quant` it's a meta-package that pins all it's dependencies versions.
If you need/want to upgrade a dependency you can uninstall `jupyter-quant`,
although this can break interdependencies. Or install from git, where it's
updated regularly.

```bash
# git install
pip install -U git+https://github.com/quantbelt/jupyter-quant.git
```
