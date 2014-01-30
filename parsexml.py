#!/usr/bin/env python

import sys
from xml.dom.minidom import parse

dom = parse(sys.argv[1]);

for n in dom.childNodes[0].childNodes:
  if n.firstChild and n.tagName == sys.argv[2]:
    print n.firstChild.data
