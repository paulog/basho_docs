---
title: Use Cases
project: riak
version: 1.2.0+
document: cookbook
index: true
toc: true
audience: intermediate
keywords: [use-cases]
---

The examples of data models laid out here are not necessarily right for
your application. This section is designed to illustrate some common
approaches to thinking about and implementing data models in Riak that
fit certain high-level, common application patterns. How you structure
your app to run on Riak should take into account the unique needs of
your application, including access patterns such as read/write distribution,
latency differences between various operations, use of Riak features
including MapReduce, Search and secondary indexes, and more. This guide
is only meant to be illustrative.

## High Read/Write, Simple Applications

*No complex relationships, but need high read/write performance*

  * Session Storage
  * Serving Ads
  * Log Data
  * Sensor Data

## Content Management, Social Applications

*Require one-to-many and many-to-many relationships*

  * User Accounts
  * User Settings/Preferences (one-to-one type of data)
  * User Subscriptions / Events / Timelines (typically one-to-many and many-to-many relationships)
  * Blog Posts, Articles and Other Content

