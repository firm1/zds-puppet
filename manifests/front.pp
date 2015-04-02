define zds::front(
    $venv_path = "/opt/${name}/venv",
    $webapp_path = "/opt/${name}/zds-site",
    $id = $name,
    $repo = undef,
    $branch = undef,
    $primary_color = $zds::primary_color,
    $secondary_color = $zds::secondary_color,
    $side_bg = $zds::side_bg,
    $side_hv = $zds::side_hv,
    $body_bg = $zds::body_bg,
    $header_hv = $zds::header_hv,
    $logo_url = $zds::logo_url,
) {

    $a = file("${webapp_path}/assets/scss/variables/_colors.scss",'/dev/null')
    if($a != '') {
    file_line { 'primary_color':
       path  => "${webapp_path}/assets/scss/variables/_colors.scss",
       line  => "\$color-primary: ${primary_color};",
       match => '^\$color-primary*',
    } ->
    file_line { 'secondary_color':
       path  => "${webapp_path}/assets/scss/variables/_colors.scss",
       line  => "\$color-secondary: ${secondary_color};",
       match => '^\$color-secondary*',
    } ->
    file_line { 'side_bg':
       path  => "${webapp_path}/assets/scss/variables/_colors.scss",
       line  => "\$color-sidebar-background: ${side_bg};",
       match => '^\$color-sidebar-background*',
    } ->
    file_line { 'side_hv':
       path  => "${webapp_path}/assets/scss/variables/_colors.scss",
       line  => "\$color-sidebar-hover: ${side_hv};",
       match => '^\$color-sidebar-hover*',
    } ->
    file_line { 'body_bg':
       path  => "${webapp_path}/assets/scss/variables/_colors.scss",
       line  => "\$color-body-background: ${body_bg};",
       match => '^\$color-body-background*',
    } ->
    file_line { 'header_hv':
       path  => "${webapp_path}/assets/scss/variables/_colors.scss",
       line  => "\$color-header-hover: ${header_hv};",
       match => '^\$color-header-hover*',
    } 
    }

    exec {"front-prod-${id}":
        command => "npm install",
        cwd => "${webapp_path}",
        path => ["/usr/local/node/node-default/bin","/usr/local/bin","/bin", "/usr/bin"],
        environment => ["HOME=/root"],
        require => Exec["update-npm"],
        subscribe => Vcsrepo["${webapp_path}"],
        timeout => 0
    }
    exec {"front-clean-${id}":
        command => "npm run gulp -- clean",
        cwd => "${webapp_path}",
        path => ["/usr/local/node/node-default/bin","/usr/local/bin","/bin"],
        require => Exec["front-prod-${id}"]
    }
    exec {"front-build-${id}":
        command => "npm run gulp -- build",
        cwd => "${webapp_path}",
        path => ["/usr/local/node/node-default/bin","/usr/local/bin", "/bin"],
        require => Exec["front-clean-${id}"]
    }
    file { "${webapp_path}/static":
        ensure => directory,
        mode => "0755",
        require => Exec["front-build-${id}"]
    }
    exec { "collectstatic-${id}":
        command => "${venv_path}/bin/python ${webapp_path}/manage.py collectstatic --noinput --clear",
        cwd => "${webapp_path}",
        require => [Exec["front-build-${id}"], File["${webapp_path}/static"], Python::Virtualenv["${venv_path}"]]
    }
    exec {"docu-${id}":
        command => "make html",
        cwd => "${webapp_path}/doc/",
        path => ["/usr/bin/", "/bin", "/usr/local/bin", "${venv_path}/bin"],
        require => Python::Virtualenv["${venv_path}"]
    }
}
