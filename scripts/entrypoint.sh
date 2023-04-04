#!/bin/sh
set -ex

/home/elixir/app/bin/accounts_management_api eval "AccountsManagementAPI.Release.migrate"
/home/elixir/app/bin/accounts_management_api "$@"
