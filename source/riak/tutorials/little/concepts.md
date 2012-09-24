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

## The Landscape

Before we understand where Riak sits in the spectrum of databases, it's good to have a little front matter. The existence of databases like Riak is the culmination of two things: accessible technology spuring more data requirements, and a gap in the existing database market.

First, as we've seen steady improvements in technology along with reductions in cost, vast amounts of computing power and storage are now within the grasp of nearly anyone. Along with our increasingly interconnected world caused by the web and shrinking, cheaper computers (like smartphones), this has spured an exponential growth of data, and a demand for more predictability and speed by increasingly savy users.

Second, relational database management systems (RDBMS) had become fine tuned over the years for a set of use-cases like business intelligence. They were also technically tuned for things optimizing disk access, and squeezing performance out of single larger servers. Cheap commodity (or virtualized) servers made horizontal growth and increasingly attractive alternative for more organizations. As cracks in relational implementations became apparent, custom implementations arose in response to specific problems not originally envisioned by the relational DBs.

These new databases are loosely called NoSQL, and Riak is of its ilk.

### Database Models

Modern database can be loosely grouped into the way they represent data. Although I'm presenting 5 major types (the last 4 are considered NoSQL models), these lines are often blurred--you can use some key/value stores as a document store, you can use a relational database to just store key/value data.

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
  5. **Key/Value**. Key/Value, or KV stores, are conceptually like hashtables, where values are stored
    and accessed by an immutable key. They range from single-server varieties like
    [memcached](http://memcached.org/) used for high-speed caching, to multi-datacenter
    distributed systems like [[Riak Enterprise]].
    
    Examples: *[[Riak]]*, *Redis*, *Voldemort*

## Riak Components

Riak is a Key/Value database, built from the ground up to safely distribute data across a cluster of physical servers (called nodes). That cluster is called a Ring--we'll cover why later.

For now, we'll only consider the parts required to use Riak. Riak functions similar to a hashtable. Depending on your background, you may instead call it a map, or dictionary, or object. But the concept is the same: you store a value with an immutable key, and retrieve it later.

<!-- replace with an image -->

If Riak were a variable that functioned as a hashtable, you might set the value of your favorite food like this.

```javascript
hashtable["favorite"] = "pizza"
```

And retrieve the value `"pizza"` by using the same key.

```javascript
food = hashtable["favorite"]
```

One day you burn the roof of your mouth. So you update your favorite food to `"cold pizza"`.

```javascript
hashtable["favorite"] = "cold pizza"
```

Successive requests will now return `"cold pizza"`.

That's the very basic idea of a key/value store like Riak.

### Buckets

Another aspect of Riak is a *bucket*. Sometimes you must group together multiple keys into logical categories, where identical keys will not overlap. These groupings are called buckets.

```javascript
edibles["favorite"] = "pizza"
animals["favorite"] = "red panda"
```

Of course, you could have just named your keys `edible_favorite` and `animal_favorite`, but this allows for easier keys, and has other added benefits that I'll outline later.

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
