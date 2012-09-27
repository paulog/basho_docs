---
title: "A Little Riak Book: Developers"
project: riak
version: 1.2.0+
document: tutorials
toc: true
versions: false
audience: beginner
keywords: []
prev: ["Concepts", "concepts.html"]
up:   ["A Little Riak Book", "index.html"]
next: ["Operators", "operators.html"]
---

_We're going to hold off on the details of installing Riak at the moment. If you'd like to follow along, it's easy enough to get started by following the documentation on the website. If not, this is a perfect section to read while you sit on a train without internet connection._

Developing with a Riak database is quite easy to do, once you understand some of the finer points. It is a key/value store, in the technical sense (you associate values with keys, and retrieve them using the same keys) but it offers so much more. You can embed write hooks to fire before or after a write, or index data for quick retrieval. Riak has a SOLR-based search, and lets you run mapreduce functions to extract and aggregate data across a huge cluster with TB of data in a reletively short timespan. We'll show some of the bucket-specific settings developers can configure.

## Lookup

Since Riak is a KV database, the most basic commands are setting and getting values. We'll use the HTTP interface, via curl, but we could just as easily use Erlang, Ruby, Java, or any other supported language.

<aside class="sidebar"><h3>Supported Languages</h3>

Riak has official drivers for the following languages:

Erlang, Java, PHP, Python, Ruby

Including community supplied drivers, supported languages are even more numberous:

C/C++, Clojure, Common Lisp, Dart, Go, Groovy, Haskell, Javascript (jquery and nodejs), Lisp Flavored Erlang, .NET, Perl, PHP, Play, Racket, Scala, Smalltalk

There are also dozens of other [[project-specific addons|Community Developed Libraries and Projects]].
</aside>

#### PUT

The simplest write command in Riak is putting a value. It requires a key, value, and a bucket. The HTTP interface uses the basic REST methods (PUT, GET, POST, DELETE), which in curl are prefixed with `-X`. Putting the value `pizza` into the key `favorite` under the `food` bucket is like so:

```bash
curl -H 'Content-Type:text/plain' -XPUT 'http://localhost:8098/riak/food/favorite' -d 'pizza'
```

I threw a few curveballs in there. The `-d` flag denotes that the next string will be the value. We kept things simple the text `pizza`. How did Riak know we were giving it text? Because `-H 'Content-Type:text/plain'` defines the HTTP MIME type of this value to be plain text. But we could have set any value at all, be it XML, JSON, or even a image or video. Any HTTP MIME type is a valid value (which is anything, really).

#### GET

```bash
curl -XGET 'http://localhost:8098/riak/food/favorite'
pizza
```


#### POST

In curl, the `-I` command will return the full response message, including the HTTP header data.

```bash
curl -I -H 'Content-Type:application/json' -XPOST 'http://localhost:8098/riak/people' -d '{"name":"aaron"}'

XXXXXXXX
```


#### DELETE

Deleting an object in Riak is internally just marked as delete by setting the value to a tombstone. Later, another process called a reaper clears the marked objects from the backend. This detail isn't normally important, except to note that any code you write that scans all keys will have to deal with tombstoned objects. Simply counting keys is not a reliable figure for summing active objects.

```bash
curl -XDELETE 'http://localhost:8098/riak/people/XXXXXXXX'
```

#### Keys


### Responses

#### Codes

#### Body


### Header Metadata

### Quorum

## Bucket Props

Before continuing on to other types of queries, let's spend a bit of time covering buckets. More than just namespaces, buckets can be tuned differently. Some buckets might act as loggers, while others may be shopping carts. Some might be heavily written to, while others might be largely read.

### Hooks

## Querying

We've already seen direct key-vaue lookups. The truth is, it's a pretty powerful mechanism that spans a spectrum of usecases. However, sometimes we need to lookup data by values, rather than keys. Sometimes we need to perform some calculation

### Secondary Indexing (2i)

### Search (Yokozuna)

### MR + Link Walking

#### Link Walking

  It may not seem like it, but Link Walking is a specialized case of MapReduce

