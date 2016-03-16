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
  Chef::Log.info("********** 7 '#{app['environment']['NODE_PATH']}' **********")
#  search("aws_opsworks_app").each do |app|
#    Chef::Log.info("********** The app's short name is '#{app['shortname']}' **********")
#    Chef::Log.info("********** The app's URL is '#{app['app_source']['url']}' **********")
#  end

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

  ENV['NODE_PATH'] = app['environment']['NODE_PATH']

  Chef::Log.info("********** env '#{ENV}' **********")
  npm_install
  npm_start do
    Chef::Log.info("********** env inside '#{ENV}' **********")
    action [:stop, :enable, :start]
  end
end
