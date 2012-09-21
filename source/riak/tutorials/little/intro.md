---
title: "A Little Riak Book: Intro"
project: riak
version: 1.2.0+
document: tutorials
toc: true
versions: false
audience: beginner
keywords: []
---

<!-- As current users will tell you, Riak "just works". This is a testament to Riak's design, but has the downside where you can run a cluster for quite a long time without knowing how it works. This short manual is an attempt at resolving that conflict.
 -->

## What is Riak

Riak is an open-source, distributed key/value database for high availability, fault-tolerance, and near-linear scalability. It's a mouthful, that basically means Riak has high uptime, and grows with you.

<!-- Data has become more available, more valuable in the aggregate, and easier to access. -->


In a more interconnected world, some major shifts have occurred in data management. The web and mobile devices have spurred an explosion in collecting and accessing data unseen in the history of the world. And with the increase in interconnected data such as social networks.

In addition, the improvements in prices, technology improvements, and virtualization have put vast amounts of computing power and storage within the grasp of most everyone, spuring data architectures based on clusters of commodity hardware.

All of these considerations have lead to an abundance of highly interconnected data, requiring new and novel ways to manage it. The ability to both store and quickly access this data, in a predictable and low latency manner, has given rise to a new class of databases, loosely called NoSQL databases.


No longer is Big Data the exclusive domain of a handful of companies with the expertise and funding to capture and process large amounts of data. Now anyone can handle data. In fact, a growing number of customers are expecting it.

the amount of data being collected and managed has also increased at a staggering rate. 

Many databases today claiming to work for *Big Data* were either retrofited to cluster, or begin easily on small-scales with increasingly complex configuration and operational requirements as your data swells. Riak was designed from the ground-up based on the real-world proven Dynamo paper.

<aside class="sidebar">
<h3>What is Big Data?</h3>
There's a lot of discussion around what constitutes <em>Big Data</em>. I have a 6 Terabyte RAID in my house to store videos and other backups. Does that count? On the other hand, CERN grabbed about [200 Petabytes](http://www.itbusinessedge.com/cm/blogs/lawson/the-big-data-software-problem-behind-cerns-higgs-boson-hunt/?cs=50736) looking for the Higgs boson.

It's a hard number to pin down, because Big Data is a personal figure. What's big to one might be small to another. Ths is why many definitions don't refer to byte count at all, but instead about relative potentials. A reasonable definition of Big Data is [provided by Gartner](http://www.gartner.com/DisplayDocument?ref=clientFriendlyUrl&id=2057415).

<blockquote>Big Data are high-volume, high-velocity, and/or high-variety information assets that require new forms of processing to enable enhanced decision making, insight discovery and process optimization.</blockquote>
</aside>

Storage is easy and cheap. But large amounts of data that is highly available is a different story.

The focus of Riak is high-volume (data that's available to read and write when you need it), high-velocity (easily responds to growth), and high-variety information assets (you can store any type of data as a value). It's built to handle Big Data, whatever that means for you.

Riak is built to be highly available, meaning that it responds to requests quickly at very large scales, even if your application is storing and serving terabytes of data a day. Riak was designed for applications where every moment of downtime costs money.

Riak has been used in production for three years, and is used by Github, Comcast, Voxer, Disqus and many more.

### History

Riak was created in X

## Installing

This is not an "install and follow along" guide. This is a "read and comprehend" guide. Don't feel compelled to install before continuing to read.

## Launching
