#!/bin/bash
WONKO_ROOT=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
$WONKO_ROOT/main.rb --invalidate-all --refresh net.minecraft --refresh net.minecraftforge --refresh com.mumfrey.liteloader
