define zds::core(
    $venv_path = "/opt/${name}/venv",
    $webapp_path = "/opt/${name}/zds-site",
    $id = $name,
    $repo = undef,
    $branch = undef,
    $url = $zds::url,
) {

    file {["/opt/${id}/"]:
        ensure => directory,
    }

}
