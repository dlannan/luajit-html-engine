import zipfile

# Define the test files with filenames and contents
test_files = {
    "01-simple-document.html": """<!DOCTYPE html>
<html>
  <head>
    <title>Simple Document</title>
  </head>
  <body>
    Hello, world!
  </body>
</html>""",

    "02-inline-vs-block.html": """<!DOCTYPE html>
<html><body>
  <div>This is <span>inline</span> text and also <b>bold</b> + <i>italic</i> parts.</div>
</body></html>""",

    "03-attributes-quoting.html": """<!DOCTYPE html>
<html><body>
  <img src="image.png" alt='An "image"' title=SimpleTitle>
  <a href=https://example.com>Example Link</a>
</body></html>""",

    "04-classes-and-ids.html": """<!DOCTYPE html>
<html><head>
  <style>
    #header { color: blue; }
    .highlight { background-color: yellow; }
    p.small { font-size: 12px;}
  </style>
</head><body>
  <div id="header">Header</div>
  <p class="highlight small">Some text</p>
  <p class="small">More text</p>
</body></html>""",

    "05-css-basic-style.html": """<!DOCTYPE html>
<html><head>
  <style>
    body { background-color: #f0f0f0; }
    h1 { color: red; margin: 0; padding: 5px; }
    p { color: black; font-size: 14px; }
  </style>
</head><body>
  <h1>Heading One</h1>
  <p>Paragraph text here.</p>
</body></html>""",

    "06-lists-nesting.html": """<!DOCTYPE html>
<html><body>
  <ul>
    <li>Item 1</li>
    <li>Item 2
      <ol>
        <li>Subitem A</li>
        <li>Subitem B</li>
      </ol>
    </li>
  </ul>
</body></html>""",

    "07-whitespace-handling.html": """<!DOCTYPE html>
<html><body>
  <div>
    Line1
    Line2
        Lots   of   spaces
  </div>
</body></html>""",

    "08-forms-basic.html": """<!DOCTYPE html>
<html><body>
  <form action="/submit">
    <label for="name">Name:</label>
    <input type="text" id="name" name="name" value="Default">
    <button type="submit">Submit</button>
  </form>
</body></html>""",

    "09-images-links.html": """<!DOCTYPE html>
<html><body>
  <a href="https://example.com">Visit Example</a>
  <img src="logo.png" alt="Logo">
</body></html>""",

    "10-text-formatting.html": """<!DOCTYPE html>
<html><body>
  <p>This is <b>bold</b>, <strong>strong</strong>, <i>italic</i>, <em>emphasis</em>, <u>underline</u>.</p>
</body></html>"""
}

# Create the ZIP archive
with zipfile.ZipFile("basic_html_tests.zip", "w") as zipf:
    for filename, content in test_files.items():
        zipf.writestr(filename, content)

print("ZIP file 'basic_html_tests.zip' created.")
