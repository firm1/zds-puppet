class zds::params {
    $zds_params = hiera_hash('zds')
    validate_hash($zds_params)

    $url = $zds_params['url']
    $repo = $zds_params['repo'],
    $branch = $zds_params['branch'],
    $id = $zds_params['id'],
}