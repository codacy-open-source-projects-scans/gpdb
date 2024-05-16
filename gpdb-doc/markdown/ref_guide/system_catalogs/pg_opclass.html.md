# pg_opclass 

The `pg_opclass` system catalog table defines index access method operator classes. Each operator class defines semantics for index columns of a particular data type and a particular index access method. An operator class essentially specifies that a particular operator family is applicable to a particular indexable column data type. The set of operators from the family that are actually usable with the indexed column are those that accept the column's data type as their left-hand input.

An operator class's `opcmethod` must match the `opfmethod` of its containing operator family. Also, there must be no more than one `pg_opclass` row having `opcdefault` true for any given combination of `opcmethod` and `opcintype`.

The PostgreSQL [Interfacing Extensions to Indexes](https://www.postgresql.org/docs/12/xindex.html) documentation describes operator classes at length.

|column|type|references|description|
|------|----|----------|-----------|
|`oid`|oid| |Row identifier \(hidden attribute; must be explicitly selected\)|
|`opcmethod`|oid|[pg\_am](pg_am.html).oid|Index access method operator class is for|
|`opcname`|name| |Name of this operator class|
|`opcnamespace`|oid|[pg\_namespace](pg_namespace.html).oid|Namespace of this operator class|
|`opcowner`|oid|[pg\_authid](pg_authid.html).oid|Owner of the operator class|
|`opcfamily`|oid|[pg\_opfamily](pg_opfamily.html).oid|Operator family containing the operator class|
|`opcintype`|oid|[pg\_type](pg_type.html).oid|Data type that the operator class indexes|
|`opcdefault`|boolean| |True if this operator class is the default for the data type `opcintype`|
|`opckeytype`|oid|[pg\_type](pg_type.html).oid|Type of data stored in index, or zero if same as `opcintype`|

**Parent topic:** [System Catalogs Definitions](../system_catalogs/catalog_ref-html.html)

