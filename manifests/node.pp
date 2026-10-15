# 
class elastic_hpc::node (

) {
  file { '/etc/slurm/epilog.d/40-epilog.sh':
    ensure => file,
    source => 'puppet:///modules/elastic_hpc/slurm/40-epilog.sh',
    owner  => 'slurm',
    group  => 'slurm',
    mode   => '0755',
  }
}
