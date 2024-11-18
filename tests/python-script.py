# These are some comments at the top of the code
# Another comment
# Yet another comment
# More
"""This is a the module docstring.

This is some text that describes the module.

This is just a test script in order to see how the
(neo)vim plugin renders the code.

Examples
--------
This is an example of how to use the module.

.. code-block:: python

    # Just call the main block
    main()

"""

from dataclasses import dataclass

import pandas as pd
import numpy as np

VALUE = 1  # This is a comment
ANOTHER_VALUE = 2  # which wouldn't be collapsed


# Here is a comment
# More comments

seed = sum(map(ord, "Some random seed"))
rng = np.random.default_rng(seed)

# Here are some comments
# More comments
# Even more comments


@dataclass
class Config:
    """This is the configuration that is used in the script.

    This is a dataclass that contains the configuration

    Attributes
    ----------
    threshold : float
        The threshold to filter the data
    save_file : str
        The file to save the data

    """

    threshold: float
    save_file: str


def load_data() -> pd.DataFrame:
    """Load the data

    This returns a DataFrame

    Returns
    -------
    pd.DataFrame
        The DataFrame with the data

    """
    return pd.DataFrame(
        {
            "x": [1, 2, 3],
            "y": [2, 4, 5],
        }
    )


def transform_data(df: pd.DataFrame) -> pd.DataFrame:
    """This is the processing of the data.

    Parameters
    ----------
    df : pd.DataFrame
        The DataFrame to process

    """
    return df.assign(z=lambda x: x["x"] + x["y"])


def filter_data(df: pd.DataFrame, threshold: float) -> pd.DataFrame:
    """This is the filtering of the data.

    Parameters
    ----------
    df : pd.DataFrame
        The DataFrame to filter
    threshold : float
        The threshold to filter the data

    """
    # This is a comment of the code
    """This is a multiline comment of the code.

    More of the multiline comment

    """
    return df.query("x ** 2 + y ** 2 > @threshold ** 2")


def save_data(df: pd.DataFrame, save_file: str) -> None:
    """Save the DataFrame

    This is the saving function

    Parameters
    ----------
    df : pd.DataFrame
        The DataFrame to save

    """

    print(f"Saving the DataFrame to {save_file}")
    print(df)


def main() -> None:
    """This is the main function.

    This is the docstring

    """
    config = Config(threshold=5, save_file="data.csv")
    load_data().pipe(transform_data).pipe(filter_data, threshold=config.threshold).pipe(
        save_data, save_file=config.save_file
    )


if __name__ == "__main__":
    # Run the main function
    # This is a comment
    main()
