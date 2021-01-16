#!/usr/bin/env python3

__author__ = "Vilhelm Prytz"
__email__ = "vilhelm@prytznet.se"

def read():
    with open("CHANGELOG.md") as f:
        changelog = f.read()
    return changelog


def main():
    changelog = read()
    lines = changelog.split("\n")
    release_linenumbers = []
    for i in range(len(lines)):
        l = lines[i]
        if l[:3] == "## ":
            release_linenumbers.append(i)
    
    parse = False
    for i in range(len(lines)):
        if i == release_linenumbers[0]:
            parse = True
        if i == release_linenumbers[1]:
            parse = False
        if parse:
            print(lines[i])



if __name__ == "__main__":
    main()
