#!/bin/bash

mongod --config $(brew --prefix)/etc/mongod.conf &
bundle exec -- rerun -- thin start --port=8000 -R config.ru
