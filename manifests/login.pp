# 
class elastic_hpc::login (

) {
  require profile::slurm::submitter

   file { '/bin/sq':
    ensure => file,
    source => 'puppet:///modules/elastic_hpc/slurm/sq',
    owner  => 'slurm',
    group  => 'slurm',
    mode   => '0755',
  }

 file { '/sbin/automated-undrain':
    ensure => file,
    source => 'puppet:///modules/elastic_hpc/slurm/automated-undrain',
    owner  => 'slurm',
    group  => 'slurm',
    mode   => '0755',
  }

 file { '/bin/sinfo-alloc':
    ensure => file,
    source => 'puppet:///modules/elastic_hpc/slurm/sinfo-alloc',
    owner  => 'slurm',
    group  => 'slurm',
    mode   => '0755',
  }


}
