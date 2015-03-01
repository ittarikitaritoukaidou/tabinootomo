#!/bin/bash

mongod --config $(brew --prefix)/etc/mongod.conf &
bundle exec -- thin start --port=8000 -R config.ru
