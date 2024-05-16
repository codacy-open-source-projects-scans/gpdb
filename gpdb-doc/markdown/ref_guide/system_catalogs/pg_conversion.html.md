# pg_conversion 

The `pg_conversion` system catalog table describes the available encoding conversion procedures as defined by `CREATE CONVERSION`.

|column|type|references|description|
|------|----|----------|-----------|
|`oid`|oid||The object ID|
|`conname`|name| |Conversion name \(unique within a namespace\)|
|`connamespace`|oid|pg\_namespace.oid|The OID of the namespace \(schema\) that contains this conversion|
|`conowner`|oid|pg\_authid.oid|Owner of the conversion|
|`conforencoding`|integer| |Source encoding ID|
|`contoencoding`|integer| |Destination encoding ID|
|`conproc`|regproc|pg\_proc.oid|Conversion procedure|
|`condefault`|boolean| |True if this is the default conversion|

**Parent topic:** [System Catalogs Definitions](../system_catalogs/catalog_ref-html.html)

