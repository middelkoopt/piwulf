#!/bin/bash
cd ./containers/warewulf
SITE=${SITE:-site.json} exec ./setup-nodes.sh
