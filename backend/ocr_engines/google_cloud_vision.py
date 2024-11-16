from google.cloud import vision
from PIL import Image as PILImage, ImageGrab, UnidentifiedImageError
from pathlib import Path
from io import BytesIO
import webbrowser
from fastapi import HTTPException
from typing import IO


def text_from_image(file: IO) -> str:
    try:
        # OPTIMIZATION: If the UploadFile is already png then this unnecessarily un and recompresses it.
        vimage = vision_image_from_file(file)
    except UnidentifiedImageError:
        raise HTTPException(
            status_code=422,
            detail="Image file is an unknown format, corrupt, or incomplete.",
        )

    print("Awaiting response from Vision API...")
    captured_text = get_text(vimage)
    return captured_text


def get_text(image: vision.Image) -> str:
    """
    Using Google Cloud Vision API, find the full text in the image and its bounding box.

    Currently prints to stdout and returns the text as string.
    """

    client = vision.ImageAnnotatorClient()

    response: vision.AnnotateImageResponse = client.text_detection(
        image=image,
        image_context={"language_hints": ["ja"]},
    )

    # If there are errors, report and exit
    if response.error.code != 0:
        print(f"Cloud Vision call encountered error:")
        print(response.error)
        return

    # Response contains parsed text two ways

    # A list of all text units and their bounding boxes
    texts = response.text_annotations

    # The full parsed text in index 0
    print(texts[0].description)

    # Units are grouped by the engine's best guess in indices 1+.
    # In the manga page sample, it does a pretty good job of following page and speech bubble flow
    # but furigana is pulled to its own unit preceding the normal-size text.
    # texts[1].description

    # Alternatively, the text is also in
    # text = response.full_text_annotation

    # Bounding box of the text is also available
    # ie. Bounds: (x, y), (x, y), (x, y), (x, y)
    print(
        "Bounds: "
        + ", ".join(
            f"({vertex.x}, {vertex.y})" for vertex in texts[0].bounding_poly.vertices
        )
    )

    return texts[0].description


def vision_image_from_path(image_path: Path) -> vision.Image:
    """
    Read in an image file and convert to a vision.Image ready for the Cloud Vision API
    """

    with open(image_path, "rb") as imagefile:
        image = vision.Image(content=imagefile.read())

    return image


def vision_image_from_clipboard() -> vision.Image:
    """
    Take the image in the clipboard and convert it for Cloud Vision API use
    """

    # Using Pillow, grab the image from the clipboard
    img = ImageGrab.grabclipboard()

    # Image could be saved with
    # img.save(file_path)
    # but we're just passing it through

    # THE FOLLOWING DOES NOT WORK
    # Bytes of image
    # bytes = img.tobytes()
    # These bytes are not a recognized format for Vision. Probably an internal format for PIL

    # To get the bytes as a compressed format that Cloud Vision can recognize, "save" them to a BytesIO stream
    png_bytes = BytesIO()
    # Specify the format since it can't be inferred from filename
    img.save(png_bytes, "png")

    return vision.Image(content=png_bytes.getvalue())

    # THE FOLLOWING DOES NOT WORK
    # Seems like the Tkinter clipboard is limited to text
    # Uses an empty Tkinter widget to pull from clipboard
    # A bit of a hack, but the other way uses pywin32, a 3rd party library that is obviously not cross-platform
    # return Tk().clipboard_get()


def vision_image_from_bytes(input_bytes: bytes) -> vision.Image:
    """
    Attempts to convert the input file to a PNG (for compression) then to a Vision API Image.

    By using PIL's open we can support many image formats and use it to convert to PNG. Windows screenshots are
    stored as PNG by default, I think, but can't rely on that. No idea what other OS's do. So this convers some
    bases.
    """
    input = BytesIO(input_bytes)

    # TODO: This can raise PIL.UnidentifiedImageError if the file is an unknown type, incomplete or corrupt
    # Do we handle that here or trickle up to the caller?
    image = PILImage.open(input)

    output = BytesIO()
    image.save(output, "png")

    return vision.Image(content=output.getvalue())


def vision_image_from_file(fp) -> vision.Image:
    """
    Reads a file-like object into a PNG-compressed Vision Image.
    """
    image = PILImage.open(fp)
    png_bytes = BytesIO()
    image.save(png_bytes, "png")

    return vision.Image(content=png_bytes.getvalue())


def sanitize(text: str) -> str:
    """
    Removes newlines and other breaking characters from the string to prep it for URL injection
    TODO: Probably make it urlsafe encoded
    """
    return text.replace("\n", "")


def send_text_to_lorenzis_jisho(text: str):
    """
    Open Lorenzi's Jisho (a good online Japanese dictionary) with the given text.

    This is a hack solution; I eventually want to integrate something like Lorenzi's sentence analysis
    into the app itself, as well as dictionary lookups.
    """

    text = sanitize(text)
    LORENZI_SEARCH_URL = "https://jisho.hlorenzi.com/search/%s"

    search_url = LORENZI_SEARCH_URL % text

    webbrowser.open(search_url, new=2, autoraise=True)


def send_text_to_deepl(text: str):
    """
    For fun, trying out sending the text to DeepL for automatic translation
    """

    text = sanitize(text)
    DEEPL_TRANSLATE_URL = "https://www.deepl.com/en/translator#ja/en/%s"

    translate_url = DEEPL_TRANSLATE_URL % text

    webbrowser.open(translate_url, new=2, autoraise=True)


# Main function included only for manual testing purposes
if __name__ == "__main__":
    from argparse import ArgumentParser

    parser = ArgumentParser()
    parser.add_argument("-t", "--translate", action="store_true")

    args = parser.parse_args()

    # Vision Image from path
    # image_path = Path("test_images/DLRAW.NET-0125.jpg")
    # image = vision_image_from_file(image_path)

    # Vision Image from clipboard (must be in clipboard already when program is run)
    image = vision_image_from_clipboard()

    image_text = get_text(image)
    if args.translate:
        send_text_to_deepl(image_text)
    else:
        send_text_to_lorenzis_jisho(image_text)
