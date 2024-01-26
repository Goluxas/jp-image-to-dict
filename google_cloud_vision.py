from google.cloud import vision

from pathlib import Path


def get_text(image_path: Path):
    client = vision.ImageAnnotatorClient()

    with open(image_path, "rb") as imagefile:
        image = vision.Image(content=imagefile.read())

    response: vision.AnnotateImageResponse = client.text_detection(image=image)

    # Response contains parsed text two ways

    # A list of all text units and their bounding boxes
    texts = response.text_annotations

    # The full parsed text
    print(texts[0].description)

    # Following units are grouped by the engine's best guess.
    # In the manga page sample, it does a pretty good job of following page and speech bubble flow
    # but furigana is pulled to its own unit preceding the normal-size text.
    texts[1].description

    # Bounding box of the text is also available
    # ie. Bounds: (x, y), (x, y), (x, y), (x, y)
    print(
        "Bounds: "
        + ", ".join(
            f"({vertex.x}, {vertex.y})" for vertex in texts[0].bounding_poly.vertices
        )
    )


# Run this script to see the output of the main text captured using the sample manga page
if __name__ == "__main__":
    image = Path("test_images/DLRAW.NET-0125.jpg")

    get_text(image)
