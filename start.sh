#!/bin/sh
erl -noshell -pa ./ -run deploy_tool main -s init stop
