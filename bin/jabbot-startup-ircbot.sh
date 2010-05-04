#!/bin/sh

twiggy -l :15000 -Ilib -MJabbot::Core         -e '\&Jabbot::Core::app' &
twiggy -l :15101 -Ilib -MJabbot::Front::IRC   -e '\&Jabbot::Front::IRC::app' &
twiggy -l :15201 -Ilib -MJabbot::Back::Github -e '\&Jabbot::Back::Github::app' &


