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

import pandas as pd


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
    """This is a multiline comment of the code."""
    return df.query("x ** 2 + y ** 2 > @threshold ** 2")


def save_data(df: pd.DataFrame) -> None:
    """Save the DataFrame

    This is the saving function

    Parameters
    ----------
    df : pd.DataFrame
        The DataFrame to save

    """

    print("Saving the DataFrame")
    print(df)


def main() -> None:
    """This is the main function.

    This is the docstring


    """
    load_data().pipe(transform_data).pipe(filter_data, threshold=5).pipe(save_data)
