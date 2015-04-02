define zds::database(
    $database_name = $zds::database_name,
    $repo = undef,
    $branch = undef,
    $id = $name,
) {
    mysql_database { "${database_name}-${id}":
      ensure  => 'present',
      charset => 'utf8',
    }
}
