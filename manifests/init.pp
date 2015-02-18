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
    vcsrepo { "/opt/${id}/zds-site":
      ensure   => present,
      provider => git,
      source   => "https://github.com/${repo}/zds-site.git",
      revision => "${branch}",
    } ->
    file {'settings_prod':
      path => "/opt/${id}/zds-site/zds/settings_prod.py",
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
      version => 'v0.10.36',
    } ->
    package {
        "libxml2-dev": ensure => present;
        "python-lxml": ensure => present;
        "python-sqlparse": ensure => present;
        "libxslt1-dev": ensure => present;
        "python-mysqldb": ensure => present;
        "libmysqlclient-dev": ensure => present;
    } ->
    python::virtualenv {"/opt/${id}/venv":
        ensure       => present,
        version      => 'system',
        requirements => "/opt/${id}/zds-site/requirements.txt",
        systempkgs   => true,
        distribute   => false,
    } ->
    file {'gunicorn_start':
      path => "/opt/${id}/venv/bin/gunicorn_start.bash",
      ensure => present,
      content => template('zds/gunicorn_start.erb'),
      mode => "0755"
    } ->
    python::pip { 'MySQL-python':
        pkgname => 'MySQL-python',
        ensure  => 'present',
        virtualenv => "/opt/${id}/venv"
    } ->
    class { '::mysql::server':
      root_password    => 'SuperPassword'
    } ->
    mysql_database { 'zdsbase':
      ensure  => 'present',
      charset => 'utf8',
    } ->
    exec { "syncdb":
        command => "/opt/${id}/venv/bin/python /opt/${id}/zds-site/manage.py syncdb --noinput",
        require => File['settings_prod']
    } ->
    exec { "migrate":
        command => "/opt/${id}/venv/bin/python /opt/${id}/zds-site/manage.py migrate"
    } ->
    python::gunicorn { "vhost-${id}":
        ensure      => present,
        virtualenv  => "/opt/${id}/venv",
        mode        => 'wsgi',
        dir         => "/opt/${id}/zds-site/",
        bind        => "unix:/tmp/gunicorn-${id}.sock",
        environment => 'prod',
        appmodule   => 'zds',
        osenv       => { 'DBHOST' => 'localhost' },
        timeout     => 30,
    } ->
    exec {"update-npm":
       command => "npm install -g npm",
       path => "/usr/local/node/node-default/bin",
    } ->
    exec {"front-prod":
        command => "npm install",
        cwd => "/opt/${id}/zds-site/",
        path => "/usr/local/node/node-default/bin",
        require => Exec["update-npm"]
    } ->
    exec {"front-clean":
        command => "npm run gulp -- clean",
        cwd => "/opt/${id}/zds-site/",
        path => ["/usr/local/node/node-default/bin","/usr/local/bin","/bin"],
        require => Exec["front-prod"]
    } ->
    exec {"front-build":
        command => "npm run gulp -- build",
        cwd => "/opt/${id}/zds-site/",
        path => ["/usr/local/node/node-default/bin","/usr/local/bin", "/bin"],
        require => Exec["front-clean"]
    } ->
    file { "/opt/${id}/zds-site/static":
        ensure => directory,
    }
    exec { "collectstatic":
        command => "/opt/${id}/venv/bin/python /opt/${id}/zds-site/manage.py collectstatic --noinput --clear",
        require => File['settings_prod']
    } ->
    supervisor::app { "zds-site-${id}":
      app_name     => "zds-${id}",
      command      => "/opt/${id}/venv/bin/gunicorn_start.bash",
      directory    => "/opt/${id}/venv/bin",
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
      require => Exec["front-build"]
    }

    nginx::resource::location {"${id}_static":
      ensure => present,
      vhost => "vhost-${id}",
      location => "/static/",
      www_root => "/opt/${id}/zds-site/",
      require => Exec["front-build"]
    }
}
