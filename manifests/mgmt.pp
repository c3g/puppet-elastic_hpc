# Bind mount mgmt volumes on directories managed by other modules
#
# Each entry is passed to elastic_hpc::bind_mount. The volumes must exist
# (mgmt volumes in main.tf with bind_mount = false). Example:
#
# elastic_hpc::mgmt::bind_mounts:
#   slurm:
#     source: /mnt/mgmt/slurm
#     target: /var/spool/slurm
#     services: [slurmctld]
#     migrate_data: false
class elastic_hpc::mgmt (
  Hash[String[1], Hash] $bind_mounts = {},
) {
  $bind_mounts.each |$mount_name, $params| {
    elastic_hpc::bind_mount { $mount_name:
      * => $params,
    }
  }
}
