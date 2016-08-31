# ETCD structure

## Stability

The structure is currently in development and may change multiple times in an incompatible
way until a stable major release. After such a release the structure won't change
for the same major release (but may for future major releases).

## Rules

* Record entry values are either JSON objects or plain strings (that is without
quotation marks). If an entry value begins with a `{`, it is parsed as a JSON object,
otherwise it is taken as plain string.

* Each record which has a JSON entry value must be supported by the program.
Otherwise an error is emitted and the request/response fails. This is not true for plain strings,
which are returned as-is, without an error, but also without defaults support (except TTL).
This behaviour allows support for JSON-unsupported records.

* Entry values store the *content* of a record, they do not include the domain name,
the DNS class (`IN`), nor the entry type (`A`, `MX`, &hellip;), these values are
in the key already. They may include a record-specific TTL value, see below rule for details.

* The record TTL is a regular field in case of a JSON object entry (key `"ttl"`), but there
is (currently) no way to define a record-specific TTL for a plain string entry.
One may use a default value as a workaround for this limitation.

* For each record field a default value is searched for and used, if an entry value
does not specify the field value itself. If no value is found for the field,
an error is raised and the request/response fails.

* Subdomains are determined by the domain name in question (QNAME) minus the zone name
(and the separating dot). E.g. QNAME `some.thing.example.net` in zone `example.net`
yields the subdomain `some.thing`.
If the QNAME is equal to the zone name, the subdomain is set to `@` for ETCD requests.

## Structure (Entries)

`<prefix>` is the global prefix from configuration (see [README](README.md))

### Version

* Key: `<prefix>/version`
* Value: must be the same as the major version of the program (e.g. `1` for `1.x[.y]`)

### Records

Each resource record has at least one corresponding entry in the storage.
Entries are as follows:

* Key: `<prefix>/<zone>/<subdomain>/<QTYPE>/<id>`
  * `<zone>` is a domain name, e.g. `example.net`
  * `<subdomain>` is as described in the rules above
  * `<QTYPE>` is the type of the resource resource, e.g. `A`, `MX`, &hellip;
  * `<id>` is user-defined, it has no meaning in the program, it may even be empty
* Value: `<JSON object>` or `<plain string>`

For multiple values of the same record use multiple `<id>`s. All records
but `SOA` may have multiple values.

#### Exceptions

* For the `SOA` record the entry key is `<prefix>/<zone>/@/SOA` (no `<id>`).
It does not have multiple values.

* The QTYPE `ANY` is not a real record, so nothing to store for it.

### Defaults

There are four levels of default values, from most generic to most specific:

1. zone
  * Key: `<prefix>/<zone>/-defaults`
2. zone + QTYPE
  * Key: `<prefix>/<zone>/<QTYPE>-defaults`
3. zone + subdomain
  * Key: `<prefix>/<zone>/<subdomain>/-defaults`
4. zone + subdomain + QTYPE
  * Key: `<prefix>/<zone>/<subdomain>/<QTYPE>-defaults`

Defaults-entries must be JSON objects, with any number of fields (including zero).
Defaults-entries may be non-existent, which is equivalent to an empty object.

Field names of defaults objects are the same as record field names. So there could
be an ambiguity in non-QTYPE defaults, if different record types define the same
field name. The program only checks for value types, not content, so take care yourself.

## Supported records

For each of the supported record types the entry values may be JSON objects. The recognized
specific field names and syntax are given below for each entry.

#### Notes

* All entries can have a `ttl` field, for the record TTL.

* All domain names (or host names) are undergoing a check whether to append the zone name.
The rule is the same as in [BIND][] zone files: if a name ends with a dot, the zone
name is not appended, otherwise it is. This is naturally only possible for JSON-entries.

* All durations are either integers, given in seconds, or [duration strings][tdur].
All of them must be positive (that is >= 1 second).

### `SOA`

* `primary`: a domain name.
* `mail`: a mail address, in regular syntax (`mail@example.net`). The domain name undergoes the zone append check!
* `refresh`: duration
* `retry`: duration
* `expire`: duration
* `neg-ttl`: duration

There is no serial field, because the program takes the cluster revision as serial.
This way the operator does not have to increase it each time he/she changes DNS data.

### `NS`

* `hostname`: a domain name.

## Example

[bind]: https://www.isc.org/downloads/bind/
[tdur]: https://golang.org/pkg/time/#ParseDuration