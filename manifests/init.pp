# == Class: zds
#
# Full description of class zds here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { 'zds':
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <firm1@zestedesavoir.com>
#
# === Copyright
#
# Copyright 2015 Your name here, unless otherwise noted.
#
class zds (
    $url = $zds::params::url,
    $repos = $zds::params::repos,
    $database_name = $zds::params::database_name,
    $database_host = $zds::params::database_host,
    $database_user = $zds::params::database_user,
    $database_password = $zds::params::database_password,
    $node_version = $zds::params::node_version,
    $pandoc_repo = $zds::params::pandoc_repo,
    $pandoc_release_tag = $zds::params::pandoc_release_tag,
    $pandoc_dest = $zds::params::pandoc_dest,
    $logo_url = $zds::params::logo_url,
) inherits zds::params {

    class { 'java':
      distribution => 'jdk',
    }

    class { 'nodejs':
      version => "${node_version}",
    }
    exec {"update-npm":
        command => "npm install -g npm",
        path => "/usr/local/node/node-default/bin",
        require => Class['nodejs']
    }

    class { 'memcached':
        max_memory => '20%'
    }

    class { '::mysql::server':
      root_password    => "${database_password}"
    }

    package {
        "libxml2-dev": ensure => present;
        "python-lxml": ensure => present;
        "python-sqlparse": ensure => present;
        "libxslt1-dev": ensure => present;
        "python-mysqldb": ensure => present;
        "libmysqlclient-dev": ensure => present;
        "haskell-platform": ensure => present;
        "jpegoptim": ensure => present;
        "optipng": ensure => present;
    } ->
    package {"git-core":
      ensure => latest,
    } ->
    class { 'python' :
      version    => 'system',
      pip        => true,
      dev        => true,
      virtualenv => true,
    } ->
    class {"::zds::pandoc": }

    create_resources ("::zds::core", $repos)
    create_resources ("::zds::database", $repos)
    create_resources ("::zds::django", $repos)
    create_resources ("::zds::solr", $repos)
    create_resources ("::zds::front", $repos)
    create_resources ("::zds::web", $repos)
}
