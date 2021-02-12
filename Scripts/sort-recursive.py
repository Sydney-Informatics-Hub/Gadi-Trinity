#!/usr/bin/env python3
import os
import sys

if(len(sys.argv) != 2):
    print("Call with name of recursive_trinity.cmds file")
    exit

fname = sys.argv[1]

# Picky about where it is called
def commandToSize(command):
    return os.stat("/".join(
        command.split()[2].lstrip("\"").rstrip("\"").split("/")[-5:])).st_size

with open(fname) as f:
    commands = f.readlines()

lofc = [{"size":commandToSize(x),"command":x} for x in commands]
sortedlofc = sorted(lofc,key=lambda x: x['size'],reverse=True)
with open(fname+'.sorted','w') as f:
    for c in sortedlofc:
        f.write(c['command'])
        

