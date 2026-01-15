import mimetypes
import subprocess
import sys
import urllib.parse


def main(uri):
    # Decode the URI and parse it
    parsed_uri = urllib.parse.urlparse(uri)
    file_path = urllib.parse.unquote(parsed_uri.path)
    fragment = parsed_uri.fragment

    mime_type, _ = mimetypes.guess_type(file_path, strict=False)

    # If it's a PDF file, handle fragments for okular
    if mime_type == "application/pdf":
        if fragment.startswith("nameddest="):
            # Extract named destination and let okular handle it natively
            url_nameddest = fragment.split("nameddest=")[1]
            # URL decode the named destination
            named_dest = urllib.parse.unquote(url_nameddest)
            # Construct the okular URL format: file#nameddest
            okular_uri = f"{file_path}#{named_dest}"
            subprocess.run(["okular", okular_uri])
        elif fragment.startswith("page="):
            page = fragment.split("page=")[1]
            subprocess.run(["okular", "-p", str(page), file_path])
        elif fragment:
            # For any other fragment, try passing it as a named destination
            okular_uri = f"{file_path}#{fragment}"
            subprocess.run(["okular", okular_uri])
        else:
            subprocess.run(["okular", file_path])
    else:
        # Use xdg-open to open the file with the default application for its MIME type
        subprocess.run(["xdg-open", file_path])


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 pdf_handler.py <file-uri>")
        sys.exit(1)

    main(sys.argv[1])
