class zds::params {
    #$zds_params = hiera('zds', "{'url':'vps137741.ovh.net', 'repo':'zestedesavoir', 'branch':'dev', 'id':'1'}")
    #validate_hash($zds_params)

    #$url = $zds_params['url']
    #$repo = $zds_params['repo']
    #$branch = $zds_params['branch']
    #$id = $zds_params['id']

    $url = "vps137741.ovh.net"
    $repo = "Situphen"
    $branch = "update-npm-dependencies"
    $id = "testnode"
}
