Chef::Log.info("******Installing MongoDB.******")
depends 'mongodb'

include_recipe "mongodb::10gen_repo"
include_recipe "mongodb::default"
