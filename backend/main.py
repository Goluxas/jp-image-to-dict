from typing import Annotated
from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import UnidentifiedImageError

from google_cloud_vision import vision_image_from_bytes, get_text

app = FastAPI()

# BAD: If the incoming request uses a port, it must be specified.
# But Flutter uses a port range on every request so we need more flexibility.
# origins = ["http://localhost", "https://localhost"]

# BAD: Cannot use wildcards in these origins, use allow_origin_regex instead. (Note the lack of pluriality)
# origins = ["http://localhost:*", "https://localhost:*"]

origin_regex = r"http://localhost:\d{1,5}"

app.add_middleware(
    CORSMiddleware,
    # allow_origins=origins,
    allow_origin_regex=origin_regex,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    return {"message": "Hello World"}


# want an endpoint to accept png bytes (however that transfers over API)
# and sends back all the information flutter will need
# What is that information?
# For now, just the parsed text.
# Later, this backend should do the analysis and dictionary lookup and send that as an object too.
# Also need a way to communicate errors to Flutter
@app.post("/ocr/png/")
async def ocr_png(file: Annotated[bytes, File()]):
    # NOTE: MIGHT want to switch to UploadFile, which spools to a file on disk if memory gets too full
    # Safer for high volume requests. Not necessary for my personal use.
    try:
        vimage = vision_image_from_bytes(file)
    except UnidentifiedImageError:
        # TODO: What's the FastAPI-ic way to return an error message here?
        return {
            "error": {
                "code": 1,
                "description": "Image file is an unknown format, corrupt, or incomplete.",
            }
        }

    captured_text = get_text(vimage)

    return {"captured_text": captured_text}
