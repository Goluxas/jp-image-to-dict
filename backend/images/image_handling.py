from PIL import Image as PILImage, UnidentifiedImageError
from io import BytesIO
from fastapi import HTTPException


def image_to_png_bytes(image_path: str) -> bytes:
    try:
        with PILImage.open(image_path) as img:
            with BytesIO() as output:
                img.save(output, format="PNG")
                return output.getvalue()

    except UnidentifiedImageError:
        raise HTTPException(
            status_code=422,
            detail="Image file is an unknown format, corrupt, or incomplete.",
        )


def png_bytes_to_pil_image(png_bytes: bytes) -> PILImage:
    return PILImage.open(BytesIO(png_bytes))
