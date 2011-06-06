#!/bin/sh

aemp run profile seed &
perl -Ilib -MJabbot::Core -e 'Jabbot::Core->run' &
perl -Ilib -MJabbot::Front::IRC -e 'Jabbot::Front::IRC->run' &
start_server --port 15201 -- twiggy -Ilib -MJabbot::Back::Github -e '\&Jabbot::Back::Github::app' &
