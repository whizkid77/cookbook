app = search(:aws_opsworks_app).first
app_path = "/srv/#{app['shortname']}"

package "git" do
  # workaround for:
  # WARNING: The following packages cannot be authenticated!
  # liberror-perl
  # STDERR: E: There are problems and -y was used without --force-yes
  options "--force-yes" if node["platform"] == "ubuntu" && node["platform_version"] == "14.04"
end

yum_package 'gcc-c++'

application app_path do
  javascript "5.6.0"
  environment.update("PORT" => "80")
  environment.update(app["environment"])


  Chef::Log.info("********** The app's initial state is '#{node['state']}' **********")
  Chef::Log.info("********** The app's short name is '#{app['shortname']}' **********")
  Chef::Log.info("********** The app's URL is '#{app['app_source']['url']}' **********")
  Chef::Log.info("ENV1: #{app}")
  Chef::Log.info("ENV2: #{app[:deploy]}")
  Chef::Log.info("ENV3: #{app['deploy']}")
  Chef::Log.info("ENV4: #{app[:deploy]['nodeapp'][:environment_variables]}")
  Chef::Log.info("ENV5: #{app[:deploy]['nodeapp'][:environment_variables]}")
  Chef::Log.info("USER_ID: #{app[:deploy]['nodeapp'][:environment_variables][:NODE_PATH]}")
  search("aws_opsworks_app").each do |app|
    Chef::Log.info("********** The app's short name is '#{app['shortname']}' **********")
    Chef::Log.info("********** The app's URL is '#{app['app_source']['url']}' **********")
    Chef::Log.info("ENVa: #{app[:deploy]}")
    Chef::Log.info("ENVb: #{app['deploy']}")
  end

  file "/tmp/git_wrapper.sh" do
    owner "root"
    mode "0755"
    content "#!/bin/sh\nexec /usr/bin/ssh -o StrictHostKeyChecking=no -i /tmp/id_rsa \"$@\""
  end

  file "/tmp/id_rsa" do
    content app["app_source"]["ssh_key"]
    mode "0600"
  end

  git app_path do
    repository app["app_source"]["url"]
    revision app["app_source"]["revision"]
    ssh_wrapper "/tmp/git_wrapper.sh"
  #  deploy_key app["app_source"]["ssh_key"]
  end

#  link "#{app_path}/index.js" do
#    to "#{app_path}/server.js"
#  end

  npm_install
  npm_start do
    action [:stop, :enable, :start]
  end
end
