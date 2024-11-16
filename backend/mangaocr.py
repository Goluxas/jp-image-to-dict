import manga_ocr
from typing import IO
from .image_handling import image_to_png_bytes, png_bytes_to_pil_image

ocr = manga_ocr.MangaOcr()

text = ocr("test.png")


def get_text_from_file(file: IO) -> str:
    png_bytes = image_to_png_bytes(file)
    pil_image = png_bytes_to_pil_image(png_bytes)
    return ocr(pil_image)
