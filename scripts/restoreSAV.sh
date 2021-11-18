#!/bin/bash

# find . -name '*.SAV' -exec ./restoreSAV.sh \{\} \;
mv  $1 ${1%.SAV}
