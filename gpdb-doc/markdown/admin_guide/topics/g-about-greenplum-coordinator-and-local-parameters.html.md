---
title: About Greenplum Database Coordinator and Local Parameters 
---

Server configuration files contain parameters that configure server behavior. The Greenplum Database configuration file, postgresql.conf, resides in the data directory of the database instance.

The coordinator and each segment instance have their own postgresql.conf file. Some parameters are *local*: each segment instance examines its postgresql.conf file to get the value of that parameter. Set local parameters on the coordinator and on each segment instance.

Other parameters are *coordinator* parameters that you set on the coordinator instance. The value is passed down to \(or in some cases ignored by\) the segment instances at query run time.

See the *Greenplum Database Reference Guide* for information about *local* and *coordinator* server configuration parameters.

**Parent topic:** [Configuring the Greenplum Database System](../topics/g-configuring-the-greenplum-system.html)

