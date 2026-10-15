class elastic_hpc::cvmfs::client ( ) {
  require profile::cvmfs::client

  file { '/etc/cvmfs/config.d/ref.mugqic.local':
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/elastic_hpc/cvmfs/ref.mugqic.local',
    mode   => '0644',
  }

  file { '/etc/cvmfs/config.d/soft.mugqic.local':
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/elastic_hpc/cvmfs/soft.mugqic.local',
    mode   => '0644',
  }
}
