#!/bin/sh

perl bin/jabbot -run FrontEnd::IRC &

sleep 2
perl bin/jabbot -run BackEnd::Github &

sleep 2
perl bin/jabbot -run BackEnd::FeedAggregator &

sleep 2
perl bin/jabbot -run BackEnd::CPANTaiwan &


