#!/usr/bin/env python
"""pkg_clean - a simple python script to clean up the /var/cache/pacman/pkg directory.
More versatile than 'pacman -Sc' in that you can select how many old versions
to keep.
Usage: pkg_clean {-p} {-v} <# of copies to keep>
  # of copies to keep - (required) how many generations of each package to keep
  -p - (optional) preview what would be deleted; forces verbose (-v) mode.
  -v - (optional) show deleted packages."""
# Note that the determination of package age is done by simply looking at the date-time
# modified stamp on the file. There is just enough variation in the way package version
# is done that I thought this would be simpler & just as good.
# Also note that you must be root to run this script.

import getopt
import os
import re
import sys

# cleanup does the actual pkg file deletion
def cleanup(run_list):
  # strictly speaking only the first of these globals needs to be listed.
  global n_deleted, opt_verbose, opt_preview, n_to_keep
  # return if the run_list is too short
  if len(run_list) <= n_to_keep: return
  # Build list of tuples (date-time file modified, file name)
  dtm_list = [(os.stat(tfn)[8], tfn) for tfn in run_list]
  # Sort the list by date-time
  dtm_list.sort()
  # Build list of the filenames to delete (all but last n_to_keep).
  kill_list = [tfn[1] for tfn in dtm_list[:-n_to_keep]]
  if opt_verbose: print kill_list
  n_deleted += len(kill_list)
  if not opt_preview:
    for dfn in kill_list:
      os.unlink(dfn)

######################################################################
# mainline processing

# process command line options
try:
  opts, pargs = getopt.getopt(sys.argv[1:], 'vp')
  opt_dict = dict(opts)
  opt_preview = opt_dict.has_key('-p')
  opt_verbose = opt_dict.has_key('-v')
  if opt_preview: opt_verbose = True
  if len(pargs) == 1:
    n_to_keep = pargs[0]
  else:
    raise getopt.GetoptError("missing required argument.")
  try:
    n_to_keep = int(n_to_keep)
    if n_to_keep <= 0: raise ValueError
  except ValueError, e:
    raise getopt.GetoptError("# of copies to keep must be numeric > 0!")
except getopt.GetoptError, msg:
  print "Error:",msg,"\n",__doc__
  sys.exit(1)

# change to the pkg directory & get a sorted list of its contents
os.chdir('/var/cache/pacman/pkg')
pkg_fns = os.listdir('.')
pkg_fns.sort()

# for pkg e.g. 'gnome-common-2.8.0-1.pkg.tar.gz' group(1) is 'gnome-common'.
bpat = re.compile(r'(.+)-[^-]+-.+\.pkg.tar.gz$')
n_deleted = 0
pkg_base_nm = ''
# now look for "runs" of the same package differing only in version info.
for run_end in range(len(pkg_fns)):
  fn = pkg_fns[run_end]
  mo = bpat.match(fn) # test for a match of the package name pattern
  if mo:
    tbase = mo.group(1) # gets the 'base' package name
    # is it a new base name, i.e. the start of a new run?
    if tbase != pkg_base_nm: # if so then process the prior run
      if pkg_base_nm != '':
        cleanup(pkg_fns[run_start:run_end])
      pkg_base_nm = tbase # & setup for the new run
      run_start = run_end
  else:
    print >>sys.stderr, "File '"+fn+"' doesn't match package pattern!"

# catch the final run of the list
run_end += 1
cleanup(pkg_fns[run_start:run_end])

if opt_verbose:
  print n_deleted,"files deleted."

