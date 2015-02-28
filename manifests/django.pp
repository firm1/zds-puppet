define zds::django (
    $repos = $zds::params::repos,
    $database_name = $zds::database_name,
    $database_host = $zds::database_host,
    $database_user = $zds::database_user,
    $database_password = $zds::database_password,
    $venv_path = "/opt/${name}/venv",
    $webapp_path = "/opt/${name}/zds-site",
    $id = $name,
    $repo = undef,
    $branch = undef,
    $zds_settings = $zds::params::zds_settings,
    $url = $zds::params::url,
    $pandoc_repo = $zds::params::pandoc_repo,
    $pandoc_release_tag = $zds::params::pandoc_release_tag,
    $pandoc_dest = $zds::params::pandoc_dest,
) {
    include supervisor

    vcsrepo { "${webapp_path}":
      ensure   => latest,
      provider => git,
      source   => "https://github.com/${repo}/zds-site.git",
      revision => "${branch}",
    } ->
    file {"settings_prod_${id}":
      path => "${webapp_path}/zds/settings_prod.py",
      ensure => present,
      content => template('zds/settings_prod.erb'),
      mode => "0755"
    } ->
    python::virtualenv {"${venv_path}":
        ensure       => present,
        version      => 'system',
        requirements => "${webapp_path}/requirements.txt",
        systempkgs   => true,
        distribute   => false,
        subscribe => Vcsrepo["${webapp_path}"],
    } ->
    python::requirements {"${webapp_path}/requirements-dev.txt":
       virtualenv => "${venv_path}",
    } ->
    file { "${venv_path}/logs":
        ensure => directory,
        require => File["settings_prod_${id}"],
        mode => "0755"
    } ->
    python::pip { "gunicorn_env_${id}":
        pkgname => 'gunicorn',
        ensure  => 'present',
        virtualenv => "${venv_path}"
    } ->
    file {"gunicorn_start_${id}":
      path => "${venv_path}/bin/gunicorn_start.bash",
      ensure => present,
      content => template('zds/gunicorn_start.erb'),
      mode => "0755"
    } ->
    python::pip { "MySQL-python-${id}":
        pkgname => 'MySQL-python',
        ensure  => 'present',
        virtualenv => "${venv_path}"
    } ->
    exec { "syncdb-${id}":
        command => "${venv_path}/bin/python ${webapp_path}/manage.py syncdb --noinput",
        subscribe => File["settings_prod"],
        require => File["settings_prod_${id}"]
    }
    exec { "migrate-${id}":
        command => "${venv_path}/bin/python ${webapp_path}/manage.py migrate",
        subscribe => File["settings_prod_${id}"],
        require => Exec["syncdb-${id}"]
    }
    exec { "fixtures-${id}":
        command => "${venv_path}/bin/python ${webapp_path}/manage.py loaddata fixtures/*.yaml",
        cwd => "${webapp_path}",
        subscribe => File["settings_prod"],
        require => Exec["migrate-${id}"]
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
        subscribe => [Vcsrepo["${webapp_path}"], File["settings_prod_${id}"]]
    } ->
    supervisor::app { "zds-site-${id}":
      app_name     => "zds-${id}",
      command      => "${venv_path}/bin/gunicorn_start.bash",
      directory    => "${venv_path}/bin",
      subscribe => [Vcsrepo["${webapp_path}"], File["settings_prod_${id}"]]
    }
}
