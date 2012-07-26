#!/bin/bash
sudo rsync -av --delete --exclude sync.sh --exclude installed --exclude packages  . /mnt/lfs/huddle/
