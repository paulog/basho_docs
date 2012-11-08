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

Riak is one of the simplest NoSQL databases to operate. In some ways, it's downright
mundane. Want more servers? Add them. A server crash at night? Sleep until morning and
fix it. But the fact that it generally hums without a hiccup, does not diminish the
importance of understanding this integral part of your application stack.

We've covered the core concepts of Riak, and I've provided a taste of how to go about using
Riak, but there is more to Riak than that. There are details you should know if you plan on
operating a Riak cluster of your own.

## Clusters

Up to this point you've conceptually read about "clusters" and the "Ring" in
nebulous summations. What exactly do we mean, and what are the practical implications 
of these details for Riak developers and operators?

### The Ring

*The Ring* in Riak is actually a two-fold concept.

Firstly, the Ring is a function of the consistent hash space partitions, managed by vnodes.
This partition range is treated as circular, from 0 to 2^160-1 back to 0 again. (If you're
wondering, yes this means that we are limited to 2^160 nodes, which is a limit of a
1.46 quindecillion, or `1.46 x 10^48`, node cluster. For comparison, there are only
`1.92 x 10^49` [silicon atoms on Earth](http://education.jlab.org/qa/mathatom_05.html).)

When we consider replication, the N value defines how many nodes an object is replicated to.
Riak makes a best attempt at spreading that value to as many nodes as it can, so it copies
to the next N adjacent nodes, starting with the primary partition and counting around
the Ring, if it reaches the last partition, it starts over at the first one.

Secondly, the Ring is also used as a shorthand for describing the state of the circular hash
ring I just mentioned. This Ring (aka *Ring State*) is a datastructure that gets passed around
between nodes, so they all know the state of the entire cluster. Which node
manages which vnodes? If a node gets a request for an object managed by other nodes, it consults
the Ring and forwards on the request to the proper nodes. It's a local copy of a contract that
all of the nodes agree to follow.

Obviously, this contract needs to stay in sync between all of the nodes. If a node is permanently taken
offline or a new one added, the other nodes need to readjust, balancing the partitions around the cluster,
then updating the Ring with this new structure. This Ring state gets passed between the nodes by means of
a *gossip protocol*.

### Gossip

The *gossip protocol* is Riak's method of keeping all nodes current on the state of the Ring. If a node goes up or down, that information is propgated to other nodes. Periodically, nodes will also send their status to each other for added consistency.

[IMAGE]

Propogating changes in Ring is an asynchronous operation, and can take a couple minutes depending on
Ring size.

<!-- Transfers will not start while a gossip is in progress. -->


Currently, the ability to change the total number of vnodes of a cluster is not feasible. This
means that you *must have an idea of how large you want your cluster to grow in a single
datacenter*. Although a basic install starts with 64 vnodes, if you plan any cluster larger
than 6 or so servers you should increase vnodes to `256` or `1024`.

The number of vnodes must be a power of 2 (eg. `64`, `256`, `1024`, etc).

### How Replication Uses the Ring

Even if you are not a coder, it's worth taking a look at this Ring example. It's also worth
remembering that partitions are managed by vnodes, and in many cases are used interchangabley,
though I'll try and be more precise here.

Let's start with Riak configured to have 8 vnodes, which is set via `ring_creation_size`
in the `etc/app.config` file.

```erlang
 %% Riak Core config
 {riak_core, [
               ...
               {ring_creation_size, 8},
```

In this example, I have a total of three Riak nodes running on `10.0.1.1`, `10.0.1.2` and `10.0.1.3`.

The following is Erlang, the language Riak was written in. Riak has the amazing, and probably dangerous 
command `attach`, that attaches an Erlang console to a running Riak node, loaded with all of the
Riak modules. So here we're getting a copy of the Ring from the locally running node.

The `riak_core_ring:chash(Ring)` function extracts the total count of partitions (8), with an array
of numbers representing the start of the partition, some fraction of the 2^160 number, and the node
name that represents a particular Riak server in the cluster.

```erlang
$ bin/riak attach
(a@10.0.1.1)1> {ok,Ring} = riak_core_ring_manager:get_my_ring().
(a@10.0.1.1)2> riak_core_ring:chash(Ring).
{8,
 [{0,'a@10.0.1.1'},
  {182687704666362864775460604089535377456991567872, 'b@10.0.1.2'},
  {365375409332725729550921208179070754913983135744, 'c@10.0.1.3'},
  {548063113999088594326381812268606132370974703616, 'a@10.0.1.1'},
  {730750818665451459101842416358141509827966271488, 'b@10.0.1.2'},
  {913438523331814323877303020447676887284957839360, 'c@10.0.1.3'},
  {1096126227998177188652763624537212264741949407232, 'a@10.0.1.1'},
  {1278813932664540053428224228626747642198940975104, 'b@10.0.1.2'}]}
```

To find out what partition the bucket/key `food/favorite` object would be stored in, for example,
we execute `riak_core_util:chash_key({<<"food">>, <<"favorite">>})` and get a wacky 160 bit Erlang
number we named `DocIdx`.

And just to illustrate that Erlang binary value is a real number, the next line makes it a more
readable format, similar to the ring partition numbers.

```erlang
(a@10.0.1.1)3> DocIdx = riak_core_util:chash_key({<<"food">>, <<"favorite">>}).
<<80,250,1,193,88,87,95,235,103,144,152,2,21,102,201,9,156,102,128,3>>

(a@10.0.1.1)4> <<I:160/integer>> = DocIdx. I.
462294600869748304160752958594990128818752487427
```

With this `DocIdx` number, we can order the partitions, starting with first number greater than
`DocIdx`. The remaining partitions are in numerical order, until we reach zero, then
we continue to exhaust the list.

```erlang
(a@10.0.1.1)5> Preflist = riak_core_ring:preflist(DocIdx, Ring).
[{548063113999088594326381812268606132370974703616, 'a@10.0.1.1'},
 {730750818665451459101842416358141509827966271488, 'b@10.0.1.2'},
 {913438523331814323877303020447676887284957839360, 'c@10.0.1.3'},
 {1096126227998177188652763624537212264741949407232, 'a@10.0.1.1'},
 {1278813932664540053428224228626747642198940975104, 'b@10.0.1.2'},
 {0,'a@10.0.1.1'},
 {182687704666362864775460604089535377456991567872, 'b@10.0.1.2'},
 {365375409332725729550921208179070754913983135744, 'c@10.0.1.3'}]
```

So what does all this have to do with replication? With the above list, we simply replicate a write
down the list N times. If we set N=3, then the `food/favorite` object will be written to
the `a@10.0.1.1` node's partition `5480631...` (the above number is truncated), `b@10.0.1.2`
partition `7307508...`, and `c@10.0.1.3` partition `9134385...`.

If something has happend to one of those nodes, like a network split (confusingly also called a
partition, the "P" in "CAP"), the next active nodes in the list become candidates to hold
the data.

So if the partition `7307508...` write could not connect to node `b@10.0.1.2`, Riak would then
attempt to write partition `7307508...` to `a@10.0.1.1` as a fallback.

Because of the structure of the Ring, how it distributes partitions, and how it handles
failures, it's relatively simple to ensure that data is replicated to as many physical nodes
as possible, while being able to remain operational if a node is unavailable, by simply
trying the next available node in the list.


### Hinted Handoff

When a node goes down data is replicated to a backup node. But this is not a solution, merely a bandaid.
So Riak will periodically trigger vnodes to check if they reside on the correct node (according to the Ring).
If not, the managing process will attempt to connect with the home node, and if that node
responds, will hand off any data it hold back to proper node.

As long as the temporary node cannot connect to the primary, it will continue to access writes
and reads on behalf of its incapacitated bretheren.

Of course, high availability is not the only purpose of hinted handoff. In the case where the
ring changes, because a node was added or removed, data must be transfered to its new home.


## Managing a Cluster



### Command Line

Checks on the state of the ring, 

`riak-admin ringready`

### Making a Cluster

### Adding/Removing Nodes

This is the general pattern when a node joins a cluster that already has data

Join/Leave -> Ring state change -> Gossiped -> Hinted handoff


## How Riak is Built

### Erlang

vm.args

### riak_core

Riak Core config

### riak_kv

Riak KV config

### bitcask, eleveldb

### riak_api

### Other projects

lager, riak_sysmon

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





...


### Hinted Handoff

If a node has been added/removed or moved from offline to online, Riak has to balance the vnodes the same by shuffling them around. This shuffling is called *hinted handoff*, because 1) a vnode has a *hint* on where it should go (this information is gossiped), and 2) the data is handed off (transferred) to its new home.

This means that, although you don't have to do anything when you take a server up/down (or when it returns to the cluster), Riak still has some data to transfer around. Due to it's consistent-hashing style design, this data transfer is as minimal as it can be.

[Hinted handoff is one of the keys to Riak's availability, since requests can continue being served as if a node still operated.]

