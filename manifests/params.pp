class zds::params {
    #$zds_params = hiera('zds', "{'url':'vps137741.ovh.net', 'repo':'zestedesavoir', 'branch':'dev', 'id':'1'}")
    #validate_hash($zds_params)

    #$url = $zds_params['url']
    #$repo = $zds_params['repo']
    #$branch = $zds_params['branch']
    #$id = $zds_params['id']

    $url = "vps137741.ovh.net"
    $repo = "zestedesavoir"
    $branch = "dev"
    $id = "daily"
    $database_name = "zdsbase"
    $database_host = "localhost"
    $database_user = "root"
    $database_password = "SuperPassword"
    $venv_path = "/opt/${id}/venv"
    $webapp_path = "/opt/${id}/zds-site"
    $node_version = "v0.10.36"
    $pandoc_repo = "jgm"
    $pandoc_release_tag = "1.13"
    $pandoc_dest = "/opt/${id}/pandoc"
}
