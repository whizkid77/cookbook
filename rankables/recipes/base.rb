for p in ['emacs','ack','mlocate'] do
  Chef::Log.info("******Installing #{p}******")
  package p do
    action :install
  end
end
