#
# Cookbook Name:: sensoryjourneys
# Recipe:: default
#
# Copyright 2012, Gravitystorm Limited

### The website



package "postgresql-9.1" do
  action :install
end

service "postgresql" do
  supports :reload => true, :restart => true
  action :enable
end

%w( ruby1.8 rdoc1.8 ri1.8 ruby irb libxml2-dev ruby1.8-dev apache2-threaded-dev libmagick-dev libmagickwand-dev build-essential libopenssl-ruby apache2 libxml-ruby git ).each do |p|
  package p
end

package "rubygems" do
  action :install
end

gem_package "rails" do
  version '2.3.8'
  action :install
  gem_binary '/usr/bin/gem'
end

gem_package "pg" do
  action :install
  gem_binary '/usr/bin/gem'
end

gem_package "libxml-ruby" do
  action :install
  gem_binary '/usr/bin/gem'
end

gem_package "rmagick" do
  action :install
  gem_binary '/usr/bin/gem'
end

include_recipe 'passenger-gem'

user "sensory" do
  action :create
  shell "/bin/bash"
end

# Create the database user. For now, it's a superuser.
script "create sensory db user" do
  interpreter "bash"
  user "postgres"
  group "postgres"
  cwd "/var/lib/postgresql"
  code <<-EOH
    createuser sensory -s
  EOH
  not_if %q{test -n "`sudo -u postgres psql template1 -A -t -c '\du sensory'`"} # Mmm, hacky
end

script "create databases" do
  user "postgres"
  group "postgres"
  interpreter "bash"
  cwd "/var/lib/postgresql"
  code <<-EOH
    createdb -E UTF8 -O sensory sensory_prod
    createdb -E UTF8 -O sensory paperwalking
  EOH
  not_if %q{test -n "`sudo -u postgres psql template1 -A -t -c '\l' | grep sensory_prod`"}
end

deploy_dir = "/var/www/sensory"
shared_dir = File.join(deploy_dir, "shared")

[shared_dir, deploy_dir, File.join(shared_dir, "config"), File.join(shared_dir, "log")].each do |dir|
  directory dir do
    owner "sensory"
    group "sensory"
    recursive true
  end
end

deploy_revision deploy_dir do
  repo "https://github.com/gravitystorm/Sensory-Journeys.git"
  revision "master"
  user "sensory"
  group "sensory"

  before_migrate do
    current_release_directory = release_path
    shared_directory = new_resource.shared_path
    running_deploy_user = new_resource.user

    script 'Create the database' do
      interpreter "bash"
      cwd current_release_directory
      user running_deploy_user
      environment 'RAILS_ENV' => 'production'
      code <<-EOH
        rake db:create
        psql -U sensory -h localhost -f wp/site/doc/create.postgres paperwalking
      EOH
      not_if %q{test -n "`sudo -u postgres psql template1 -A -t -c '\l' | grep sensory_prod`"}
    end
  end

  migrate true
  migration_command "rake db:migrate"
  environment "RAILS_ENV" => "production"
  action :deploy
  restart_command "touch web/tmp/restart.txt"
  create_dirs_before_symlink %w{web/tmp}
  symlinks "system" => "web/public/system", "pids" => "web/tmp/pids", "log" => "web/log"
  symlink_before_migrate "config/database.yml" => "web/config/database.yml"
end

template "/etc/apache2/sites-available/sensory" do
  source "apache.vhost.conf"
  notifies :reload, "service[apache2]"
end

apache_site "default" do
  enable false
end

apache_site "sensory" do
  enable true
end

# Go into the project source code, and set up the database configuration
# 
# $ cd Sensory-Journeys/web/config
# $ cp postgres.example.database.yml database.yml
# $ nano database.yml # you need to edit this with the database username (sensory) and password (you picked one earlier)
# $ cp example.environment.rb environment.rb
# $ nano environment.rb # you need to set the walking papers url and change the default passwords
# 
# Setup the database with all the correct tables, columns etc for our project.
# 
# $ rake db:migrate
#

### Walking papers

%w( curl python-imaging python-numpy openjdk-6-jre-headless libapache2-mod-php5 php5-gd php5-pgsql php-pear).each do |p|
  package p
end

script "install pear modules" do
  interpreter "bash"
  cwd "/tmp"
  code <<-EOH
    pear install Crypt_HMAC HTTP_Request DB Crypt_HMAC2 MDB2 MDB2#pgsql
  EOH
  not_if "test -f /usr/share/php/Crypt/HMAC2.php"
end

# Unfortunately, this doesn't work. There's a stange change in behaviour in the
# linker that prevents vlfeat from compiling. The version that we're using is
# unmaintained, and upstream walking papers no longer uses it.
# In vlfeat/Makefile, you need to move a flag around:
# In the common unix configuration section:
# C_LDFLAGS   += -L$(BINDIR) -l$(DLL_NAME)  <- add -lm to the end
# In the linux-64 section:
# LDFLAGS         += -lm -Wl,--rpath,\$$ORIGIN/ <- remove -lm from this line
# It will then compile, and chef will then be happy.
# The real fix is a whole-scale upgrade of the wp module in this project.
script "set up walking papers" do
  interpreter "bash"
  cwd File.join(deploy_dir, "current")
  user "sensory"
  group "sensory"
  code <<-EOH
    set -e
    git submodule init && git submodule update
    cd wp/site && make
    cd ../decoder && make
  EOH
  not_if "test -f #{File.join(deploy_dir, "current", 'bin/a64/test_stringop')}"
end

# Set up the walking papers configuration

template "/var/www/sensory/current/wp/site/lib/init.php" do
  source "init.php.txt"
  owner "sensory"
  group "sensory"
  mode '0644'
end

# Increase the size of file uploads and POSTs in general
template "/etc/php5/apache2/php.ini" do
  source "php.ini"
  notifies :restart, "service[apache2]"
end

# 
# ========= scans-compile.py ==========
# 
# This is the utility that compiles the individual scans into slippy maps.
#

package "python-psycopg2" do
  action :install
end

template "/var/www/sensory/current/wp/dbconnect.py" do
  source "example.dbconnect.py"
  owner "sensory"
  group "sensory"
  mode '0644'
end
