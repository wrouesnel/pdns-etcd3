# pdns-etcd3

[![Go Report Card](https://goreportcard.com/badge/github.com/nixn/pdns-etcd3)](https://goreportcard.com/report/github.com/nixn/pdns-etcd3)

A [PowerDNS][pdns] [remote backend][pdns-remote] with [ETCD][etcd] v3 cluster as storage.
It uses the [official client](https://github.com/coreos/etcd/tree/master/clientv3/)
to get the data from the cluster. Responses are authoritative for each zone found in
the data. Only the DNS class `IN` is supported, but that's a limitation of PowerDNS.

There is no stable release yet, even no beta. Any testing is appreciated.

[pdns]: https://www.powerdns.com/
[pdns-remote]: https://doc.powerdns.com/3/authoritative/backend-remote/
[etcd]: https://github.com/coreos/etcd/

## Features

* Automatic serial for `SOA` records (based on the cluster revision).
* Replication is handled by the ETCD cluster, no additional configuration is needed for using multiple authoritative PowerDNS servers.
* Multiple syntax possibilities for JSON-supported records
* Support for automatically appending zone name to unqualified domain names
* Multi-level defaults, overridable

#### Planned

* Reduce redundancy in the data by automatically deriving corresponding data
  * `A` ⇒ `PTR` (`in-addr.arpa`)
  * `AAAA` ⇒ `PTR` (`ip6.arpa`)
  * …
* Default prefix for IP addresses
* Override of domain name appended to unqualified names (instead of zone name)
  * useful for `PTR` records in reverse zones
* Upgrade data structure (if needed for new program version) without interrupting service

## Installation

```sh
go get github.com/nixn/pdns-etcd3
```

Of course you need an up and running ETCD v3 cluster and a PowerDNS installation.

## Usage

### PowerDNS configuration
```
launch+=remote
remote-connection-string=pipe:command=/path/to/pdns-etcd3[,pdns-version=3|4][,<config>][,prefix=anything][,timeout=2000]
```

`pdns-version` is `3` by default, but may be set to `4` to enable PowerDNS v4 compatibility.
Version 3 and 4 have incompatible protocols with the backend, so you must use the proper one.

`<config>` is one of
* `configFile=/path/to/etcd-config-file`
* `endpoints=192.168.1.7:2379|192.168.1.8:2379`
* MAYBE LATER (see below) `discovery-srv=example.com`

TLS and authentication is only possible when using the configuration file.

The configuration file is the one accepted by the official client
(see [etcd/clientv3/config.go](https://github.com/coreos/etcd/blob/master/clientv3/config.go),
TODO find documentation).

`endpoints` accepts hostnames too, but be sure they are resolvable before PowerDNS
has started. Same goes for `discovery-srv`; it is undecided yet if this config is needed.

If `<config>` is not given, it defaults to `endpoints=[::1]:2379|127.0.0.1:2379`

`prefix` is optional and is empty by default.

`timeout` is optional and defaults to 2 seconds. The value must be a positive integer,
given in milliseconds.

### ETCD structure

See [ETCD-structure][etcd-structure]. The structure lies beneath the `prefix`
configured in PowerDNS (see above).

[etcd-structure]: ETCD-structure.md

## Compatibility

pdns-etcd3 is tested on PowerDNS 3.x and uses an ETCD v3 cluster. It
may work on PowerDNS 4.x, but is not tested, though it is planned to
support both eventually, or even only 4.x later. Issues regarding
PowerDNS 4.x are not handled yet.

## Debugging

For now, there is much logging, as the program is in alpha state.

# Hacking

To get started hacking on this project, clone the repository and run
`./autogen.sh` to setup pre-commit hooks (these will help your commits pass CI).
