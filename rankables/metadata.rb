name        "rankables"
description 'Cookbook for MongoDB Berkshelf based install'
maintainer  "Third Wave Labs"
version     "1.0.0"

depends 'mongodb'

recipe 'rankables::codedeploy-agent', 'Fetches, installs, and starts the AWS CodeDeploy host agent'
