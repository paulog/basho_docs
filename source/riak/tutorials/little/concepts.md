---
title: "A Little Riak Book: Concepts"
project: riak
version: 1.2.0+
document: tutorials
toc: true
versions: false
audience: beginner
keywords: []
---

Before we dig into the details of using Riak, we need a bit of front matter.

## Database Models

(5 major types, but these lines are often blurred - you can use a KV as a document store, you can use a relational DB as a KV).

### Riak

#### Keys

#### Values

#### Buckets

## This NoSQL Thing

## Replication and Sharding

(duplicating all data across many servers (A-Z on both server 1 and 2)... splitting a set of data across many servers (eg. A-N on server 1, O-Z on server 2)... both (A-N on server 1 & 2, O-Z on server 3 & 4). you might immediately notice that our servers have increased. But so has our capacity and reliability)
(diagram the various server setups. Replication, Sharding, Repl+Sharding)

## CAP Theorem

- Replicating and sharding our data has a cost, however. The very act of placing our data in multiple servers carries some inherent risk

Partition

(create a diagram explaining CAP, with the various types of server setups)

As your server count grows--especially as you introduce multiple datacenters--the odds of a partition drastically increase.

- Failure migrates from an edge case to the common case.

Be wary of anyone who tells you they have solved it, or it is not a problem (what about Spanner?)

