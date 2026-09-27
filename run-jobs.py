from sys import argv, exit
from pathlib import Path
from subprocess import Popen, PIPE, STDOUT
from concurrent.futures import ThreadPoolExecutor

jobs = [l.split('|') for l in filter(lambda l: l, map(lambda l: l.strip(), open(argv[1]).readlines()))]
jobs_finished = 0

def worker(job):
    global jobs_finished
    c, o, cmd = Path(job[0]), Path(job[1]), job[2]
    if not o.exists() or c.stat().st_mtime >= o.stat().st_mtime:
        p = Popen(cmd, stdout=PIPE, stderr=STDOUT, text=True)
        stdout, _ = p.communicate()
        if p.returncode != 0:
            return stdout.strip()
        print(f'{jobs_finished+1}/{len(jobs)} {o.name}')
    jobs_finished += 1
    return None

with ThreadPoolExecutor(max_workers=4) as executor:
    for i, r in enumerate(executor.map(worker, jobs)):
        if r != None:
            print(r)
            exit(1)
