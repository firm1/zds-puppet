class zds::database(
    $database_name = $zds::database_name,
    $database_password = $zds::database_password,
) {
    class { '::mysql::server':
      root_password    => "${database_password}"
    } ->
    mysql_database { "${database_name}":
      ensure  => 'present',
      charset => 'utf8',
    }
}
