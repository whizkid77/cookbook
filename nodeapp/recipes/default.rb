app = search(:aws_opsworks_app).first
app_path = "/srv/#{app['shortname']}"

package "git" do
  # workaround for:
  # WARNING: The following packages cannot be authenticated!
  # liberror-perl
  # STDERR: E: There are problems and -y was used without --force-yes
  options "--force-yes" if node["platform"] == "ubuntu" && node["platform_version"] == "14.04"
end

application app_path do
  javascript "4"
  environment.update("PORT" => "80")
  environment.update(app["environment"])


  Chef::Log.info("********** The app's initial state is '#{node['state']}' **********")
#  Chef::Log.info("********** The app's username is '#{app['app_source']['username']}' **********")
#  Chef::Log.info("********** The app's pw is '#{app['app_source']['password']}' **********")
#  Chef::Log.info("********** The app's sshkey is '#{app['app_source']['sshkey']}' **********")
#  Chef::Log.info("********** The app's rev is '#{app['app_source']['revision']}' **********")
#  Chef::Log.info("********** The app's app_source is '#{app['app_source']}' **********")

  file "/tmp/git_wrapper.sh" do
    owner "ec2-user"
    mode "0755"
    content "#!/bin/sh\nexec /usr/bin/ssh -i /tmp/id_rsa \"$@\""
  end

  file "/tmp/id_rsa" do
    content app["app_source"]["ssh_key"]
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
