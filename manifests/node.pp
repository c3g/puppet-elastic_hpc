# 
class elastic_hpc::node (

) {
  require profile::slurm::node

  file { '/etc/slurm/epilog.d/40-epilog.sh':
    ensure => file,
    source => 'puppet:///modules/elastic_hpc/slurm/40-epilog.sh',
    owner  => 'slurm',
    group  => 'slurm',
    mode   => '0755',
  }

  # File read by 40-epilog.sh to check that /project is still available.
  # Only touched when /project is mounted to avoid creating it on local disk.
  exec { 'touch /project/testfile':
    creates => '/project/testfile',
    onlyif  => 'mountpoint -q /project',
    path    => ['/bin', '/usr/bin'],
  }
}
