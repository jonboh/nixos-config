import subprocess
import sys

if len(sys.argv) != 2:
    print("Usage: git-init-tars ARGUMENT")
    sys.exit(1)

reponame = sys.argv[1]

cmd = f'ssh git@tars.lan "mkdir {reponame}.git && cd {reponame}.git && git init -b main --bare"'
result = subprocess.run(cmd, shell=True)
if result.returncode != 0:
    print("Failed to create remote bare repository")
    sys.exit(result.returncode)

confirm_origin = (
    input(
        f"Do you want to add the 'origin' remote (git@tars.lan:{reponame}.git)? [y/N]: "
    )
    .strip()
    .lower()
)
if confirm_origin == "y":
    cmd2 = f"git remote add origin git@tars.lan:{reponame}.git"
    result2 = subprocess.run(cmd2, shell=True)
    if result2.returncode != 0:
        print("Failed to add origin git remote")
else:
    print("Skipping adding 'origin' remote.")

confirm_github = (
    input(
        f"Do you want to add the 'github' remote (git@github.com:jonboh/{reponame}.git)? [y/N]: "
    )
    .strip()
    .lower()
)
if confirm_github == "y":
    cmd2 = f"git remote add github git@github.com:jonboh/{reponame}.git"
    result2 = subprocess.run(cmd2, shell=True)
    if result2.returncode != 0:
        print("Failed to add github git remote")
else:
    print("Skipping adding 'github' remote.")
