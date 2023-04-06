#!/bin/sh
set -ex

/app/bin/migrate
/app/bin/server
