#!/bin/sh

start_server --port 15000 -- twiggy -Ilib -MJabbot::Core         -e '\&Jabbot::Core::app' &
start_server --port 15101 -- twiggy -Ilib -MJabbot::Front::IRC   -e '\&Jabbot::Front::IRC::app' &
start_server --port 15201 -- twiggy -Ilib -MJabbot::Back::Github -e '\&Jabbot::Back::Github::app' &


