import PyPDF2
try:
    r = PyPDF2.PdfReader('202211070324141640008छात्रपरियोजनाकेलिएप्रारूप.pdf')
    text = '\n'.join(p.extract_text() for p in r.pages)
    with open('pdf_content.txt', 'w', encoding='utf-8') as f:
        f.write(text)
except Exception as e:
    with open('pdf_content.txt', 'w', encoding='utf-8') as f:
        f.write("Error: " + str(e))
