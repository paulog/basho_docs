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

Riak is one of the simplest NoSQL databases to operate. In some ways, it's
downright mundane. Want more servers? Add them. A server crash at night? Sleep
until morning and fix it. But the fact that it generally hums without a hiccup,
does not diminish the importance of understanding this integral part of your
application stack.

We've covered the core concepts of Riak, and I've provided a taste of how to go
about using Riak, but there is more to Riak than that. There are details you
should know if you plan on operating a Riak cluster of your own.

## Clusters

Up to this point you've conceptually read about "clusters" and the "Ring" in
nebulous summations. What exactly do we mean, and what are the practical
implications of these details for Riak developers and operators?

A *cluster* in Riak is a managed collection of nodes that share a common Ring.

### The Ring

*The Ring* in Riak is actually a two-fold concept.

Firstly, the Ring is a function of the consistent hash space partitions,
managed by vnodes. This partition range is treated as circular, from 0 to
2^160-1 back to 0 again. (If you're wondering, yes this means that we are
limited to 2^160 nodes, which is a limit of a 1.46 quindecillion, or
`1.46 x 10^48`, node cluster. For comparison, there are only `1.92 x 10^49`
[silicon atoms on Earth](http://education.jlab.org/qa/mathatom_05.html).)

When we consider replication, the N value defines how many nodes an object is
replicated to. Riak makes a best attempt at spreading that value to as many
nodes as it can, so it copies to the next N adjacent nodes, starting with the
primary partition and counting around the Ring, if it reaches the last
partition, it starts over at the first one.

Secondly, the Ring is also used as a shorthand for describing the state of the
circular hash ring I just mentioned. This Ring (aka *Ring State*) is a
datastructure that gets passed around between nodes, so they all know the state
of the entire cluster. Which node manages which vnodes? If a node gets a
request for an object managed by other nodes, it consults the Ring and forwards
on the request to the proper nodes. It's a local copy of a contract that all of
the nodes agree to follow.

Obviously, this contract needs to stay in sync between all of the nodes. If a node is permanently taken
offline or a new one added, the other nodes need to readjust, balancing the partitions around the cluster,
then updating the Ring with this new structure. This Ring state gets passed between the nodes by means of
a *gossip protocol*.

### Gossip

The *gossip protocol* is Riak's method of keeping all nodes current on the state of the Ring. If a node goes up or down, that information is propgated to other nodes. Periodically, nodes will also send their status to a random peer for added consistency.

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
remembering that partitions are managed by vnodes, and in conversation are sometimes interchanged,
though I'll try and be more precise here.

Let's start with Riak configured to have 8 vnodes/partitions, which are set via `ring_creation_size`
in the `etc/app.config` file (we'll dig deeper into this file later).

```erlang
 %% Riak Core config
 {riak_core, [
               ...
               {ring_creation_size, 8},
```

In this example, I have a total of four Riak nodes running on `A@10.0.1.1`,
`B@10.0.1.2`, `C@10.0.1.3`, and `D@10.0.1.4`.

The following is Erlang, the language Riak was written in. Riak has the amazing, and probably
dangerous  command `attach`, that attaches an Erlang console to a live Riak node, loaded with
all of the Riak modules. So here we're getting a copy of the Ring from the locally running node.

The `riak_core_ring:chash(Ring)` function extracts the total count of partitions (8), with an array
of numbers representing the start of the partition, some fraction of the 2^160 number, and the node
name that represents a particular Riak server in the cluster.

```erlang
$ bin/riak attach
(A@10.0.1.1)1> {ok,Ring} = riak_core_ring_manager:get_my_ring().
(A@10.0.1.1)2> riak_core_ring:chash(Ring).
{8,
 [{0,'A@10.0.1.1'},
  {182687704666362864775460604089535377456991567872, 'B@10.0.1.2'},
  {365375409332725729550921208179070754913983135744, 'C@10.0.1.3'},
  {548063113999088594326381812268606132370974703616, 'D@10.0.1.4'},
  {730750818665451459101842416358141509827966271488, 'A@10.0.1.1'},
  {913438523331814323877303020447676887284957839360, 'B@10.0.1.2'},
  {1096126227998177188652763624537212264741949407232, 'C@10.0.1.3'},
  {1278813932664540053428224228626747642198940975104, 'D@10.0.1.4'}]}
```

To discover which partition the bucket/key `food/favorite` object would be stored in, for example,
we execute `riak_core_util:chash_key({<<"food">>, <<"favorite">>})` and get a wacky 160 bit Erlang
number we named `DocIdx` (document index).

Just to illustrate that Erlang binary value is a real number, the next line makes it a more
readable format, similar to the ring partition numbers.

```erlang
(A@10.0.1.1)3> DocIdx = riak_core_util:chash_key({<<"food">>, <<"favorite">>}).
<<80,250,1,193,88,87,95,235,103,144,152,2,21,102,201,9,156,102,128,3>>

(A@10.0.1.1)4> <<I:160/integer>> = DocIdx. I.
462294600869748304160752958594990128818752487427
```

With this `DocIdx` number, we can order the partitions, starting with first number greater than
`DocIdx`. The remaining partitions are in numerical order, until we reach zero, then
we loop around and continue to exhaust the list.

```erlang
(A@10.0.1.1)5> Preflist = riak_core_ring:preflist(DocIdx, Ring).
[{548063113999088594326381812268606132370974703616, 'D@10.0.1.4'},
 {730750818665451459101842416358141509827966271488, 'A@10.0.1.1'},
 {913438523331814323877303020447676887284957839360, 'B@10.0.1.2'},
 {1096126227998177188652763624537212264741949407232, 'C@10.0.1.3'},
 {1278813932664540053428224228626747642198940975104, 'D@10.0.1.4'},
 {0,'A@10.0.1.1'},
 {182687704666362864775460604089535377456991567872, 'B@10.0.1.2'},
 {365375409332725729550921208179070754913983135744, 'C@10.0.1.3'}]
```

`Ctrl^D`

So what does all this have to do with replication? With the above list, we simply replicate a write
down the list N times. If we set N=3, then the `food/favorite` object will be written to
the `D@10.0.1.4` node's partition `5480631...` (I truncated the number here),
`A@10.0.1.1` partition `7307508...`, and `B@10.0.1.2` partition `9134385...`.

If something has happend to one of those nodes, like a network split
(confusingly also called a partition---the "P" in "CAP"), the remaining
active nodes in the list become candidates to hold the data.

So if the partition `7307508...` write could not connect to node `10.0.1.1`, 
Riak would then attempt to write that partition `7307508...` to `C@10.0.1.3`
as a fallback (it's the next node in the list preflist after the 3 primaries).

Due to the structure of the Ring, how it distributes partitions, and how it
handles failures, it's relatively simple to ensure that data is replicated to
as many physical nodes as possible, while being able to remain operational if
a node is unavailable, by simply trying the next available node in the list.


### Hinted Handoff

When a node goes down data is replicated to a backup node. But this is not a solution, merely a
bandaid. So Riak will periodically trigger vnodes to check if they reside on the correct node
(according to the Ring). If not, the managing process will attempt to connect with the home
node, and if that node responds, will hand off any data it hold back to proper node.

As long as the temporary node cannot connect to the primary, it will continue to access writes
and reads on behalf of its incapacitated bretheren.

High availability is not the only purpose of hinted handoff. In the case where the ring changes,
because a node was added or removed, data must be transfered to its new home. In this case,
the same thing will happen: a vnode checks if it's in the correct place, and if not, attempts
to transfer its data to its new home node.


## Managing a Cluster

Now that we have a grasp of the general concepts of Riak, how users query it,
and how Riak manages replication, it's time to build a cluster. It's so easy to
do, in fact, I didn't bother discussing it for most of this book.

### Install

The Riak docs have all of the information you need to [[Install|Installing and Upgrading]] it per operating system. The general sequence is:

1. Install Erlang
2. Get Riak from a package manager (ala apt-get or Homebrew), or build from source (the results end up under `rel/riak`, with the binaries under `bin`).
3. Run `riak start`

Install Riak on four or five nodes---five being the recommended safe minimum for production.

### Command Line

Most Riak operations can be performed though the command line. We'll concern outselves with two: `riak` and `riak-admin`.

#### `riak`

Simply typing the `riak` command will give a useage list, although not a
terribly descriptive one.

```bash
Usage: riak {start|stop|restart|reboot|ping|console|attach|chkconfig|escript|version}
```

Most of these commands are self explanatory, once you know what they mean. `start` and `stop` are simple enough. `restart` means to stop the running node and restart it inside of the same Erlang VM (virtual machine), while `reboot` will take down the Erlang VM and restart everything.

You can print the current running `version`. `ping` will return `pong` if the server is in good shap, otherwise you'll get the *just-similar-enough-to-be-annoying* response `pang` (with an *a*), or a simple `Node *X* not responding to pings` if it's not running at all.

`chkconfig` is useful if you want to ensure your `etc/app.config` is not broken
(that is to say, it's parsable). I mentioned `attach` briefly above, when
we looked into the details of the Ring---it attaches a console to the local
running Riak server so you can execute Riak's Erlang code. And finally, `escript` is similar to console, except you pass in script file of commands you wish to run.

<!-- 
If you want to build this on a single dev machine, here is a truncated guide.
Download the Riak source code, then run the following:
make deps
make devrel
for i in {1..5}; do dev/dev$i/bin/riak start; done
for i in {1..5}; do dev/dev$i/bin/riak ping; done
for i in {2..5}; do dev/dev$i/bin/riak-admin cluster join dev1@127.0.0.1; done
dev/dev1/bin/riak-admin cluster plan
dev/dev1/bin/riak-admin cluster commit
You should now have a 5 node cluster running locally.
-->

#### `riak-admin`

The `riak-admin` command is the meat operations, the tool you'll use most often. This is where you'll join nodes to the Ring, diagnose issues, check status, and trigger backups.

```bash
Usage: riak-admin { cluster | join | leave | backup | restore | test | 
                    reip | js-reload | erl-reload | wait-for-service | 
                    ringready | transfers | force-remove | down | 
                    cluster-info | member-status | ring-status | vnode-status |
                    diag | status | transfer-limit | 
                    top [-interval N] [-sort reductions|memory|msg_q] [-lines N] }
```

Many of these commands are deprecated, and many don't make sense without a
cluster, but a few we can look at now.

`status` outputs a list of information about this cluster. It's mostly the same information you can get from getting `/stats` via HTTP, although the coverage of information is not exact (for example, riak-admin status returns `disk`, and `/stats` returns some computed values like `gossip_received`).

```
$ riak-admin status
1-minute stats for 'dev1@127.0.0.1'
-------------------------------------------
vnode_gets : 0
vnode_gets_total : 2
vnode_puts : 0
vnode_puts_total : 1
vnode_index_reads : 0
vnode_index_reads_total : 0
vnode_index_writes : 0
vnode_index_writes_total : 0
vnode_index_writes_postings : 0
vnode_index_writes_postings_total : 0
vnode_index_deletes : 0
...
```

Adding javascript or erlang files to Riak (as we did in the
[[developers chapter|A Little Riak Book: Developers]]) are not automatically found by the nodes,
but they instead must be informed by either `js-reload` or `erl-reload` command.

`riak-admin` also provides a little `test` command, so you can perform a read/write cycle
to a node, which I find useful for testing a client's ability to connect, and the node's
ability to write.

Finally, `top` is an analysis command checking the Erlang details of a partitular node in
real time. Different processes have different process ids (Pids), use varying amounts of memory,
queue up so many messages at a time (MsgQ), and so on. This is useful for advanced diagnostics,
and is especially useful if you know Erlang, or seek help from other users, the Riak team, or
Basho.

```bash
===============================================================================================================================
 'dev2@127.0.0.1'                                                          04:25:06
 Load:  cpu         0               Memory:  total       19597    binary         97
        procs     562                        processes    4454    code         9062
        runq        0                        atom          420    ets           994

Pid                 Name or Initial Func         Time       Reds     Memory       MsgQ Current Function
-------------------------------------------------------------------------------------------------------------------------------
<6132.154.0>        riak_core_vnode_manager       '-'       7426      90240          0 gen_server:loop/6                       
<6132.62.0>         timer_server                  '-'       5653       2928          0 gen_server:loop/6                       
<6132.61.0>         riak_sysmon_filter            '-'       4828       5864          0 gen_server:loop/6                       
<6132.155.0>        riak_core_capability          '-'       1425      13720          0 gen_server:loop/6                       
<6132.149.0>        riak_core_ring_manager        '-'       1161      88512          0 gen_server2:process_next_msg/9          
<6132.156.0>        riak_core_gossip              '-'        769      34392          0 gen_server:loop/6                       
<6132.542.0>        mi_scheduler                  '-'         35       2848          0 gen_server:loop/6                       
<6132.1552.0>       inet_tcp_dist:do_accept/6     '-'         30       2744          0 dist_util:con_loop/9                    
<6132.1554.0>       inet_tcp_dist:do_accept/6     '-'         30       2744          0 dist_util:con_loop/9                    
<6132.20.0>         net_kernel                    '-'         29       4320          0 gen_server:loop/6                       
```


### Making a Cluster

With several solitary nodes running---assuming they are networked and are able to communicate to
each other---launching a cluster is the simplest part.

Executing the `cluster` command will output a descriptive set of commands.

```
$ riak-admin cluster
The following commands stage changes to cluster membership. These commands
do not take effect immediately. After staging a set of changes, the staged
plan must be committed to take effect:

   join <node>                    Join node to the cluster containing <node>
   leave                          Have this node leave the cluster and shutdown
   leave <node>                   Have <node> leave the cluster and shutdown

   force-remove <node>            Remove <node> from the cluster without
                                  first handing off data. Designed for
                                  crashed, unrecoverable nodes

   replace <node1> <node2>        Have <node1> transfer all data to <node2>,
                                  and then leave the cluster and shutdown

   force-replace <node1> <node2>  Reassign all partitions owned by <node1> to
                                  <node2> without first handing off data, and
                                  remove <node1> from the cluster.

Staging commands:
   plan                           Display the staged changes to the cluster
   commit                         Commit the staged changes
   clear                          Clear the staged changes
```

To create a new cluster, you must `join` another node (any will do). Taking a
node out of the cluster uses `leave` or `force-remove`, while swapping out
an old node for a new one uses `replace` or `force-replace`.

I should mention here that using `leave` is the nice way of taking a node
out of commission. However, you don't always get that choice. If a server
happens to explode (or simply smoke ominously), you don't need it's approval
to remove if from the cluster, but can instead mark it as `down`.

But before we worry about removing nodes, let's add some first.

```bash
$ riak-admin cluster join dev1@127.0.0.1
Success: staged join request for 'dev2@127.0.0.1' to 'dev1@127.0.0.1'
$ riak-admin cluster join dev1@127.0.0.1
Success: staged join request for 'dev3@127.0.0.1' to 'dev1@127.0.0.1'
```

<aside class="sidebar"><h3>Don't Wait Too Long</h3>
You should always keep in mind the general pattern Riak
follows when you make a change to the cluster:

*Join/Leave/Down -> Ring state change -> Gossiped -> Hinted handoff*

Large amounts of data can take time and cause system strain to transfer, so
don't wait until it's too late to grow.
</aside>

Once all changes are staged, you must review the cluster `plan`. It will give you
all of the details of the nodes that are joining the cluster, and what it
will look like after each step or *transition*, including the `member-status`,
and how the `transfers` plan to handoff partitions.

Below is a simple plan, but there are cases when Riak requires multiple
transitions to enact all of your requested actions, such as adding and removing
nodes in one stage.

```bash
$ riak-admin cluster plan
=============================== Staged Changes ================================
Action         Nodes(s)
-------------------------------------------------------------------------------
join           'dev2@127.0.0.1'
join           'dev3@127.0.0.1'
-------------------------------------------------------------------------------


NOTE: Applying these changes will result in 1 cluster transition

###############################################################################
                         After cluster transition 1/1
###############################################################################

================================= Membership ==================================
Status     Ring    Pending    Node
-------------------------------------------------------------------------------
valid     100.0%     34.4%    'dev1@127.0.0.1'
valid       0.0%     32.8%    'dev2@127.0.0.1'
valid       0.0%     32.8%    'dev3@127.0.0.1'
-------------------------------------------------------------------------------
Valid:3 / Leaving:0 / Exiting:0 / Joining:0 / Down:0

WARNING: Not all replicas will be on distinct nodes

Transfers resulting from cluster changes: 42
  21 transfers from 'dev1@127.0.0.1' to 'dev3@127.0.0.1'
  21 transfers from 'dev1@127.0.0.1' to 'dev2@127.0.0.1'
```

Making changes to cluster membership can be fairly resource intensive, so Riak defaults to
only performing 2 transfers at a time. You can choose to alter this `transfer-limit` from
the `riak-admin`, but bear in mind the higher the number, the greater normal operations
will be impinged.

At this point, if you find a mistake in the plan, you have the chance to `clear` it and try
again. When you are ready, `commit` the cluster to enact the plan.

```
$ dev1/bin/riak-admin cluster commit
Cluster changes committed
```

Without any data, adding a node to a cluster is a quick operation. However, with large amounts of
data to be transfered to a new node, it can take quite a while before the service is available.

### Status Options

To check on a launching node's progress, you can run the `wait-for-service` command. It will
output the status of the service and stop when it's finally up. You can get a list of available
`services` through the similarly named command.

```
$ riak-admin wait-for-service riak_kv dev3@127.0.0.1
riak_kv is not up: []
riak_kv is not up: []
riak_kv is up
```

You can also see if the whole ring is ready to go with `ringready`. If the nodes do not agree
on the state of the ring, it will output `FALSE`, otherwise `TRUE`.

```
$ riak-admin ringready
TRUE All nodes agree on the ring ['dev1@127.0.0.1','dev2@127.0.0.1',
                                  'dev3@127.0.0.1']
```

For a more complete view of the status of the nodes in the ring, you can check out `member-status`.

```bash
$ riak-admin member-status
================================= Membership ==================================
Status     Ring    Pending    Node
-------------------------------------------------------------------------------
valid      34.4%      --      'dev1@127.0.0.1'
valid      32.8%      --      'dev2@127.0.0.1'
valid      32.8%      --      'dev3@127.0.0.1'
-------------------------------------------------------------------------------
Valid:3 / Leaving:0 / Exiting:0 / Joining:0 / Down:0
```

And for more details of any current handoffs or unreachable nodes, try `ring-status`. It
also lists some information from `ringready` and `transfers`. Below I turned off a node
to show what it might look like.

```bash
$ riak-admin ring-status
================================== Claimant ===================================
Claimant:  'dev1@127.0.0.1'
Status:     up
Ring Ready: true

============================== Ownership Handoff ==============================
Owner:      dev1 at 127.0.0.1
Next Owner: dev2 at 127.0.0.1

Index: 182687704666362864775460604089535377456991567872
  Waiting on: []
  Complete:   [riak_kv_vnode,riak_pipe_vnode]
...

============================== Unreachable Nodes ==============================
The following nodes are unreachable: ['dev3@127.0.0.1']

WARNING: The cluster state will not converge until all nodes
are up. Once the above nodes come back online, convergence
will continue. If the outages are long-term or permanent, you
can either mark the nodes as down (riak-admin down NODE) or
forcibly remove the nodes from the cluster (riak-admin
force-remove NODE) to allow the remaining nodes to settle.
```

If all of the above information options about your nodes weren't enough, you can
list the status of each vnode per node, via `vnode-status`. It'll show each
vnode by its partition number, give any status information, and a count of each
vnode's keys. Finally, you'll get to see each vnode's backend type---something I'll
cover in the next section.

```bash
$ riak-admin vnode-status
Vnode status information
-------------------------------------------

VNode: 0
Backend: riak_kv_bitcask_backend
Status: 
[{key_count,0},{status,[]}]

VNode: 91343852333181432387730302044767688728495783936
Backend: riak_kv_bitcask_backend
Status: 
[{key_count,0},{status,[]}]

VNode: 182687704666362864775460604089535377456991567872
Backend: riak_kv_bitcask_backend
Status: 
[{key_count,0},{status,[]}]

VNode: 274031556999544297163190906134303066185487351808
Backend: riak_kv_bitcask_backend
Status: 
[{key_count,0},{status,[]}]

VNode: 365375409332725729550921208179070754913983135744
Backend: riak_kv_bitcask_backend
Status: 
[{key_count,0},{status,[]}]
...
```

Some commands we did not cover are either deprecated in favor of their `cluster`
equivalents (`join`, `leave`, `force-remove`, `replace`, `force-replace`), or 
flagged for future removal `reip` (use `cluster replace`).

The last command is `diag`, which requires a [Riaknostic](http://riaknostic.basho.com/)
installation to give you more diagnostic tools.

I know this was a lot to digest, and probably pretty dry. Walking through command
line tools usually is. There are plenty of details behind many of the `riak-admin`
commands, too numerous to cover in such a short book. I encourage you to toy around
with them on your own installation.


## How Riak is Built

It's hard to call Riak a single project. It's probably more correct to think of
Riak as the center of gravity for a whole system of projects. As we've gone over
before, Riak is built on Erlang, but that's not quite correct either. It's better
to say Riak is fundamentally Erlang, with some pluggable native C code components
(like leveldb), Java (Yokozuna), and even JavaScript (for Mapreduce or commit hooks).

### Erlang

When you start up a Riak node, it also starts up an Erlang VM (virtual machine) to run
and manage Riak's processes, including vnodes, process messages, gossips, resource
management and more. The running Riak operating system process is found as a `beam.smp`
command with many, many arguments.

```
$ ps -o command | grep beam
/riak/erts-5.9.1/bin/beam.smp -K true -A 64 -W w -- -root /riak \
-progname riak -- -home /Users/ericredmond -- \
-boot /riak/releases/1.2.1/riak -embedded -config /riak/etc/app.config \
-pa ./lib/basho-patches -name dev4@127.0.0.1 -setcookie testing123 -- console
```

Those arguments are configured through the `etc/vm.args` file. There are a couple
setting you should pay special attention to.

The `name` setting is the name of the current Riak node. Every node in your cluster
needs a different name. It should have the IP address or dns name of the server
this node runs on, and optionally a different prefix---though some people just like
to call it riak for simplicity (eg: `riak@node15.myhost`).

The `setcookie` setting is a setting for Erlang to perform inter process
communication across nodes. Every node in the cluster needs to have the same
cookie name. I recommend you change the name from `riak` to something a little
less likely to accidentally conflict, like `hihohihoitsofftoworkwego`.

My `vm.args` looks like this:

```
## Name of the riak node
-name dev1@127.0.0.1

## Cookie for distributed erlang.  All nodes in the same cluster
## should use the same cookie or they will not be able to communicate.
-setcookie testing123
```

Continuing down the `vm.args` file are more erlang settings, some environment
variables that are set up for the process (prefixed by `-env`), followed by
some optional SSL encryption settings.

### `riak_core`

If any single component could be called "Riak", it would be *Riak Core*. Core,
and implementations are responsible for managing the partitioned keyspace, launching
and supervising vnodes, preference list building, hinted handoff, and things that
aren't related specifically to client interfaces, handling requests, or storage.

Riak Core config

### `riak_kv`

Riak KV is the Key/Value implementation of Riak Core. This is where much of the
actual work happens, handling requests, coordinating them for redundancy and
read repair. It's what makes the Riak as we know a KV store rather than something
else, like a Cassandra-style columnar datastore.

Riak KV config

### `bitcask`, `eleveldb`, `memory`, `multi`

Several modern databases have swappable backends, and Riak is no different in that
respect. Riak currently supports three different storage engines---*Bitcask*,
*eLevelDB*, and *Memory*---and one hybrid called *Multi*.


Backend config

riak_kv_bitcask_backend
riak_kv_eleveldb_backend
riak_kv_memory_backend
riak_kv_multi_backend

### `riak_api`

So far, all of the components we've seen have been inside the Riak house. The API
is the front door. *In a perfect world*, the API would manage two implementations:
Protocol buffers (PB), an efficient binary protocol framework designed by Google;
and HTTP. Unfortunately the HTTP client interface is not yet ported, leaving only
PB for now---though I like to think of this as merely an implementation detail,
soon unraveled from KV.

In any case, Riak API represents the client facing aspect of Riak. Implementations
handle how data is encoded and transfered, and this project handles the services
for presenting those interfaces, managing connections, providing entry points.


API config

### `riak_pipe`

Riak pipe config

### Other projects

Other projects add depth to Riak, though aren't strictly necessary, in a
functional sense. Two of these projects are Lager, Riak's chosen logging
system; and Sysmon, a useful system monitor.


More config

`lager`, `riak_sysmon`

## Setups



### Secondary Indexing (2i)

<!-- riak_kv_eleveldb_backend -->

<!-- How it works -->
<!-- http://docs.basho.com/riak/latest/tutorials/querying/Secondary-Indexes/ -->

### MapReduce

<!-- ## Configuration Notes -->

<!-- ## Reading Logs -->

### Search (Yokozuna)


## Tools

### Riaknostic

### Riak Control

## Scaling Riak

Vertically (by adding bigger hardware), and Horizontally (by adding more nodes).

