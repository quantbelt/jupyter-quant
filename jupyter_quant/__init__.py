"""Jupyter quant, a dockerized quant research environment."""

import re
from importlib.metadata import version

__version__ = version("cboe_toolz")

# Extract only the numeric parts for __version_info__
__version_info__ = tuple(
    [int(x) for x in re.findall(r"\d+", __version__.split("+")[0])]
)
