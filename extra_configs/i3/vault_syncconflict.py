import json
import subprocess


def get_vault_conflicts():
    try:
        ls_process = subprocess.Popen(
            ["ls", "/home/jonboh/vault"], stdout=subprocess.PIPE
        )
        rg_process = subprocess.Popen(
            ["rg", "sync-conflict"], stdin=ls_process.stdout, stdout=subprocess.PIPE
        )
        ls_process.stdout.close()  # Allow ls_process to receive a SIGPIPE if rg_process exits.
        end_of_pipe = subprocess.Popen(
            ["wc", "-l"], stdin=rg_process.stdout, stdout=subprocess.PIPE
        )
        rg_process.stdout.close()  # Allow rg_process to receive a SIGPIPE if wc exits.
        output = end_of_pipe.communicate()[0]
        lines_count = output.decode("utf-8").strip()
        return int(lines_count)
    except Exception as e:
        print(f"An error while getting vault sync conflicts: {e}")


if __name__ == "__main__":
    empty = json.dumps({"text": "", "state": "Idle"})
    try:
        conflicts = get_vault_conflicts()
        if conflicts > 0:
            message = {"text": f"VAULT CONFLICT {conflicts}", "state": "Warning"}
            print(json.dumps(message))
        else:
            print(empty)
    except:
        print(empty)
