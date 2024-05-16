---
title: Accessing External Data with PXF 
---

Data managed by your organization may already reside in external sources such as Hadoop, object stores, and other SQL databases. The Greenplum Platform Extension Framework \(PXF\) provides access to this external data via built-in connectors that map an external data source to a Greenplum Database table definition.

PXF is installed with Hadoop and Object Storage connectors. These connectors enable you to read and write external data stored in text, Avro, JSON, RCFile, Parquet, SequenceFile, and ORC formats. You can use the JDBC connector to access an external SQL database.

The Greenplum Platform Extension Framework includes a C-language extension and a Java service. After you configure and initialize PXF, you start a single PXF JVM process on each Greenplum Database segment host. This long- running process concurrently serves multiple query requests.

For detailed information about the architecture of and using PXF, refer to the [Greenplum Platform Extension Framework \(PXF\)](https://docs.vmware.com/en/VMware-Greenplum-Platform-Extension-Framework/6.7/greenplum-platform-extension-framework/overview_pxf.html) documentation.

**Parent topic:** [Working with External Data](../external/g-working-with-file-based-ext-tables.html)

