# Puppet Elastic HPC

This repo contains a Puppet module complementing
[puppet-magic_castle](https://github.com/ComputeCanada/puppet-magic_castle) for the
C3G Elastic HPC project. It provides additional classes that are attributed to
Magic Castle instances based on their tags, in the same way as the `profile::` classes
of puppet-magic_castle.

Classes are included by adding them to the
[`magic_castle::site::tags`](https://github.com/ComputeCanada/puppet-magic_castle#magic_castlesite)
mapping in the cluster hieradata (`config.yaml`). Since this mapping is merged with the
default one, `lookup_options` must specify a `deep` merge:

```yaml
lookup_options:
  magic_castle::site::tags:
    merge: 'deep'

magic_castle::site::tags:
  login:
    - elastic_hpc::cvmfs::client
    - elastic_hpc::login
  mgmt:
    - elastic_hpc::mgmt
  node:
    - elastic_hpc::node
    - elastic_hpc::cvmfs::client
```

The parameters of the classes can be customized by defining values in the hieradata.
The following sections list the available classes, defined types and templates, their
role and their parameters.
- [`elastic_hpc`](#elastic_hpc)
- [`elastic_hpc::bind_mount`](#elastic_hpcbind_mount)
- [`elastic_hpc::cvmfs::client`](#elastic_hpccvmfsclient)
- [`elastic_hpc::login`](#elastic_hpclogin)
- [`elastic_hpc::mgmt`](#elastic_hpcmgmt)
- [`elastic_hpc::node`](#elastic_hpcnode)
- [`elastic_hpc/alien_cache.conf.epp`](#elastic_hpcalien_cacheconfepp)

For classes with parameters, a folded **default values** subsection provides the default
value of each parameter as it would be defined in hieradata.

## `elastic_hpc`

Base class of the module. It currently does not manage any resource.

## `elastic_hpc::bind_mount`

Defined type that bind mounts a Magic Castle volume on a directory that is already managed
by another module (i.e.: `/var/spool/slurm` managed by `profile::slurm`).

The volume must be declared in `main.tf` with `bind_mount = false`, so that
[`profile::volumes`](https://github.com/ComputeCanada/puppet-magic_castle#profilevolumes)
only mounts it under `/mnt/<tag>/<name>`. No `File` resource is declared on the target
to avoid duplicate declarations; the target directory is created with `mkdir -p` if missing.
Ownership and mode set on the target by the module managing it apply to the volume, since
the `File` resource is ordered after the mount.

The listed services are ordered after the bind mount, so they only start once it is in place.
When `migrate_data` is true and the volume is still empty, the services are stopped and the
existing content of the target is copied on the volume with `rsync -aHAX` before mounting.

This type is generally not used directly, but through [`elastic_hpc::mgmt`](#elastic_hpcmgmt).

### parameters

| Variable       | Description                                                                         | Type                 |
| :------------- | :---------------------------------------------------------------------------------- | :------------------- |
| `source`       | Path where the volume is mounted (i.e.: `/mnt/mgmt/slurm`)                           | Stdlib::Absolutepath |
| `target`       | Directory on which the volume is bind mounted. Defaults to the resource title        | Stdlib::Absolutepath |
| `services`     | Services that are started only once the bind mount is in place                      | Array[String[1]]     |
| `migrate_data` | Copy the existing content of `target` on the volume before mounting, if it is empty | Boolean              |

<details>
<summary>default values</summary>

```puppet
elastic_hpc::bind_mount { '<target>':
  source       => <required>,
  target       => $title,
  services     => [],
  migrate_data => false,
}
```
</details>

<details>
<summary>example</summary>

```puppet
elastic_hpc::bind_mount { '/var/spool/slurm':
  source       => '/mnt/mgmt/slurm',
  services     => ['slurmctld'],
  migrate_data => true,
}
```
</details>

### dependencies

When `migrate_data` is true, the `rsync` package is installed.

## `elastic_hpc::cvmfs::client`

This class adds the CVMFS client configuration of the C3G MUGQIC repositories:
- `/etc/cvmfs/config.d/ref.mugqic.local`
- `/etc/cvmfs/config.d/soft.mugqic.local`

Both files define the `CVMFS_SERVER_URL` of the repositories (Calcul Québec S3 stratum
through stunnel, with the C3G west stratum 1 as fallback).

The repositories still need to be listed in
[`profile::cvmfs::client`](https://github.com/ComputeCanada/puppet-magic_castle#profilecvmfsclient)
parameters to be mounted.

<details>
<summary>example</summary>

```yaml
magic_castle::site::tags:
  login:
    - elastic_hpc::cvmfs::client
  node:
    - elastic_hpc::cvmfs::client

profile::cvmfs::client::repositories: ['cvmfs-config.computecanada.ca', 'soft.computecanada.ca', 'soft.mugqic']
profile::cvmfs::client::alien_cache_repositories: ['ref.mugqic']
profile::cvmfs::client::alien_cache_repo_template: "elastic_hpc/alien_cache.conf"
profile::cvmfs::alien_cache::alien_fs_root: "/project"
```
</details>

### dependencies

When `elastic_hpc::cvmfs::client` is included, these classes are included too:
- [`profile::cvmfs::client`](https://github.com/ComputeCanada/puppet-magic_castle#profilecvmfsclient)

## `elastic_hpc::login`

This class installs Slurm helper scripts on login nodes:

| Path                     | Description                                                                                       |
| :----------------------- | :------------------------------------------------------------------------------------------------ |
| `/bin/sq`                | `squeue` wrapper with a wider output format (cpus, memory, full job name, priority, submit time)   |
| `/bin/sinfo-alloc`       | `sinfo` per node view of the `cpubase_bycore_b1` partition, including allocated/idle CPUs         |
| `/sbin/automated-undrain`| Reboots nodes of `cpubase_bycore_b1` in `error` state, canceling their jobs. Dry run unless `-y` |

### dependencies

When `elastic_hpc::login` is included, these classes are included too:
- `profile::slurm::submitter` (see [`profile::slurm::base`](https://github.com/ComputeCanada/puppet-magic_castle#profileslurmbase))

## `elastic_hpc::mgmt`

This class bind mounts mgmt volumes on directories managed by other modules,
by declaring an [`elastic_hpc::bind_mount`](#elastic_hpcbind_mount) for each entry
of `bind_mounts`. It is used to store the Slurm state and the Prometheus database on
persistent volumes.

The volumes must be declared in `main.tf` with `bind_mount = false`:

```hcl
volumes = {
  mgmt = {
    slurm      = { size = 100, mode = "0755", bind_mount = false }
    prometheus = { size = 100, mode = "0755", bind_mount = false }
  }
}
```

### parameters

| Variable      | Description                                                                                         | Type                    |
| :------------ | :-------------------------------------------------------------------------------------------------- | :---------------------- |
| `bind_mounts` | Mapping name - [`elastic_hpc::bind_mount`](#elastic_hpcbind_mount) parameters                       | Hash[String[1], Hash]   |

<details>
<summary>default values</summary>

```yaml
elastic_hpc::mgmt::bind_mounts: {}
```
</details>

<details>
<summary>example</summary>

```yaml
magic_castle::site::tags:
  mgmt:
    - elastic_hpc::mgmt

elastic_hpc::mgmt::bind_mounts:
  slurm:
    source: /mnt/mgmt/slurm
    target: /var/spool/slurm
    services: [slurmctld]
    migrate_data: false
  prometheus:
    source: /mnt/mgmt/prometheus
    target: /var/lib/prometheus
    services: [prometheus]
    migrate_data: false
```
</details>

## `elastic_hpc::node`

This class installs a Slurm epilog script on compute nodes,
`/etc/slurm/epilog.d/40-epilog.sh`. The script drains the node when one of these
health checks fails:
- `/project/testfile` cannot be read (project filesystem is gone);
- a file of `/cvmfs/soft.mugqic` cannot be evicted and read again (`soft.mugqic` is broken).

The class also creates `/project/testfile` with `touch` when it does not exist. This only
happens when `/project` is a mountpoint, so the file is never created on the node local disk.

Drained nodes can be put back in service with
[`automated-undrain`](#elastic_hpclogin) from the login node.

### dependencies

When `elastic_hpc::node` is included, these classes are included too:
- [`profile::slurm::node`](https://github.com/ComputeCanada/puppet-magic_castle#profileslurmnode)

## `elastic_hpc/alien_cache.conf.epp`

CVMFS configuration template for repositories using an alien cache. It defines a tiered
cache with an upper layer on local disk (`/localscratch/cvmfs`) and a lower layer
on the cluster filesystem alien cache (`/<alien_fs_root>/<alien_folder_name>/@fqrn@`).

It is used by
[`profile::cvmfs::client`](https://github.com/ComputeCanada/puppet-magic_castle#profilecvmfsclient)
for the repositories listed in `alien_cache_repositories`. Since the template is rendered
by `profile::cvmfs::client`, its own parameters are read from hieradata with `lookup()`.

### parameters

| Variable                                    | Description                                                    | Type    |
| :------------------------------------------ | :------------------------------------------------------------- | :------ |
| `elastic_hpc::cvmfs::localdisk_quota_limit` | Quota of the local disk cache layer in MB (`CVMFS_CACHE_localdisk_QUOTA_LIMIT`) | Integer |

<details>
<summary>default values</summary>

```yaml
elastic_hpc::cvmfs::localdisk_quota_limit: 30000
```
</details>

<details>
<summary>example</summary>

```yaml
profile::cvmfs::client::alien_cache_repositories: ['ref.mugqic']
profile::cvmfs::client::alien_cache_repo_template: "elastic_hpc/alien_cache.conf"
profile::cvmfs::alien_cache::alien_fs_root: "/project"
elastic_hpc::cvmfs::localdisk_quota_limit: 50000
```
</details>
