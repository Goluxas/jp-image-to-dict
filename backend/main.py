import os
from fastapi import FastAPI, UploadFile, Request
from fastapi.middleware.cors import CORSMiddleware

DEBUG = os.environ.get("IS_DEVELOPMENT", "true") == "true"

app = FastAPI()

# from google_cloud_vision import text_from_image as google_cloud_vision_ocr
# ocr = google_cloud_vision_ocr

from mangaocr import get_text_from_file as mangaocr_ocr

ocr = mangaocr_ocr
"""
The OCR engine to use for processing image files.

Expected interface:
    ocr(file: IO) -> str
"""

# BAD: If the incoming request uses a port, it must be specified.
# But Flutter uses a port range on every request so we need more flexibility.
# origins = ["http://localhost", "https://localhost"]

# BAD: Cannot use wildcards in these origins, use allow_origin_regex instead. (Note the lack of pluriality)
# origins = ["http://localhost:*", "https://localhost:*"]

# Can use both together
# The regex failed even though I checked the CORSMiddleWare source and did the re.compile and fullmatch the same way and it worked
# But adding the explicit domain worked
# origins = ["https://goluxas.github.io"]
# origin_regex = r"https?:\/\/(localhost|goluxas\.github\.io)(:\d{1,5})?"

origins = [
    "https://goluxas.github.io",
    "http://localhost",
    "http://127.0.0.1",
    "http://10.0.2.2",
]

# Localhost with all its ports because Flutter can't seem to make up its mind
origin_regex = r"https?:\/\/(localhost|10\.0\.2\.2)(:\d{1,5})?"


@app.middleware("http")
async def cors_debugging(request: Request, call_next):
    if DEBUG:
        origin = request.headers.get("Origin")
        print(f"{origin=}")

    response = await call_next(request)
    return response


app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_origin_regex=origin_regex,
    # allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

if DEBUG:
    print("Debug Mode ON")


@app.get("/")
async def root():
    return {
        "message": "API is online.\nVisit /docs for usage.",
    }


# want an endpoint to accept png bytes (however that transfers over API)
# and sends back all the information flutter will need
# What is that information?
# For now, just the parsed text.
# TODO: this backend should do the analysis and dictionary lookup and send that as an object too.
@app.post("/ocr/png/")
async def ocr_png(file: UploadFile):
    """
    Sends the file off to the OCR engine and processes the response for frontend use.
    For the time being, that means only the full captured text as a string.
    """
    print("Received OCR Request.")

    captured_text = ocr(file.file)

    return {"captured_text": captured_text}
