#!/bin/bash

mongod &
grunt &
bundle exec -- rerun -- thin start --port=8000 -R config.ru
