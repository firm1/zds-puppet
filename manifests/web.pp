define zds::web(
    $venv_path = "/opt/${name}/venv",
    $webapp_path = "/opt/${name}/zds-site",
    $id = $name,
    $repo = undef,
    $branch = undef,
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
      require => File["${venv_path}/logs"],
      proxy_redirect => "http://${url}/ http://${url}:${id}/",
      location_cfg_append  => {
        add_header => {
          "'Access-Control-Allow-Origin'"  => "'*'",
          "'Access-Control-Allow-Methods'"  => "'POST, GET, OPTIONS , PUT'",
          "'Access-Control-Allow-Headers'"  => "'Authorization,Content-Type,Accept,Origin,User-Agent,DNT,Cache-Control,X-Mx-ReqToken,Keep-Alive,X-Requested-With,If-Modified-Since'"
        },
      },
    }

    nginx::resource::location {"static_${id}":
      ensure => present,
      location => "/static/",
      vhost => "vhost-${id}",
      location_alias => "${webapp_path}/static/",
    }

    nginx::resource::location {"doc_${id}":
      ensure => present,
      location => "/doc/",
      vhost => "vhost-${id}",
      location_alias => "${webapp_path}/doc/build/html/",
    }
}
