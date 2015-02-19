class zds::params {
    $zds_params = hiera_hash('zds')
    validate_hash($zds_params)

    $url = $zds_params['site']['url']
    $repo = $zds_params['repo']['author']
    $branch = $zds_params['repo']['branch']
    $id = $zds_params['site']['id']

    $database_name = ['database']['name']
    $database_host = ['database']['host']
    $database_user = ['database']['user']
    $database_password = ['database']['password']

    $venv_path = "/opt/${id}/venv"
    $webapp_path = "/opt/${id}/zds-site"
    $node_version = $zds_params['front']['node_version']
    $pandoc_repo = "jgm"
    $pandoc_release_tag = "1.13"
    $pandoc_dest = ""
    
    $zds_settings = $zds_params['settings']
}
