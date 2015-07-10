#!/bin/bash

cat webroot.txt | while read root; do
  echo "$root"
  find "$root" -name wp-config.php >> wp-config.txt
done

# vim:ts=2:sw=2:sts=2:et:ft=sh

