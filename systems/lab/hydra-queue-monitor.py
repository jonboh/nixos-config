#!/usr/bin/env python3

import json
import subprocess
import sys
import urllib.request
import urllib.error
import os


def get_queue_status():
    """Fetch the queue runner status from Hydra."""
    try:
        request = urllib.request.Request(
            "https://hydra.jonboh.dev/queue_runner_status",
            headers={"Accept": "application/json"}
        )
        with urllib.request.urlopen(request) as response:
            data = json.loads(response.read().decode())
            return data
    except urllib.error.URLError as e:
        print(f"Error fetching queue status: {e}", file=sys.stderr)
        return None
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON response: {e}", file=sys.stderr)
        return None


def should_restart_queue_runner(status):
    """
    Determine if the queue runner should be restarted based on the status.
    
    Returns True if:
    - There are >0 jobs queued and 0 jobs running, OR
    - There are 0 jobs queued and 0 jobs running (for declarative jobsets)
    """
    if not status:
        return False
    
    jobs_queued = status.get("nrQueuedBuilds", 0)
    jobs_running = status.get("nrStepsBuilding", 0)
    
    # Case 1: Jobs are queued but none are running
    if jobs_queued > 0 and jobs_running == 0:
        print(f"Found {jobs_queued} queued jobs with 0 running jobs - restart needed")
        return True
    
    # Case 2: No jobs queued and no jobs running (declarative jobsets case)
    if jobs_queued == 0 and jobs_running == 0:
        print(f"Found 0 queued and 0 running jobs (declarative jobsets) - restart needed")
        return True
    
    print(f"Queue status normal: {jobs_queued} queued, {jobs_running} running")
    return False


def restart_queue_runner():
    """Restart the hydra-queue-runner service."""
    # Check for dry run mode
    if os.getenv("DRY_RUN"):
        print("DRY_RUN mode: Would restart hydra-queue-runner service")
        return True
        
    try:
        subprocess.run(
            ["systemctl", "restart", "hydra-queue-runner"],
            check=True,
            capture_output=True,
            text=True
        )
        print("Successfully restarted hydra-queue-runner")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error restarting hydra-queue-runner: {e}", file=sys.stderr)
        print(f"stderr: {e.stderr}", file=sys.stderr)
        return False


def main():
    """Main monitoring logic."""
    print("Checking Hydra queue runner status...")
    
    status = get_queue_status()
    if not status:
        print("Failed to get queue status, exiting", file=sys.stderr)
        sys.exit(1)
    
    if should_restart_queue_runner(status):
        if restart_queue_runner():
            sys.exit(0)
        else:
            sys.exit(1)
    else:
        print("No restart needed")
        sys.exit(0)


if __name__ == "__main__":
    main()