#!/usr/bin/env python3
####    ############    Copyright (C) 2025 Mattis Hasler, Barkhausen Institut
####    ############    
####                    This source describes Open Hardware and is licensed under the
####                    CERN-OHL-W v2 (https://cern.ch/cern-ohl)
############    ####    
############    ####    
####    ####    ####    
####    ####    ####    
############            Authors:
############            Mattis Hasler (mattis.hasler@barkhauseninstitut.org)

from pathlib import Path
import re


TAG_SLASH = [
"////    ////////////",
"////    ////////////",
"////",
"////",
"////////////    ////",
"////////////    ////",
"////    ////    ////",
"////    ////    ////",
"////////////",
"////////////"
]
TAG_HASH = [
"####    ############",
"####    ############",
"####",
"####",
"############    ####",
"############    ####",
"####    ####    ####",
"####    ####    ####",
"############",
"############",
]

TAG_SLASH_PAD = 24
TAG_HASH_PAD = 24

REX_COPYRIGHT = r"Copyright \(C\) ([\d\-\s]+) ([\w\s]+), Barkhausen Institut"
COPYRIGHT = "Copyright (C) {years} {author}, Barkhausen Institut"
LICENSE = [
    "",
    "This source describes Open Hardware and is licensed under the",
    "CERN-OHL-W v2 (https://cern.ch/cern-ohl)"
]
AUTHOR = "Authors:"

DEFAULT_AUTHOR = "Mattis Hasler (mattis.hasler@barkhauseninstitut.org)"
DEFAULT_C_AUTHOR = "Mattis Hasler"
DEAFULT_C_YEARS = "2025"

def processFile(fname:Path, tagLines:list[str], tagWidth:int):
    with open(fname, "r") as f:
        lines = f.readlines()
    cAuthor = None
    cYears = None
    licGood = True
    spaceGood = True
    authorIdx = None
    tagIdx = 0
    authorLines = []
    sheBang = None
    for line in (lines):
        if tagIdx >= len(tagLines):
            break
        if tagIdx == 0 and line.startswith("#!"):
            sheBang = line
            continue
        tagline = tagLines[tagIdx]
        if not line.startswith(tagline):
            raise Exception(f"problem with tag")
        rest = line[tagWidth:].strip()
        if tagIdx == 0:
            m = re.match(REX_COPYRIGHT, rest)
            if m:
                cAuthor = m.group(2)
                cYears = m.group(1)
        elif tagIdx < len(LICENSE)+1:
            if rest != LICENSE[tagIdx-1]:
                licGood = False
        elif rest == AUTHOR:
            authorIdx = tagIdx
        elif authorIdx is not None and tagIdx > authorIdx:
            authorLines.append(rest)
        elif rest != '':
            spaceGood = False
        tagIdx += 1
    #print("Tag details")
    #print(f"(c) Author: {cAuthor} years: {cYears}")
    #print(f"License:{'good' if licGood else 'bad'}")
    #print(f"Space:{'good' if spaceGood else 'bad'}")
    #print("Authors:")
    #for line in authorLines:
    #    print(line)
    if licGood and spaceGood and len(authorLines) > 0 and cAuthor is not None and cYears is not None:
        return
    print(f"Header update needed:{fname}")
    if len(authorLines) == 0:
        authorLines.append(DEFAULT_AUTHOR)
    if cAuthor is None:
        cAuthor = DEFAULT_C_AUTHOR
    if cYears is None:
        cYears = DEAFULT_C_YEARS
    header = [COPYRIGHT.format(years=cYears, author=cAuthor)]
    header += LICENSE
    nSpace = len(tagLines) - len(header) - len(authorLines) - 1
    header += [""] * nSpace
    header += [AUTHOR]
    header += authorLines
    skip = len(header)
    if sheBang is not None:
        skip += 1

    with open(fname, "w") as f:
        if sheBang is not None:
            print(sheBang, file=f, end='')
        for tagline,line in zip(tagLines, header):
            print(f"{tagline.ljust(tagWidth)}{line}", file=f)
        for line in lines[skip:]:
            print(line, file=f, end='')





def main():
    root = Path(".")
    for fname in root.glob("**/*"):
        if fname.parts[0] in ['chaos', 'rrun']:
            continue
        elif fname.parts[0][0] == '.':
            continue
        elif fname.name in ['RR']:
            continue
        elif fname.suffix in ['.pyc', '.md', '.lock']:
            continue
        elif not fname.is_file():
            continue
        if fname.suffix in [".v", ".sv", '.c', '.h', '.cc']:
            tag = TAG_SLASH
            tagWidth = TAG_SLASH_PAD
        elif fname.suffix in [".py", '.nix']:
            tag = TAG_HASH
            tagWidth = TAG_HASH_PAD
        else:
            print(f"file not detected - skipping: {fname}")
            continue
        try:
            processFile(fname, tag, tagWidth)
        except:
            print(f"Error processing {fname}")

if __name__ == "__main__":
    main()