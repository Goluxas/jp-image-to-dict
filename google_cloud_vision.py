from google.cloud import vision
from PIL import ImageGrab

from pathlib import Path
from io import BytesIO


def get_text(image: vision.Image):
    """
    Using Google Cloud Vision API, find the full text in the image and its bounding box.

    Currently prints to stdout.
    """

    client = vision.ImageAnnotatorClient()

    response: vision.AnnotateImageResponse = client.text_detection(
        image=image, image_context={"language_hints": ["ja"]}
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

    # Following units are grouped by the engine's best guess.
    # In the manga page sample, it does a pretty good job of following page and speech bubble flow
    # but furigana is pulled to its own unit preceding the normal-size text.
    texts[1].description

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


def vision_image_from_file(image_path: Path) -> vision.Image:
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


# Main function included only for manual testing purposes
if __name__ == "__main__":
    # Vision Image from path
    # image_path = Path("test_images/DLRAW.NET-0125.jpg")
    # image = vision_image_from_file(image_path)

    # Vision Image from clipboard (must be in clipboard already when program is run)
    image = vision_image_from_clipboard()

    get_text(image)
