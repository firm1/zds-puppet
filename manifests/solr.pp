class zds::solr(
    $venv_path = $zds::venv_path,
    $webapp_path = $zds::webapp_path,
    $solr_path = $zds::solr_path,
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

    class { 'java':
      distribution => 'jdk',
    }

    file {"${solr_path}":
        ensure => directory
    } ->
    exec { 'solr-dl':
        command => "wget -P ${solr_path} http://archive.apache.org/dist/lucene/solr/4.9.0/solr-4.9.0.zip",
        path => ["/usr/bin","/usr/local/bin","/bin"],
        unless => "test -s ${solr_path}/solr-4.9.0.zip",
        timeout => 0
    } ->
    exec { 'unzip-solr':
        command => "unzip solr-4.9.0.zip",
        path => ["/usr/bin","/usr/local/bin","/bin"],
        cwd => "${solr_path}",
        unless => "test -s ${solr_path}/solr-4.9.0"
    } ->
    file {'solr_bash':
      path => "${solr_path}/solr.bash",
      ensure => present,
      content => template('zds/solr_bash.erb'),
      mode => "0755"
    } ->
    exec { 'build-schema-solr':
        command => "${venv_path}/bin/python ${webapp_path}/manage.py build_solr_schema > ${solr_path}/solr-4.9.0/example/solr/collection1/conf/schema.xml",
        path => ["/usr/bin","/usr/local/bin","/bin"],
        cwd => "${webapp_path}",
        require => File['settings_prod']
    } ->
    cron::hourly{ 'solr_update': 
        minute => '20',
        user => 'root',
        command => "${venv_path}/bin/python ${webapp_path}/manage.py update_index",
        require => Exec['build-schema-solr']
    }
}
