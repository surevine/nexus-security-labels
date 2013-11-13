#!/usr/bin/env python

import sys
import xml.etree.ElementTree as etree

def print_tag(tagname, child):
  tag = child.tag if "}" not in child.tag else child.tag.split("}")[1][0:]
  if tag == tagname:
    print child.text

filename = sys.argv[1] # Location of the xml file
tagname = sys.argv[2] # Name of the tag that we're targetting
recurse = sys.argv[3] # Should we look at grandchild nodes?

if len(sys.argv) < 3:
  print sys.argv[1]
  sys.exit("Usage: parsexml.py file.xml tagname [true|false]\n  e.g. ./parsexml.py pom.xml artifactId false")


tree = etree.parse(filename)
root = tree.getroot()
for child in root:
  if len(child) > 0 and recurse != "false":
    for grandchild in child:
      print_tag(tagname, grandchild)
  else:
    print_tag(tagname, child)