# Jupyter Quant

A dockerized Jupyter quant research enviroment.

## Highlights

- Designed for [ephemeral](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#create-ephemeral-containers) containers. Relevant data for your enviroment will survive your container.
- Optimized for size, it's a 2GB image vs 4GB for jupyter/scipy-notebook
- Includes all major python packages for data and timeseries analysis, see [requirements](https://github.com/gnzsnz/jupyter-quant/blob/master/requirements.txt)
- Includes jedi language server
- It does NOT include conda/mamba. All packages are installed wit pip under ~/.local/lib/python
- Includes Cython, Numba, bottleneck and numexpr to speed up things
- The usual suspects are included, numpy, pandas, sci-py, scikit-learn
- Includes tools for quant analysis, statsmodels, pymc, arch, py_vollib, zipline-reloaded, PyPortfolioOpt, etc.
- ib_insync for Interactive Broker connectivity. Works well with [IB Gateway](https://github.com/gnzsnz/ib-gateway-docker)
- sudo, so you can install new packages if needed
- bash and stow, so you can BYODF (bring your own dot files)
- Support for [apt cache](https://github.com/gnzsnz/apt-cacher-ng). If you have other linux boxes using you can leverage your cache. apt cache support major linux distributions not only debian/ubuntu.


## Volumes

The image is designed to work with 3 volumes:

1.  `quant_data`` - volume for `~/.local`` folder. It contains caches and all python packages. This enables to add additional packages through pip.
1.  `quant_conf` - volume for `~/.config``, all config goes here. This includes jupyter, ipython, matplotlib, etc
1.  Bind mount (but you could use a named volume) - volume for all notebooks, under `~/Notebooks``.

This allows to have ephemeral containers and to keep your notebooks (3), your config (2) and your additional packages (1). Eventually you would need to update the image, in this case your notebooks (3) can move without issues, your config (2) should still work but no warranty, and your packages could still be used. Eventually you would need to refresh (1) and less frecuently (2)

## Sample docker compose

```yml
version: "3.6"
services:
  jupyter-quant:
    image: gnzsnz/jupyter-quant:${IMAGE_VERSION}
    environment:
      APT_PROXY: ${APT_PROXY:-}
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

## Common tasks

- get running server URL
  
```bash
docker exec -it jupyterquant jupyter-server list
Currently running servers:
http://40798f7a604a:8888/?token=ebf9e870d2aa0ed877590eb83b4d3bbbdfbd55467422a167 :: /home/gordon/Notebooks
```

you will need to change hostname, 40798f7a604a in this case by your docker host ip.

- show jupyter config

```bash
docker exec -it jupyter-quat jupyter-server --show-config
```

- set password

```bash
docker exec -it jupyter-quat jupyter-server password
```

- get help

```bash
docker exec -it jupyter-quat jupyter-server --help
docker exec -it jupyter-quat jupyter-lab --help
```

- get installed packeges

```bash
docker exec -it jupyter-quat pip list
# outdated packages
docker exec -it jupyter-quat pip list -o
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
