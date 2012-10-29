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
curl -XPUT 'http://localhost:8098/riak/food/favorite' \
  -H 'Content-Type:text/plain' \
  -d 'pizza'
```

I threw a few curveballs in there. The `-d` flag denotes the next string will be the value. We've kept things simple with the string `pizza`, declaring it as text with the proceeeding line `-H 'Content-Type:text/plain'`. This defined the HTTP MIME type of this value as plain text. We could have set any value at all, be it XML or JSON---even an image or a video. Any HTTP MIME type is valid content (which is anything, really).

#### GET

The next command reads the value `pizza` under the bucket/key `food`/`favorite`.

```bash
curl -XGET 'http://localhost:8098/riak/food/favorite'
pizza
```

This is the simplest form of read, responding with only the value. Riak contains much more information that you can access, if you read the entire response, including the HTTP header.

In `curl` you can access the full response by way of the `-i` flag. Let's perform the above query again, adding that flag.

```bash
curl -i -XGET 'http://localhost:8098/riak/food/favorite'
HTTP/1.1 200 OK
X-Riak-Vclock: a85hYGBgzGDKBVIcypz/fgaUHjmdwZTImMfKcN3h1Um+LAA=
Vary: Accept-Encoding
Server: MochiWeb/1.1 WebMachine/1.9.0 (someone had painted it blue)
Link: </riak/food>; rel="up"
Last-Modified: Wed, 10 Oct 2012 18:56:23 GMT
ETag: "1yHn7L0XMEoMVXRGp4gOom"
Date: Thu, 11 Oct 2012 23:57:29 GMT
Content-Type: text/plain
Content-Length: 5

pizza
```

The anatomy of HTTP is a bit beyond this little book, but let's look at a few parts worth noting.

##### Status Codes

The first line gives the HTTP version 1.1 response code code `200 OK`. You may be familiar with the common website code `404 Not Found`. There are many kinds of [HTTP status codes](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html), and the Riak HTTP interface stays true to their intent: **1xx Informational**, **2xx Success**, **3xx Further Action**, **4xx Client Error**, **5xx Server Error**

Different actions can return different response/error codes. Complete lists can be found in the [[official API docs|Riak APIs]].

##### Timings

A block of headers represents different timings for the object or the request.

* **Last-Modified** - The last time this object was modified (created or updated).
* **ETag** - An *[entity tag](http://en.wikipedia.org/wiki/HTTP_ETag)* which can be used for cache validation by a client.
* **Date** - The time of the request.


##### Content

These describe the HTTP body of the message (in Riak's terms, the *value*).

* **Content-Type** - The type of value, such as `text/xml`.
* **Content-Length** - The length, in bytes, of the message body.

The other headers like `X-Riak-Vclock` and `Link`, will be covered later in this chapter.


#### POST

Similar to PUT, POST will save a value. But with POST a key is optional. All it requires is a bucket name, and it will generate a key for you.

Let's add a JSON value to represent a person under the `people` bucket. The response header is where a POST will return the key it generated for you.

```bash
curl -i -XPOST 'http://localhost:8098/riak/people' \
  -H 'Content-Type:application/json' \
  -d '{"name":"aaron"}'
HTTP/1.1 201 Created
Vary: Accept-Encoding
Server: MochiWeb/1.1 WebMachine/1.9.2 (someone had painted it blue)
Location: /riak/people/DNQGJY0KtcHMirkidasA066yj5V
Date: Wed, 10 Oct 2012 17:55:22 GMT
Content-Type: application/json
Content-Length: 0
```

You can extract this key from the `Location` value. Other than not being pretty, thiis key is just as if you defined your own key by a PUT.

##### Body

You may note that no body was returned with the response. For any kind of write, you can add the `returnbody=true` parameter to force a value to return, along with value-related headers like `X-Riak-Vclock` and `ETag`.

```bash
curl -i -XPOST 'http://localhost:8098/riak/people?returnbody=true' \
  -H 'Content-Type:application/json' \
  -d '{"name":"billy"}'
HTTP/1.1 201 Created
X-Riak-Vclock: a85hYGBgzGDKBVIcypz/fgaUHjmdwZTImMfKkD3z10m+LAA=
Vary: Accept-Encoding
Server: MochiWeb/1.1 WebMachine/1.9.0 (someone had painted it blue)
Location: /riak/people/DnetI8GHiBK2yBFOEcj1EhHprss
Link: </riak/people>; rel="up"
Last-Modified: Tue, 23 Oct 2012 04:30:35 GMT
ETag: "7DsE7SEqAtY12d8T1HMkWZ"
Date: Tue, 23 Oct 2012 04:30:35 GMT
Content-Type: application/json
Content-Length: 16

{"name":"billy"}
```

This is true for PUTs and POSTs.

#### DELETE

The final basic operation is deleting keys, which is similar to getting a value, but sending the DELETE method to the `url`/`bucket`/`key`.

```bash
curl -XDELETE 'http://localhost:8098/riak/people/DNQGJY0KtcHMirkidasA066yj5V'
```

A deleted object in Riak is internally marked as deleted, by writing a marker known as a *tombstone*. Later, another process called a *reaper* clears the marked objects from the backend (possibly, the reaper may be turned off).

This detail isn't normally important, except to understand two things:

1. In Riak, a *delete* is actually a *write*, and should be considered as such.
2. Checking for the existence of a key is not enough to know if an object exists. You be reading a key between a delete and a reap---you must read for tombstones.

#### Lists

Riak provides two kinds of lists. The first lists all *buckets* in your cluster, while the second lists all *keys* under a specific bucket. Both of these actions are called in the same way, and come in two varieties.

The following will give us all of our buckets as a JSON object.

```bash
curl 'http://localhost:8098/riak?buckets=true'
{"buckets":["food"]}
```

And this will give us all of our keys under the `food` bucket.

```bash
curl 'http://localhost:8098/riak/food?keys=true'
{
  ...
  "keys": [
    "favorite"
  ]
}
```

If we had very many keys, clearly this might take a while. So Riak also provides the ability to stream your list of keys. `keys=stream` will keep the connection open, returning results in chunks of arrays. When it has exhausted its list, it will close the connection. You can see the details through curl in verbose (`-v`) mode (much of that response has been stripped out below).

```bash
curl -v 'http://localhost:8098/riak/food?list=stream'
...

* Connection #0 to host localhost left intact
...
{"keys":["favorite"]}
{"keys":[]}
* Closing connection #0
```

<!-- Transfer-Encoding -->

You should note that none of these list actions should be used in production (they're really expensive operations). But they are useful for development, investigations, or for running occasional analytics.

## Buckets

Although we've been using buckets as namespaces up to now, they are capable of more.

Different use-cases will dictate whether a bucket is heavily written to, or largely read from. You may use one bucket to store logs, one bucket could store session data, while another may store shopping cart data. Sometimes low latency is important, while other times it's high durability. And sometimes we just want buckets to react differently when a write occurs.

### Quorum

The basis of Riak's availability and tolerance is that it can read from, or write to, multiple nodes. Riak allows you to adjust these N/R/W values (which we covered under [[Concepts|A Little Riak Book: Concepts#Practical Tradeoffs]]) on a per-bucket basis.

#### N/R/W

N is the number of total nodes that a value should be replicated to, defaulting to 3. But we can set this `n_val` to any number fewer than the total number of nodes.

Any bucket property, including `n_val`, can be set by sending a `props` value as a JSON object to the bucket url. Let's set the `n_val` to 5 nodes, meaning that objects written to `cart` will be replicated to 5 nodes.

```bash
curl -i -XPUT http://localhost:8098/riak/cart \
  -H "Content-Type: application/json" \
  -d '{"props":{"n_val":5}}'
```

You can take a peek at the bucket's properties by issuing a GET to the bucket.

*Note: Riak returns unformatted JSON. If you have a command-line tool like jsonpp (or json_pp) installed, you can pipe the output there for easier reading. The results below are a subset of all the `props` values.*

```bash
curl http://localhost:8098/riak/cart | jsonpp
{
  "props": {
    ...
    "dw": "quorum",
    "n_val": 5,
    "name": "cart",
    "postcommit": [],
    "pr": 0,
    "precommit": [],
    "pw": 0,
    "r": "quorum",
    "rw": "quorum",
    "w": "quorum",
    ...
  }
}
```

As you can see, `n_val` is 5. That's expected. But you may also have noticed that the cart `props` returned both `r` and `w` as `quorum`, rather than a number. So what is a *quorum*?

##### Symbolic Values

A *quorum* is a one more than half of all the total replicated nodes (floor(N/2) + 1). This is an important figure, since if more than half of all nodes are written to, and more than half of all nodes are read from, then you will get the most recent value (under normal circumstances).

Here's an example with the above `n_val` of 5 ({A,B,C,D,E}). Your `w` is a quorum (which is `3`, or floor(5/2)+1), so a PUT may respond successfully after writing to {A,B,C} ({D,E} will eventually be replicated to). Immediately after, a read quorum may GET values from {C,D,E}. Even if D and E have older values, you have pulled a value from node C, meaning you will receive the most recent value.

What's important is that your reads and writes *overlap*. As long as r+w > n, you'll be able to get the newest values. In other words, you'll have consistency.

A `quorum` is an excellent default, since you're reading and writing from a balance of nodes. But if you have specific requirements, like a log that is often written to, but rarely read, you might find it make more sense to write to a single node, but read from all of them. This affords you an overlap 

```bash
curl -i -XPUT http://localhost:8098/riak/logs \
  -H "Content-Type: application/json" \
  -d '{"props":{"w":"one","r":"all"}}'
```

* `all` - All replicas must reply, which is the same as setting `r` or `w` equal to `n_val`
* `one` - Setting `r` or `w` equal to `1`
* `quorum` - A majority of the replicas must respond, that is, “half plus one”.

##### More than R's and W's

Some other values you may have noticed in the bucket's `props` object are `pw`, `pr`, and `dw`.

`pr` and `pw` check for available nodes before a read or a write (the *p* stands for *pre*, as in, *before the action takes place*). The `pw` will ensure that that many nodes are available before attempting to write---if not, no writes will happen. Compare this to `w`, which waits for that many nodes writes to complete, then confirms success or failure afterward.

Finally `dw` represents the minimal *durable* writes necessary for success. For a normal `w` write to count a write as successful, it merely needs to promise a write has started, even though that write is still in memory, with no guarentee that write has been written to disk, aka, is durable. The `dw` setting represents a minimum number of durable writes necessary to be considered a success. Although a high `dw` value is likely slower than a high `w` value, there are cases where this extra enforcement is good to have, such as dealing with financial data.

### Hooks

Another utility of buckets are their ability to enforce behaviors on writes by way of hooks. You can attach functions to run either before, or after, a value is committed to a bucket.

Functions that run before a write is called pre-commit, and has the ability to cancel a write altogether if the incoming data is considered bad in some way. A simple precommit hook it to check if a value exists at all.

```erlang
%% Object size must be greater than 0 bytes
value_exists(RiakObject) ->
  case erlang:byte_size(riak_object:get_value(RiakObject)) of
    Size when Size == 0 -> {fail, "A value sized greater than 0 is required"};
    _ -> Object
  end.
```

{"mod": "precommits", "fun": "value_exists"}

## Entropy

Entropy is a biproduct of eventual consistency. In plain speak: although eventual consistency says a write will eventually replicate to other nodes, there is a bit of time where the nodes do not contain the same value.

### Gossip

### N/R/W Per Request

Riak has a couple strategies related to the case of nodes that do not agree on value.

<!-- * `default` - Uses whatever the per-bucket consistency property is for R or W, which may be any of the above values, or an integer. -->

<!-- Riak has a couple strategies to deal with the case of nodes that do not agree on value, an action known as Anti-Entropy. -->

### Read Repair

Read repair occurs when a successful read occurs — that is, the quorum was met — but not all replicas from which the object was requested agreed on the value. There are two possibilities here for the errant nodes:

1. The node responded with a `not found` for the object, meaning it doesn't have a copy.
2. The node responded with a vector clock that is an ancestor of the vector clock of the successful read.

When this situation occurs, Riak will force the errant nodes to update their object values based on the value of the successful read.

### Siblings

<!-- ### Handoff
When a partitions parent node is unavailable, requests are sent to fallback nodes (handoff). -->

## Querying

We've already seen direct key-vaue lookups. The truth is, it's a pretty powerful mechanism that spans a spectrum of usecases. However, sometimes we need to lookup data by values, rather than keys. Sometimes we need to perform some calculation

### Secondary Indexing (2i)

### Search (Yokozuna)

### MR + Link Walking

#### Link Walking

  It may not seem like it, but Link Walking is a specialized case of MapReduce



<!--
### Responses

We've focused on what you can request, but not much on the details of the responses you recieve from Riak. The HTTP interface uses HTTP headers to transmit metadata about the request (this metadata is are also available in the [[protocol buffer's RpbContent|PBC Fetch Object#Response]] response). We've seen a glimpse of this already, when we retrieved the Riak generated key from the POST method.

In `curl`, any response header can be retrieved with the `-I` flag.

```bash
HTTP/1.1 200 OK
X-Riak-Vclock: a85hYGBgzGDKBVIcRjaC3gH5wT8ymBJZ81gZUm1fneTLAgA=
Vary: Accept-Encoding
Server: MochiWeb/1.1 WebMachine/1.9.2 (someone had painted it blue)
Link: </riak/people>; rel="up"
Last-Modified: Wed, 10 Oct 2012 18:41:41 GMT
ETag: "7SJsqCOMic6PqUlnAASuIL"
Date: Wed, 10 Oct 2012 18:41:49 GMT
Content-Type: application/json
Content-Length: 16

{"name":"aaron"}
```

HTTP/1.1 201 Created
Vary: Accept-Encoding
Server: MochiWeb/1.1 WebMachine/1.9.2 (someone had painted it blue)
Location: /riak/people/f8BD18xUs0vrF8RQT71YlBfsHd
Date: Wed, 10 Oct 2012 18:37:03 GMT
Content-Type: application/json
Content-Length: 0

* **X-Riak-Vclock** - Tracks a lineage of changes and used for conflict resolution. *Covered later in this chapter.*


#### Codes

Here are some of the more common codes you'll encounter using the HTTP API.

20xs

`200 OK` GET, and PUT or POST with `returnbody=true`

HTTP/1.1 200 OK
X-Riak-Vclock: a85hYGBgzGDKBVIcRjaC3gH5wT8ymBJZ81gZUm1fneTLAgA=
Vary: Accept-Encoding
Server: MochiWeb/1.1 WebMachine/1.9.2 (someone had painted it blue)
Link: </riak/people>; rel="up"
Last-Modified: Wed, 10 Oct 2012 18:41:41 GMT
ETag: "7SJsqCOMic6PqUlnAASuIL"
Date: Wed, 10 Oct 2012 18:41:49 GMT
Content-Type: application/json
Content-Length: 16

{"name":"aaron"}

`201 Created` POST

`204 No Content` is just like a 202, except without any body data.

DELETE

HTTP/1.1 204 No Content
Content-Length: 0


HTTP/1.1 400 Bad Request

#### Body


### Header Metadata
-->
