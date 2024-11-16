import pytest
from ..ocr_engines.mangaocr import get_text_from_file
from pathlib import Path


def test_get_text_from_file():
    # Create a mock file-like object
    test_file = open(Path(__file__).parent / "test.png", "rb")

    # Call the function with the mock file
    result = get_text_from_file(test_file)

    # Assert the result is as expected
    assert result == "あの悪魔の．．．私の手柄を．．．"
