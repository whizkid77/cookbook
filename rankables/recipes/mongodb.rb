Chef::Log.info("******Installing MongoDB.******")

include_recipe "mongodb::mongodb_org_repo"
include_recipe "mongodb::default"
