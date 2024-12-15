import pytest


def sample(x: int = 1):
    return x


def test_default():
    """This is a sample test."""

    assert sample() == 1


@pytest.mark.parametrize("first_value", [1, 2, 3])
@pytest.mark.parametrize(
    "value",
    [
        1,
        2,
        3,
        # This is some comment
    ],
    ids=["one", "two", "three"],
)
def test_another_test(first_value: int, value: int):
    """This is another sample test."""

    assert sample(x=value) * first_value == value * first_value
