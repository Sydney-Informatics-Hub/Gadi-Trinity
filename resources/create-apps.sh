#!/bin/bash
mkdir apps
mkdir apps/python2
cp -r /apps/bowtie2 apps
cp -r /apps/jellyfish apps
cp -r /apps/python2/2.7.17 apps/python2
cp -r /apps/python3/3.7.4 apps/python3
cp -r /apps/salmon apps
cp -r /apps/samtools apps
cp -r /apps/trinity apps
cp -r Modules apps
patch ./apps/trinity/2.9.1/Trinity Trinity-2.9.1.patch
tar cf apps.tar apps
rm -fr apps
