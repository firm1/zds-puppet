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
    $repo = $zds::params::repo,
    $branch = $zds::params::branch,
    $id = $zds::params::id,
    $database_name = $zds::params::database_name,
    $database_host = $zds::params::database_host,
    $database_user = $zds::params::database_user,
    $database_password = $zds::params::database_password,
    $venv_path = $zds::params::venv_path,
    $webapp_path = $zds::params::webapp_path,
    $solr_path = $zds::params::solr_path,
    $node_version = $zds::params::node_version,
    $pandoc_repo = $zds::params::pandoc_repo,
    $pandoc_release_tag = $zds::params::pandoc_release_tag,
    $pandoc_dest = $zds::params::pandoc_dest,
    $logo_url = $zds::params::logo_url,
) inherits zds::params {
    include supervisor

    class {"::zds::database": 
        subscribe => File["settings_prod"],
    }
    
    class { 'memcached':
        max_memory => '50%'
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
    vcsrepo { "${webapp_path}":
      ensure   => latest,
      provider => git,
      source   => "https://github.com/${repo}/zds-site.git",
      revision => "${branch}",
    } ->
    file {'settings_prod':
      path => "${webapp_path}/zds/settings_prod.py",
      ensure => present,
      content => template('zds/settings_prod.erb'),
      mode => "0755"
    } ->
    class { 'python' :
      version    => 'system',
      pip        => true,
      dev        => true,
      virtualenv => true,
    } ->
    python::virtualenv {"${venv_path}":
        ensure       => present,
        version      => 'system',
        requirements => "${webapp_path}/requirements.txt",
        systempkgs   => true,
        distribute   => false,
        subscribe => Vcsrepo["${webapp_path}"],
    } ->
    file { "${venv_path}/logs":
        ensure => directory,
        require => File['settings_prod'],
        mode => "0755"
    } ->
    python::pip { 'gunicorn_env':
        pkgname => 'gunicorn',
        ensure  => 'present',
        virtualenv => "${venv_path}"
    } ->
    file {'gunicorn_start':
      path => "${venv_path}/bin/gunicorn_start.bash",
      ensure => present,
      content => template('zds/gunicorn_start.erb'),
      mode => "0755"
    } ->
    python::pip { 'MySQL-python':
        pkgname => 'MySQL-python',
        ensure  => 'present',
        virtualenv => "${venv_path}"
    } ->
    exec { "syncdb":
        command => "${venv_path}/bin/python ${webapp_path}/manage.py syncdb --noinput",
        subscribe => File["settings_prod"],
        require => [File['settings_prod'], Class['zds::database']]
    }
    exec { "migrate":
        command => "${venv_path}/bin/python ${webapp_path}/manage.py migrate",
        subscribe => File["settings_prod"],
        require => Exec['syncdb']
    }
    exec { "fixtures":
        command => "${venv_path}/bin/python ${webapp_path}/manage.py loaddata fixtures/*.yaml",
        cwd => "${webapp_path}",
        subscribe => File["settings_prod"],
        require => Exec['migrate']
    }
    python::gunicorn { "vhost-${id}":
        ensure      => present,
        virtualenv  => "${venv_path}",
        mode        => 'wsgi',
        dir         => "${webapp_path}",
        bind        => "unix:/tmp/gunicorn-${id}.sock",
        environment => 'prod',
        appmodule   => 'zds',
        osenv       => { 'DBHOST' => "${database_host}" },
        timeout     => 30,
        require     => File['gunicorn_start'],
        subscribe => [Vcsrepo["${webapp_path}"], File["settings_prod"]]
    } ->
    supervisor::app { "zds-site-${id}":
      app_name     => "zds-${id}",
      command      => "${venv_path}/bin/gunicorn_start.bash",
      directory    => "${venv_path}/bin",
      subscribe => [Vcsrepo["${webapp_path}"], File["settings_prod"]]
    } ->
    supervisor::app { "zds-solr-${id}":
      app_name     => "solr-${id}",
      command      => "java -jar start.jar",
      directory    => "${solr_path}/solr-4.9.0/example/",
      require => Class['zds::solr']
    }

    class {"::zds::solr":
        require => [Vcsrepo["${webapp_path}"], File["settings_prod"]]
    }

    class {"::zds::front":
        require => File["settings_prod"]
    }

    class {"::zds::web":
        require => Class["zds::front"],
        subscribe => Class["zds::front"]
    }

    class {"::zds::pandoc": }
}
