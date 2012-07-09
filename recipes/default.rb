#
# Cookbook Name:: artifactory
# Recipe:: default
#
# Copyright 2012, Michel Blankleder
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

remote_file "/tmp/#{node[:artifactory][:rpm]}" do
  source node[:artifactory][:url]
  mode "0644"
  #checksum
  not_if {File.exists?("/tmp/#{node[:artifactory][:rpm]}")}
end

package "artifactory" do
  action :install
  source "/tmp/#{node[:artifactory][:rpm]}"
  provider Chef::Provider::Package::Rpm
  not_if "rpm -q artifactory"
end

mysql_server = `rpm -q mysql-server | grep -v "not installed"`

unless mysql_server.nil? || mysql_server == ""
    #conn_ver=`grep JDBC_VERSION= /opt/artifactory/bin/configure.mysql.sh |awk -F "=" '{print $2}'`
    conn_ver="5.1.18"
    remote_file "/opt/artifactory/tomcat/lib/mysql-connector-java-#{conn_ver}.jar" do
        source "http://repo.jfrog.org/artifactory/remote-repos/mysql/mysql-connector-java/#{conn_ver}/mysql-connector-java-#{conn_ver}.jar"
        mode "0644"
        not_if {File.exists?("/opt/artifactory/tomcat/lib/mysql-connector-java-#{conn_ver}.jar")}
    end

    bash "create_database" do
        user "root"
        code <<-EOH
            `service mysqld restart`
            echo "Creating the Artifactory MySQL user and database..."
            MYSQL_LOGIN="mysql -u#{node[:mysql][:user]}"
            if [ ! -z "#{node[:mysql][:pass]}" ]; then
                MYSQL_LOGIN="mysql -u#{node[:mysql][:user]} -p#{node[:mysql][:pass]}"
            fi
            $MYSQL_LOGIN <<EOF
                CREATE DATABASE IF NOT EXISTS artifactory CHARACTER SET=utf8;
                GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER,INDEX on artifactory.* TO "#{node[:artifactory][:dbuser]}"@'localhost' IDENTIFIED BY "#{node[:artifactory][:dbpass]}";
                FLUSH PRIVILEGES;
                QUIT
            EOF
        EOH
        action :run
    end

    template "/var/lib/artifactory/etc/artifactory.system.properties" do
        source "artifactory.system.properties.erb"
        mode 0770
        owner "artifactory"
        #group "artifactory"
        variables(:db_type => "artifactory.jcr.configDir=repo/filesystem-mysql")
    end

    template "/var/lib/artifactory/etc/repo/filesystem-mysql/repo.xml" do
        source "repo.xml.erb"
        mode 0770
        owner "artifactory"
        #group "artifactory"
    end

end
