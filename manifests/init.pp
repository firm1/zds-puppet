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
    $node_version = $zds::params::node_version,
) inherits zds::params {

    include nginx
    include supervisor

    package {"texlive": 
      ensure => "latest"
    }
    package {"texlive-xetex":
      ensure => "latest"
    }
    package {"texlive-lang-french":
      ensure => "latest"
    }
    package {"texlive-latex-extra": 
      ensure => "latest"
    }

    package {"git-core":
      ensure => latest,
    } ->
    vcsrepo { "${webapp_path}":
      ensure   => present,
      provider => git,
      source   => "https://github.com/${repo}/zds-site.git",
      revision => "${branch}",
    } ->
    file {'settings_prod':
      path => "${webapp_path}/zds/settings_prod.py",
      ensure => present,
      content => template('zds/settings_prod.erb')
    } ->
    class { 'python' :
      version    => 'system',
      pip        => true,
      dev        => true,
      virtualenv => true,
    } ->
    class { 'nodejs':
      version => "${node_version}",
    } ->
    package {
        "libxml2-dev": ensure => present;
        "python-lxml": ensure => present;
        "python-sqlparse": ensure => present;
        "libxslt1-dev": ensure => present;
        "python-mysqldb": ensure => present;
        "libmysqlclient-dev": ensure => present;
    } ->
    python::virtualenv {"${venv_path}":
        ensure       => present,
        version      => 'system',
        requirements => "${webapp_path}/requirements.txt",
        systempkgs   => true,
        distribute   => false,
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
    class { '::mysql::server':
      root_password    => "${database_password}"
    } ->
    mysql_database { "${database_name}":
      ensure  => 'present',
      charset => 'utf8',
    } ->
    exec { "syncdb":
        command => "${venv_path}/bin/python ${webapp_path}/manage.py syncdb --noinput",
        require => File['settings_prod']
    } ->
    exec { "migrate":
        command => "${venv_path}/bin/python ${webapp_path}/manage.py migrate"
    } ->
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
    } ->
    exec {"update-npm":
       command => "npm install -g npm",
       path => "/usr/local/node/node-default/bin",
    } ->
    exec {"front-prod":
        command => "npm install",
        cwd => "${webapp_path}",
        path => "/usr/local/node/node-default/bin",
        require => Exec["update-npm"]
    } ->
    exec {"front-clean":
        command => "npm run gulp -- clean",
        cwd => "${webapp_path}",
        path => ["/usr/local/node/node-default/bin","/usr/local/bin","/bin"],
        require => Exec["front-prod"]
    } ->
    exec {"front-build":
        command => "npm run gulp -- build",
        cwd => "${webapp_path}",
        path => ["/usr/local/node/node-default/bin","/usr/local/bin", "/bin"],
        require => Exec["front-clean"]
    } ->
    file { "${webapp_path}/static":
        ensure => directory,
    } ->
    file { "${venv_path}/logs":
        ensure => directory,
    }
    exec { "collectstatic":
        command => "${venv_path}/bin/python ${webapp_path}/manage.py collectstatic --noinput --clear",
        require => File['settings_prod']
    } ->
    supervisor::app { "zds-site-${id}":
      app_name     => "zds-${id}",
      command      => "${venv_path}/bin/gunicorn_start.bash",
      directory    => "${venv_path}/bin",
    }

    nginx::resource::upstream { "puppet_zds_app_${id}":
      members => [
        "unix:/tmp/gunicorn-${id}.sock"
      ],
      require => Exec["front-build"]
    } 

    nginx::resource::vhost {"vhost-${id}":
      proxy => "http://puppet_zds_app_${id}",
      server_name => ["${url}"],
      access_log => '${venv_path}/logs/nginx_access.log',
      error_log => '${venv_path}/logs/nginx_error.log',
      require => [Exec["front-build"], File["${venv_path}/logs"]]
    }

    nginx::resource::location {"${id}_static":
      ensure => present,
      vhost => "vhost-${id}",
      location => "/static/",
      www_root => "${webapp_path}",
      require => Exec["front-build"]
    }
}
