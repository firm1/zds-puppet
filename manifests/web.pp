define zds::web(
    $venv_path = "/opt/${name}/venv",
    $webapp_path = "/opt/${name}/zds-site",
    $id = $name,
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
      listen_port => "${id}",
      server_name => ["${url}"],
      access_log => "${venv_path}/logs/nginx_access.log",
      error_log => "${venv_path}/logs/nginx_error.log",
      subscribe => Exec["collectstatic"],
      require => File["${venv_path}/logs"]
    }

    nginx::resource::location {"static_${id}":
      ensure => present,
      location => "/static/",
      vhost => "vhost-${id}",
      location_alias => "${webapp_path}/static/",
      subscribe => Exec["collectstatic"],
    }

    nginx::resource::location {"doc_${id}":
      ensure => present,
      location => "/doc/",
      vhost => "vhost-${id}",
      location_alias => "${webapp_path}/doc/build/html/",
      subscribe => Exec["collectstatic"],
    }

}
