if node['revision']

app = search(:aws_opsworks_app).first

app_path = "/srv/#{app['shortname']}/#{node['revision']}"

directory "/srv/#{app['shortname']}" do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# Loop over all user folders.  Wrap in ruby_block because compile-time error occurs if /srv/{APP_SHORT_NAME} does not exist.
# http://stackoverflow.com/questions/25980820/please-explain-compile-time-vs-run-time-in-chef-recipes
ruby_block 'prune old deployments' do
  block do
    Dir.entries("/srv/#{app['shortname']}").sort.reverse.each_with_index do |release_dir,index|
      next if release_dir.start_with?('.')
      next if index < 5
      Chef::Log.info("********** Pruning old release (#{index}) '#{release_dir}' **********")
      directory "/srv/#{app['shortname']}/#{release_dir}" do
        action :delete
        recursive true
      end
    end
  end
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


  Chef::Log.info("********** The app's git revision is '#{node['git_revision']}' **********")
  Chef::Log.info("********** The app's revision is '#{node['revision']}' **********")
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


  npm_install
  npm_start do
    service_name "shopworks"
    action [:stop, :enable, :start]
  end
end

end # if node['revision']
