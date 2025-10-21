"""Import a local startup file."""

try:
    from startup import *  # noqa: F401
except ImportError:
    pass
