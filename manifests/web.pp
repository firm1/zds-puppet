class zds::web(
    $venv_path = $zds::venv_path,
    $webapp_path = $zds::webapp_path,
    $id = $zds::id,
    $url = $zds::url,
) {

    include nginx

    nginx::resource::upstream { "puppet_zds_app_${id}":
      members => [
        "unix:/tmp/gunicorn-${id}.sock"
      ]
    }

    nginx::resource::vhost {"vhost-${id}":
      proxy => "http://puppet_zds_app_${id}",
      server_name => ["${url}"],
      access_log => "${venv_path}/logs/nginx_access.log",
      error_log => "${venv_path}/logs/nginx_error.log",
      subscribe => Exec["collectstatic"],
      require => File["${venv_path}/logs"]
    }

    nginx::resource::location {"${id}_static":
      ensure => present,
      vhost => "vhost-${id}",
      location => "/static/",
      www_root => "${webapp_path}",
      subscribe => Exec["collectstatic"],
    }
}
