import os
import glob

def resolve_file(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    out = []
    state = "NORMAL"
    for line in lines:
        if line.startswith("<<<<<<< HEAD"):
            state = "IN_HEAD"
        elif line.startswith("======="):
            if state == "IN_HEAD":
                state = "IN_THEIRS"
            else:
                out.append(line)
        elif line.startswith(">>>>>>>"):
            if state == "IN_THEIRS":
                state = "NORMAL"
            else:
                out.append(line)
        else:
            if state == "NORMAL":
                out.append(line)
            elif state == "IN_HEAD":
                out.append(line)
            elif state == "IN_THEIRS":
                pass
    
    with open(filepath, 'w') as f:
        f.writelines(out)

for f in glob.glob("**/*.swift", recursive=True):
    with open(f, 'r') as file:
        content = file.read()
    if "<<<<<<< HEAD" in content:
        resolve_file(f)
        print(f"Resolved {f}")
