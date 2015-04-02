define zds::solr(
    $venv_path = "/opt/${name}/venv",
    $webapp_path = "/opt/${name}/zds-site",
    $id = $name,
    $solr_path = "/opt/${name}/solr",
    $repo = undef,
    $branch = undef,
) {
    file {"${solr_path}":
        ensure => directory,
        require => File["/opt/${id}/"]
    } ->
    exec { "solr-dl-${id}":
        command => "wget -P ${solr_path} http://archive.apache.org/dist/lucene/solr/4.9.0/solr-4.9.0.zip",
        path => ["/usr/bin","/usr/local/bin","/bin"],
        unless => "test -s ${solr_path}/solr-4.9.0.zip",
        timeout => 0
    } ->
    exec { "unzip-solr-${id}":
        command => "unzip solr-4.9.0.zip",
        path => ["/usr/bin","/usr/local/bin","/bin"],
        cwd => "${solr_path}",
        unless => "test -s ${solr_path}/solr-4.9.0"
    } ->
    exec { "build-schema-solr-${id}":
        command => "${venv_path}/bin/python ${webapp_path}/manage.py build_solr_schema > ${solr_path}/solr-4.9.0/example/solr/collection1/conf/schema.xml",
        path => ["/usr/bin","/usr/local/bin","/bin"],
        cwd => "${webapp_path}",
        subscribe => [Vcsrepo["${webapp_path}"], Python::Virtualenv["${venv_path}"]]
    } ->
    supervisor::app { "zds-solr-${id}":
      app_name     => "solr-${id}",
      command      => "java -jar start.jar",
      directory    => "${solr_path}/solr-4.9.0/example/",
      require => Exec["build-schema-solr-${id}"]
    } ->
    cron::hourly{ "solr_update-${id}": 
        minute => '20',
        user => 'root',
        command => "${venv_path}/bin/python ${webapp_path}/manage.py update_index",
        subscribe => Vcsrepo["${webapp_path}"],
        require => Exec["build-schema-solr-${id}"]
    }
}
