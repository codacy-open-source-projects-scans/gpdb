---
title: About Redundancy and Failover in Greenplum Database 
---

This topic provides a high-level overview of Greenplum Database high availability features.

You can deploy Greenplum Database without a single point of failure by mirroring components. The following sections describe the strategies for mirroring the main components of a Greenplum system. For a more detailed overview of Greenplum high availability features, see [Overview of Greenplum Database High Availability](../highavail/topics/g-overview-of-high-availability-in-greenplum-database.html).

> **Important** When data loss is not acceptable for a Greenplum Database cluster, Greenplum coordinator and segment mirroring is recommended. If mirroring is not enabled then Greenplum stores only one copy of the data, so the underlying storage media provides the only guarantee for data availability and correctness in the event of a hardware failure.

The VMware Greenplum on vSphere virtualized environment ensures the enforcement of anti-affinity rules required for Greenplum mirroring solutions and fully supports mirrorless deployments. Other virtualized or containerized deployment environments are generally not supported for production use unless both Greenplum coordinator and segment mirroring are enabled.

## <a id="segment_mirroring"></a>About Segment Mirroring 

When you deploy your Greenplum Database system, you can configure *mirror* segment instances. Mirror segments allow database queries to fail over to a backup segment if the primary segment becomes unavailable. The mirror segment is kept current by a transaction log replication process, which synchronizes the data between the primary and mirror instances. Mirroring is strongly recommended for production systems and required for VMware support.

As a best practice, the secondary \(mirror\) segment instance must always reside on a different host than its primary segment instance to protect against a single host failure. In virtualized environments, the secondary \(mirror\) segment must always reside on a different storage system than the primary. Mirror segments can be arranged over the remaining hosts in the cluster in configurations designed to maximize availability, or minimize the performance degradation when hosts or multiple primary segments fail.

Two standard mirroring configurations are available when you initialize or expand a Greenplum system. The default configuration, called *group mirroring*, places all the mirrors for a host's primary segments on one other host in the cluster. The other standard configuration, *spread mirroring*, can be selected with a command-line option. Spread mirroring spreads each host's mirrors over the remaining hosts and requires that there are more hosts in the cluster than primary segments per host.

This figure shows how table data is distributed across segments when spread mirroring is configured.

![Spread Mirroring in Greenplum Database](../graphics/spread-mirroring.png "Spread Mirroring in Greenplum Database")

## <a id="segment_failover"></a>Segment Failover and Recovery 

When segment mirroring is enabled in a Greenplum Database system, the system will automatically fail over to the *mirror segment* instance if a *primary segment* instance becomes unavailable. A Greenplum Database system can remain operational if a segment instance or host goes down as long as all the data is available on the remaining active segment instances.

If the coordinator cannot connect to a segment instance, it marks that segment instance as down in the Greenplum Database system catalog and brings up the mirror segment in its place. A failed segment instance will remain out of operation until an administrator takes steps to bring that segment back online. An administrator can recover a failed segment while the system is up and running. The recovery process copies over only the changes that were missed while the segment was out of operation.

If you do not have mirroring enabled, the system will automatically shut down if a segment instance becomes invalid. You must recover all failed segments before operations can continue.

## <a id="coordinator_mirroring"></a>About Coordinator Mirroring 

You can also optionally deploy a backup or mirror of the coordinator instance on a separate host from the coordinator host. The backup coordinator instance \(the *standby coordinator*\) serves as a *warm standby* in the event that the primary coordinator host becomes non-operational. The standby coordinator is kept current by a transaction log replication process, which synchronizes the data between the primary and standby coordinator.

If the primary coordinator fails, the log replication process stops, and the standby coordinator can be activated in its place. The switchover does not happen automatically, but must be triggered externally. Upon activation of the standby coordinator, the replicated logs are used to reconstruct the state of the coordinator host at the time of the last successfully committed transaction. The activated standby coordinator effectively becomes the Greenplum Database coordinator, accepting client connections on the coordinator port \(which must be set to the same port number on the coordinator host and the backup coordinator host\).

Since the coordinator does not contain any user data, only the system catalog tables need to be synchronized between the primary and backup copies. When these tables are updated, changes are automatically copied over to the standby coordinator to ensure synchronization with the primary coordinator.

![Coordinator Mirroring in Greenplum Database](../graphics/standby_coordinator.jpg "Coordinator Mirroring in Greenplum Database")

## <a id="interconnect_redundancy"></a>About Interconnect Redundancy 

The *interconnect* refers to the inter-process communication between the segments and the network infrastructure on which this communication relies. You can achieve a highly available interconnect using by deploying dual Gigabit Ethernet switches on your network and redundant Gigabit connections to the Greenplum Database host \(coordinator and segment\) servers. For performance reasons, 10-Gb Ethernet, or faster, is recommended.

**Parent topic:** [Greenplum Database Concepts](../intro/partI.html)

