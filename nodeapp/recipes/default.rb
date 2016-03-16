app = search(:aws_opsworks_app).first

time =  Time.new.strftime("%Y%m%d%H%M%S")

app_path = "/srv/#{app['shortname']}/#{time}"

directory "/srv/#{app['shortname']}" do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

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
  Chef::Log.info("********** The app's path is '#{app_path}' **********")
  Chef::Log.info("********** 7 '#{app['environment']['NODE_PATH']}' **********")

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
  end

  service_name "shopworks"

  npm_install
  npm_start do
    action [:stop, :enable, :start]
  end
end
