#
# Cookbook Name:: provoke
# Provider:: provoke_api
#
# The MIT License (MIT)
#
# Copyright (c) 2014 Ian Good
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

def whyrun_supported?
  true
end

use_inline_resources

action :create do
  updated = false
  name = new_resource.name
  service_name = new_resource.service_name || name
  etc_dir = new_resource.etc_dir || ::File.join('/etc', name)

  # Create the config directory.
  r_etc_dir = directory etc_dir do
    mode 00755
    recursive true
  end
  updated ||= r_etc_dir.updated_by_last_action?

  # Create the /etc/init.d script.
  r_init = cookbook_file ::File.join('/etc/init.d', service_name) do
    cookbook new_resource.cookbook
    source 'api.init'
    mode 00755
  end
  updated ||= r_init.updated_by_last_action?

  # Create the /etc/default directory.
  r_default_dir = directory '/etc/default' do
    mode 00755
    recursive true
  end
  updated ||= r_default_dir.updated_by_last_action?

  # Create the /etc/default config file.
  r_default = template ::File.join('/etc/default', service_name) do
    cookbook new_resource.cookbook
    source 'api.default.erb'
    mode 00644
    variables({
      :etc_dir => etc_dir,
    })
    action :create
  end

  # Create the service resource.
  r_service = service service_name do
    supports :status => true, :start => true, :stop => true,
      :restart => true, :reload => true
    action :nothing
  end
  updated ||= r_service.updated_by_last_action?

  # Create the API/uWSGI config file.
  uwsgi_defaults = node['provoke']['uwsgi-defaults']
  uwsgi_config = uwsgi_defaults.merge(new_resource.uwsgi_config)
  r_api = template ::File.join(etc_dir, 'api.conf') do
    cookbook new_resource.cookbook
    source 'api.conf.erb'
    mode 00644
    variables({
      :app => new_resource.app,
      :uwsgi_config => uwsgi_config,
      :amqp => new_resource.amqp,
      :mysql => new_resource.mysql,
      :taskgroups => new_resource.taskgroups,
    })
    action :create
    notifies :restart, "service[#{ service_name }]"
  end
  updated ||= r_api.updated_by_last_action?

  # Install Python packages with pip, if desired.
  if node['provoke']['install-python-packages']
    packages = ['provoke[api]', 'uwsgi']
    if new_resource.mysql
      packages.push('provoke[mysql]')
    end
    if new_resource.amqp
      packages.push('provoke[amqp]')
    end

    packages.each do |pkg|
      r_pkg = python_pip pkg do
        action :upgrade
        notifies :restart, "service[#{ service_name }]"
      end
      updated ||= r_pkg.updated_by_last_action?
    end
  end

  new_resource.updated_by_last_action(updated)
end

