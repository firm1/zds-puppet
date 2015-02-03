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
	$id = $zds::params::id
) inherits ::zds::params {

    include nginx
    include python
    include mysql
    include nodejs
  
    package {
      "git-core": ensure => latest;
      "texlive": ensure => latest;
      "texlive-xetex": ensure => latest;
      "texlive-lang-french": ensure => latest;
      "texlive-latex-extra": ensure => latest;
    }

    package { 'npm':
      ensure   => latest,
      provider => 'npm',
    }

    exec {"git-clone":
      command => "git clone -b ${branch} --single-branch git://github.com/${repo}/zds-site.git /opt/${id}/zds-site",
      creates => "/opt/${id}/zds-site",
      require => [Package['git-core'], File['/opt/${id}']]
    }

    python::virtualenv {'/opt/${id}/venv':
      ensure       => present,
      version      => 'system',
      requirements => '/opt/${id}/zds-site/requirements.txt',
      systempkgs   => true,
      distribute   => false,
    }

    python::gunicorn { 'vhost-${id}' :
      ensure      => present,
      virtualenv  => '/opt/${id}/venv',
      mode        => 'wsgi',
      dir         => '/opt/${id}/zds-site/',
      bind        => 'unix:/tmp/gunicorn.socket',
      environment => 'prod',
      appmodule   => 'zds',
      osenv       => { 'DBHOST' => 'localhost' },
      timeout     => 30,
      template    => 'python/gunicorn.erb',
    }

    nginx::resource::vhost { '${url}/${id}':
      www_root => '/opt/${id}/zds-site',
      require => Exec['git-clone']
    }	
}
