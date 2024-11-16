# Japanese OCR to Dictionary Application

(Needs a catchier name.)

This is a full stack application that aims to allow users to take screenshots or photos of Japanese text and automatically convert that into an interactive dictionary lookup, similar to what you see on Lorenzi's Jisho. An example of the target output [here.](https://jisho.hlorenzi.com/search/%E3%81%8A%E5%89%8D%E3%81%AE%E6%AC%A1%E3%81%AE%E3%82%BB%E3%83%AA%E3%83%95%E3%81%AF%E3%80%8C%E3%81%82%E3%81%A3%EF%BC%81%E5%87%84%E3%81%84%E3%81%A7%E3%81%99%E3%81%AD%E3%80%8D%E3%81%A8%E8%A8%80%E3%81%86%EF%BC%81/3)

## Technologies in Use

- Back End
  - Python
  - FastAPI
  - ~~Google Vision API for OCR~~
  - MangaOCR
- Front End
  - Flutter, targeting web browser

## Feature Roadmap

- [x] Allow user to paste or upload images.
- [x] Parse text out of screenshots
- [x] Feed text into an available online dictionary such as Lorenzi's Jisho.
  - This was replaced with manual copy and paste of the parsed text. See reason in [Footnotes](#footnotes).
- [ ] Implement a Japanese morphological analyzer and break up input into dictionary words
- [ ] Allow user to browse words in front end, similar to Lorenzi's Jisho.

## Feature Wishlist

See [GitHub issues tagged `enhancement`.](https://github.com/Goluxas/jp-image-to-dict/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

## Usage

### Backend

In the root project directory, `uvicorn backend.main:app`. (If not in the root directory, relative imports don't work.)

### Frontend

Deployed to GitHub Pages at https://goluxas.github.io/jp-image-to-dict/

## Footnotes

### Why do I need to manually copy and paste the parsed text into the embedded dictionary?

Screenshots and pictures can often contain a lot of text. I discovered that long strings were causing the embedded dictionary to timeout, most likely due to long processing time on their morphological analyzer. This is bad for the user experience on my end as well as for the hit on the computation power of the sites that I'm using as the embed.

Since sending the parsed text to a third party dictionary was only ever meant to accelerate prototyping anyway, I chose to make my app's UX a little worse by requiring that copy/paste manual step instead.

This is also a preview that I'll need some way to limit how much text hits my own morphological analyzer when I implement it.
