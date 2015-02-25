class zds::front(
    $venv_path = $zds::venv_path,
    $webapp_path = $zds::webapp_path,
    $id = $zds::id,
    $node_version = $zds::node_version,
    $primary_color = $zds::primary_color,
    $secondary_color = $zds::secondary_color,
    $side_bg = $zds::side_bg,
    $side_hv = $zds::side_hv,
    $body_bg = $zds::body_bg,
    $header_hv = $zds::header_hv,
    $logo_url = $zds::logo_url,
) {

    class { 'nodejs':
      version => "${node_version}",
    }

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
    exec { 'logo':
        command => "wget -O ${webapp_path}/assets/images/logo.png ${logo_url}",
        path => ["/usr/bin","/usr/local/bin","/bin"],
    } ->
    exec { 'logo2x':
        command => "wget -O ${webapp_path}/assets/images/logo@2x.png ${logo_url}",
        path => ["/usr/bin","/usr/local/bin","/bin"],
    } ->
    exec {"update-npm":
       command => "npm install -g npm",
       path => "/usr/local/node/node-default/bin",
       require => [Class['nodejs'], Exec['logo']]
    } ->
    exec {"front-prod":
        command => "npm install",
        cwd => "${webapp_path}",
        path => ["/usr/local/node/node-default/bin","/usr/local/bin","/bin", "/usr/bin"],
        environment => ["HOME=/root"],
        require => Exec["update-npm"],
        subscribe => Vcsrepo["${webapp_path}"],
        timeout => 0
    } ->
    exec {"front-clean":
        command => "npm run gulp -- clean",
        cwd => "${webapp_path}",
        path => ["/usr/local/node/node-default/bin","/usr/local/bin","/bin"],
        subscribe => Exec["front-prod"],
        require => Exec["front-prod"]
    } ->
    exec {"front-build":
        command => "npm run gulp -- build",
        cwd => "${webapp_path}",
        path => ["/usr/local/node/node-default/bin","/usr/local/bin", "/bin"],
        subscribe => Exec["front-clean"],
        require => Exec["front-clean"]
    } ->
    file { "${webapp_path}/static":
        ensure => directory,
        mode => "0755"
    } ->
    exec { "collectstatic":
        command => "${venv_path}/bin/python ${webapp_path}/manage.py collectstatic --noinput --clear",
        cwd => "${webapp_path}",
        subscribe => Exec["front-clean"],
        require => [Exec['front-build'], File["${webapp_path}/static"], Python::Virtualenv["${venv_path}"]]
    }
}
