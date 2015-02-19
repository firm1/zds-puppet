class zds::pandoc(
    $pandoc_repo = $zds::pandoc_repo,
    $pandoc_release_tag = $zds::pandoc_release_tag,
    $pandoc_dest = $zds::pandoc_dest,
) {
   
    package {"texlive":
      ensure => "latest"
    }
    package {"texlive-xetex":
      ensure => "latest"
    }
    package {"texlive-lang-french":
      ensure => "latest"
    }
    package {"texlive-latex-extra":
      ensure => "latest"
    }

    case $::osfamily {
      'Debian': {
        exec {'dl-pandoc':
          command => "wget -P /tmp https://github.com/jgm/pandoc/releases/download/1.13.2/pandoc-1.13.2-1-amd64.deb",
          path => ["/usr/bin","/usr/local/bin","/bin"],
          unless => "test -s /tmp/pandoc-1.13.2-1-amd64.deb"
        }
        package {'pandoc':
          ensure => present,
          provider => "dpkg",
          source => "/tmp/pandoc-1.13.2-1-amd64.deb",
          require => Exec["dl-pandoc"]
        }
      }
      default: {

        group {"zds":
          ensure => present,
        }
        vcsrepo { "${pandoc_dest}":
          ensure   => present,
          provider => git,
          source   => "https://github.com/${pandoc_repo}/pandoc.git",
          revision => "${pandoc_release_tag}",
        } ->
        user {"cabal":
            ensure => "present",
            managehome => true,
            gid => "zds",
            require => Group['zds'],
        }
        exec { "cabal-update":
            command => "cabal update",
            cwd => "${pandoc_dest}",
            user => cabal,
            group => zds,
            path => ["/usr/bin","/usr/local/bin","/bin"],
            environment => ["HOME=/home/cabal"],
            require => [Package['haskell-platform'], User['cabal']]
        }
        exec { "cabal-install":
            command => "cabal install --force-reinstalls --upgrade-dependencies --only-dependencies",
            #command => "cabal install --only-dependencies",
            cwd => "${pandoc_dest}",
            user => cabal,
            group => zds,
            timeout => 0,
            path => ["/usr/bin","/usr/local/bin","/bin"],
            environment => ["HOME=/home/cabal"],
            require => Exec['cabal-update']
        }
        exec { "cabal-conf":
            command => "cabal configure",
            cwd => "${pandoc_dest}",
            user => cabal,
            group => zds,
            path => ["/usr/bin","/usr/local/bin","/bin"],
            environment => ["HOME=/home/cabal"],
            require => Exec['cabal-install']
        }
        exec { "cabal-build":
            command => "cabal build",
            cwd => "${pandoc_dest}",
            user => cabal,
            group => zds,
            path => ["/usr/bin","/usr/local/bin","/bin"],
            environment => ["HOME=/home/cabal"],
            require => Exec['cabal-conf']
        }
      }
    }
}
