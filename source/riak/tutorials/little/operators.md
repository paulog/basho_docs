---
title: "A Little Riak Book: Operators"
project: riak
version: 1.2.0+
document: tutorials
toc: true
versions: false
audience: beginner
keywords: []
prev: ["Developers", "developers.html"]
up:   ["A Little Riak Book", "index.html"]
next: ["Notes", "notes.html"]
---

<!-- What Riak is famous for is its simplicity to operate and stability at increasing scales. -->

Riak is one of the simplest NoSQL databases to operate. In some ways, it's downright mundane. Want more servers? Add them. A server crash at night? Sleep until morning and fix it.


### Gossip

The gossip protocol is Riak's way of keeping each node current on the state of the Ring. If a node goes up or down, that information is propgated to other nodes. Periodically, nodes will also send their status to eachother, just for added consistency. Gossiping is an important component for Riak's next feature.

### Hinted Handoff

If a node has been added/removed or moved from offline to online, Riak has to balance the vnodes the same by shuffling them around. This shuffling is called *hinted handoff*, because 1) a vnode has a *hint* on where it should go (this information is gossiped), and 2) the data is handed off (transferred) to its new home.

This means that, although you don't have to do anything when you take a server up/down (or when it returns to the cluster), Riak still has some data to transfer around. Due to it's consistent-hashing style design, this data transfer is as minimal as it can be.

[Hinted handoff is one of the keys to Riak's availability, since requests can continue being served as if a node still operated.]

## The Ring

Up to this point we've talked conceptually about "clusters" and a the "Ring".

## Clusters

## Setups

### Secondary Indexing (2i)

<!-- riak_kv_eleveldb_backend -->

<!-- How it works -->
<!-- http://docs.basho.com/riak/latest/tutorials/querying/Secondary-Indexes/ -->

### Search

### MapReduce

## Configuration Notes

## Reading Logs

## Riak Control

## Scaling Riak

Vertically (by adding bigger hardware), and Horizontally (by adding more nodes).




<!--
TODO: from Developers

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
