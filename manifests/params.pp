class zds::params {
    $zds_params = hiera_hash('zds')
    validate_hash($zds_params)

    $url = $zds_params['site']['url']
    $repo = $zds_params['repo']['author']
    $branch = $zds_params['repo']['branch']
    $id = $zds_params['site']['id']

    $database_name = $zds_params['database']['name']
    $database_host = $zds_params['database']['host']
    $database_user = $zds_params['database']['user']
    $database_password = $zds_params['database']['password']

    $venv_path = "/opt/${id}/venv"
    $webapp_path = "/opt/${id}/zds-site"

    $zds_front = $zds_params['front']
    $node_version = $zds_front['node_version']
    $primary_color = $zds_front['color']['primary']
    $secondary_color = $zds_front['color']['secondary']
    $body_bg = $zds_front['color']['body_bg']
    $header_hv = $zds_front['color']['header_hv']
    $side_bg = $zds_front['color']['side_bg']
    $side_hv = $zds_front['color']['side_hv']

    $pandoc_repo = "jgm"
    $pandoc_release_tag = "1.13"
    $pandoc_dest = ""
    
    $zds_settings = $zds_params['settings']
}
