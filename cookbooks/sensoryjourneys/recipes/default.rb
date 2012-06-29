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

%w( ruby1.8 rdoc1.8 ri1.8 ruby irb libxml2-dev ruby1.8-dev apache2-threaded-dev libmagick9-dev build-essential libopenssl-ruby apache2 libxml-ruby ).each do |p|
  package p
end

package "rubygems" do
  action :install
end

gem_package "rails" do
  version '2.3.8'
  action :install
end

gem_package "pg" do
  action :install
end

gem_package "libxml-ruby" do
  action :install
end

include_recipe 'passenger-gem'

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
  not_if test -f "/usr/share/php/Crypt/HMAC2.php"
end


# 
# $ sudo -u postgres -i
#   $ createdb -E UTF8 -O sensory paperwalking
#   $ exit
# 
# Go into the Sensory-Journeys top level folder
# $ cd /path/to/Sensory-Journeys
# 
# # Add the tables to the paperwalking database
# 
# $ psql -U sensory -h localhost -f wp/site/doc/create.postgres paperwalking
# 
# Set up the rest of walking papers
# 
# $ git submodule init && git submodule update
# $ cd wp/site && make
# $ cd ../decoder && make
# 
# Set up the walking papers configuration
# 
# $ cd ../site/lib
# $ cp init.php.txt init.php
# $ nano init.php (change dsn and final_destination)
# 
# PHP limits the size of uploaded files and POST requests in general. We need to increase these dramatically given the size of scans
# 
# $ sudo nano /etc/php5/apache2/php.ini # find and change these two values
#   upload_max_filesize = 25M
#   post_max_size = 25M
# 
# ========= scans-compile.py ==========
# 
# This is the utility that compiles the individual scans into slippy maps.
#

package "python-psycopg2" do
  action :install
end

# cd /path/to/Sensory-Journeys/wp
# cp example.dbconnect.py dbconnect.py
# nano dbconnect.py # set the password
