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

As we've seen steady improvements in technology, networks, virtualization, and reductions in cost, vast amounts of computing power and storage are now within the grasp of nearly anyone. Along with our increasingly interconnected world, this has spured an exponential growth of data, and a demand for more predictability and speed by increasingly savy users.

Over the years, relational database management systems (RDBMS) had become fine tuned for certain use-cases like business intelligence, and technically tuned for things optimizing disk access, and squeezing performance out of single servers. In response to a changing world, and as cracks of in relational implementations became apparent, custom implementations arose in response to specific problems not originally envisioned by the relational DBs. These new databases are loosely called NoSQL, and Riak is of this ilk.

Modern database can be loosely grouped into the way they represent data. Althought I'm presenting 5 major types, these lines are often blurred--you can use some key/value stores as a document store, you can use a relational database to just store key/value data.

  1. **Relational**. Traditional databases usually use SQL to model and query data.
    They are most useful for data which can be stored in a highly structured schema, yet
    requires query flexibility. Scaling a relational database (RDBMS) traditionally
    occurs by more powerful hardware (vertical growth).
    
    Examples: *PostgreSQL*, *MySQL*, *Oracle*
  2. **Graph**. These exist for highly interconnected data. They excel in
    modeling complex relationships between nodes, and many implementations can
    handle multiple billions of nodes and relationships (or edges and vertices).
    
    Examples: *[[Neo4j|Riak Compared to Neo4j]]*, *Graphbase*, *InfiniteGraph*
  3. **Document**. Document datastores model hierarchical values called documents,
    represented in formats such as JSON or XML, and do not enforce a document schema.
    They generally support distributing across multiple servers (horizontal growth).
    
    Examples: *[[CouchDB|Riak Compared to CouchDB]]*, *[[MongoDB|Riak Compared to MongoDB]]*, *[[Couchbase|Riak Compared to Couchbase]]*
  4. **Columnar**. Popularized by Google's BigTable, this form of database exists to
    scale across multiple servers, and groups like data into column families. Column values
    can be individually versioned and managed, though families are generally defined in advance,
    not unlike an RDBMS schema.
    
    Examples: *[[HBase|Riak Compared to HBase]]*, *[[Cassandra|Riak Compared to Cassandra]]*, *BigTable*
  5. **Key/Value**. Key/Value, or KV stores, function like hashtables, where values are stored
    and accessed by an immutable key. They range from single-serve varieties like Memcaches used
    for high-speed caching, to multi-datacenter distributed systems like [[Riak Enterprise]].
    
    Examples: *[[Riak]]*, *Redis*, *Voldemort*


#### Keys

#### Values

#### Buckets

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



### Practical Tradeoffs

The CAP theorem shows a theoretical tradeoff, but what are the practical tradeoffs required to run a distributed database like Riak?

<aside id="joins" class="sidebar"><h3>A Quick note on JOINs</h3>

Unlike relational databases, but similar to document and columnar stores, values cannot be joined by Riak. Client code is responsible for accessing objects and merging them, or by other code such as mapreduce.

The ability to easily join data across physical servers (nodes) is a tradeoff that seperates single node databases like relational and graph, from naturally sharded systems like document, columnar, and  key/value stores.

This limitation changes how you model data. Relational normalization (organizing data to reduce redundancy) exists for systems that can cheaply join data together per request. However, the ability to spread data across multiple nodes requires a denormalized approach, where some data is duplicated, and computed values may be stored for the sake of reducing reads across nodes.
</aside>

### Riak and ACID

Unlike single node databases like Neo4j or PostgreSQL, Riak does not satisfy ACID transactions. Locking across 
