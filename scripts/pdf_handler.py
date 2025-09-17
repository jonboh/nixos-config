import mimetypes
import re
import subprocess
import sys
import time
import urllib.parse
from typing import Optional

# NOTE: this script needs poppler_utils, so that pdfinfo is available in PATH


def get_pdf_named_dest_page(file_path, named_dest):
    # Using pdfinfo to get the page number for named destination
    cmd = ["pdfinfo", "-dests", file_path]
    process = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    dests_output = process.stdout.decode()
    # Search for the named destination in the pdfinfo output
    dest_match = re.search(
        rf"\s*(\d+) \[ XYZ\s+\d+\s+(\d+).*\"{named_dest}\"", dests_output
    )
    if dest_match:
        page = int(dest_match.group(1))
        y_offset = int(dest_match.group(2))
        cmd = ["pdfinfo", file_path]
        process = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        info_output = process.stdout.decode()
        pagesize_match = re.search(r"Page size:\s+\d+\s+x\s+(\d+)", info_output)
        pages_match = re.search(r"Pages:\s+(\d+)", info_output)
        if pagesize_match and pages_match:
            page_height = int(pagesize_match.group(1))
            pages = int(pages_match.group(1))
            link_pos_y = (page_height - y_offset) / page_height / (pages + 1) + page / (
                pages + 1
            )
        else:
            page_height = None
            link_pos_y = None
        return page, link_pos_y
    else:
        return None, None


def run_zathura_with_position(
    file_path, page: Optional[int], pos_x: Optional[float], pos_y: Optional[float]
):
    if page:
        process = subprocess.Popen(
            [
                "zathura",
                "-P",
                str(page),
                file_path,
            ]
        )
    else:
        process = subprocess.Popen(
            [
                "zathura",
                file_path,
            ]
        )
    if pos_y:
        if pos_x is None:
            pos_x = 0.5

        # TODO: retry until succeed instead of sleeping
        pid = process.pid
        cmd = [
            "dbus-send",
            "--type=method_call",
            "--print-reply",
            f"--dest=org.pwmt.zathura.PID-{pid}",
            "/org/pwmt/zathura",
            "org.pwmt.zathura.SetPosition",
            f"double:{pos_x}",
            f"double:{pos_y}",
        ]
        max_retries = 5
        for attempt in range(max_retries):
            try:
                result = subprocess.run(cmd, check=True)
                if result.returncode == 0:
                    break
            except subprocess.CalledProcessError:
                if attempt < max_retries - 1:
                    time.sleep(0.25)  # Wait a bit before retrying
                else:
                    raise  # Re-raise the exception if out of attempts


def main(uri):
    # Decode the URI and parse it
    parsed_uri = urllib.parse.urlparse(uri)
    file_path = urllib.parse.unquote(parsed_uri.path)
    fragment = parsed_uri.fragment

    mime_type, _ = mimetypes.guess_type(file_path, strict=False)

    # If it's a PDF file and there is a nameddest, attempt to handle that
    if mime_type == "application/pdf":
        # Check for nameddest in the fragment part of the URI, typical to PDFs
        if fragment.startswith("nameddest="):
            url_nameddest = fragment.split("nameddest=")[1]
            # check if the named destination is actuall an absolute postition
            position_match = re.search(r"pos_x%3D(.*)%26pos_y%3D(.*)", url_nameddest)
            if position_match:
                pos_x = float(position_match.group(1))
                pos_y = float(position_match.group(2))
                run_zathura_with_position(file_path, None, pos_x, pos_y)
            else:
                page, pos_y = get_pdf_named_dest_page(file_path, url_nameddest)
                if not page:
                    print(f"Named destination '{url_nameddest}' not found in PDF.")
                    sys.exit(1)
                else:
                    run_zathura_with_position(file_path, page, None, pos_y)
        elif fragment.startswith("page="):
            page = fragment.split("page=")[1]
            subprocess.run(["zathura", "-P", str(page), file_path])
        else:
            subprocess.run(["zathura", file_path])
    else:
        # Use xdg-open to open the file with the default application for its MIME type
        subprocess.run(["xdg-open", file_path])


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 open_file_with_metadata.py <file-uri>")
        sys.exit(1)

    main(sys.argv[1])
