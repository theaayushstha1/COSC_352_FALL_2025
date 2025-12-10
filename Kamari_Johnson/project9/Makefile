PDF ?= data/AttachmentE.Transformation_Morgan_2030-1.pdf
TXT ?= data/document.txt
QUERY ?= leadership innovation
N ?= 3

extract:
	python3 pdf_to_text.py $(PDF) $(TXT)

search-mojo:
	mojo build pdf_searcher.mojo
	python3 search_driver.py "$(QUERY)" $(TXT) $(N)

bench-scalar:
	MOJO_SIMD=0 mojo build pdf_searcher.mojo
	/usr/bin/time -f "%E %M" python3 search_driver.py "$(QUERY)" $(TXT) $(N)

bench-simd:
	MOJO_SIMD=1 mojo build pdf_searcher.mojo
	/usr/bin/time -f "%E %M" python3 search_driver.py "$(QUERY)" $(TXT) $(N)