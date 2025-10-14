import sys
import time

import psutil


def rss_tree(pid):
    parent = psutil.Process(pid)
    procs = [parent] + parent.children(recursive=True)
    return sum(p.memory_info().rss for p in procs if p.is_running())


def vms_tree(pid):
    parent = psutil.Process(pid)
    procs = [parent] + parent.children(recursive=True)
    return sum(p.memory_info().vms for p in procs if p.is_running())


def shr_tree(pid):
    parent = psutil.Process(pid)
    procs = [parent] + parent.children(recursive=True)
    return sum(p.memory_info().shared for p in procs if p.is_running())


pid = int(sys.argv[1])
peak_rss = peak_vms = peak_shr = 0
try:
    while True:
        rss = rss_tree(pid) // 1024 // 1024
        vms = vms_tree(pid) // 1024 // 1024
        shr = shr_tree(pid) // 1024 // 1024
        peak_rss = max(peak_rss, rss)
        peak_vms = max(peak_vms, vms)
        peak_shr = max(peak_shr, shr)
        print(
            f"RSS: {rss} | {peak_rss} MB , VMS: {vms} | {peak_vms} MB, SHR: {shr} | {peak_shr} MB "
        )
        time.sleep(1)
except:
    print(f"Peak total RSS: {peak_rss} MB")
    print(f"Peak total VMS: {peak_vms} MB")
    print(f"Peak total SHR: {peak_shr} MB")
