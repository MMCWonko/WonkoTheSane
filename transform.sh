#!/bin/bash
WONKO_ROOT=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
rm -rf $WONKO_ROOT/files/*
rm -f $WONKO_ROOT/cache/*.json
$WONKO_ROOT/main.rb
