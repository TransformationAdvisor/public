#!/bin/bash

######################
# deleleting signature files in nightly folder which are more than 10 days old
######################
scripts_dir=$(dirname "$0")
cd $scripts_dir/../nightly

# get the date for 9 days ago. e.g. "2020-07-10"
cutoff=$(date +%F  -d 'today -9 day')
echo Deleting all signature files in the nightly folder created before $cutoff

# list the files recursively from current directory in the git metadata from the HEAD of the branch
# see "git ls-tree --help" for command usage 
git ls-tree -r --name-only HEAD | while read filename; do
  # get the last commit timestamp for the file in ISO 8601-like format from git metadata. e.g. "2020-07-09 12:31:42 -0700"
  # last "--" is required to separate the filepath from other options. see "git log --help" for command usage
  ts=$(git log -1 --format="%ci" -- $filename)
  if [[ $ts < $cutoff ]] && [[ $filename != *.keep ]]; then
    # Since transformation-advisor-db is not built nightly, skip deleting the signature files for transformation-advisor-db
    if [[ $filename != *transformation-advisor-db* ]]; then
      # remove signature file that is created more than or equal to 10 days old
      rm -f $filename
    fi
  fi
done

# remove empty directory
find . -type d -empty | xargs rmdir

git status
git commit -a -m "remove signature files in nightly folder berfore $cutoff"
git push

