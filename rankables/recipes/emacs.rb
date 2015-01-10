Chef::Log.info("******Installing emacs.******")
package 'emacs' do
  action :install
end
