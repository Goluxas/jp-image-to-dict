import pytest
from ..ocr_engines.mangaocr import get_text_from_file


def test_get_text_from_file():
    # Create a mock file-like object
    test_file = open("test.png", "rb")

    # Call the function with the mock file
    result = get_text_from_file(test_file)

    # Assert the result is as expected
    assert result == "あの悪魔の．．．私の手柄を．．．"
