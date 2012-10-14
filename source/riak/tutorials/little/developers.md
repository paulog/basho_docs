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

I threw a few curveballs in there. The `-d` flag denotes the next string will be the value. We've kept things simple the text `pizza`. But how did Riak know we were giving it text? Because the proceeeding line `-H 'Content-Type:text/plain'` defined the HTTP MIME type of this value to be plain text. We could have set any value at all, be it XML or JSON---even an image or a video. Any HTTP MIME type is valid content (which is anything, really).

#### GET

The next command reads the value pizza under the bucket/key `food`/`favorite`.

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

The first line gives the HTTP 1.1 code of the response, code `200 OK`. 

#### POST

Just like PUT, POST will save a value. But with POST a key is optional. All it requires is a bucket name, and it will generate a key for you... it just won't be pretty.

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

You can extract this key from the `Location` value. Other than being ugly, is key is just as if you defined your own key by a PUT.

You may note that no body was returned with the response. For any kind of write, you can add the `returnbody=true` parameter to force a value to return.

```bash
curl -i -XPOST 'http://localhost:8098/riak/people?returnbody=true' \
  -H 'Content-Type:application/json' \
  -d '{"name":"billy"}'
```

This is true of PUTs, POSTs, and as we'll see, DELETEs.

#### DELETE

The final basic operation is deleting keys, which is just like getting a value, but padding the DELETE method to the `url`/`bucket`/`key`.

```bash
curl -XDELETE 'http://localhost:8098/riak/people/DNQGJY0KtcHMirkidasA066yj5V'
```

A deleted object in Riak is just internally marked as delete, by setting a market known as a tombstone. Later, another process called a reaper clears the marked objects from the backend. This detail isn't normally important, except to note that any code you write that scans all keys will have to deal with tombstoned objects. Simply counting keys is not a reliable figure for summing active objects.

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

You should note that none of these list actions should be used in production (they're really expensive operations). But they are useful for development, or running for occasional analytics.

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

### Quorum


## Repairing

<!-- Anti-Entropy -->

### Read Repair

### Siblings


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

