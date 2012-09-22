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

In an increasingly interconnected world, major shifts have occurred in data management. The web and connected devices have spurred an explosion of both data collection and access unseen in the history of the world. The amount of data being stored and managed has grown at a staggering rate, and in parallel, more people than ever require fast and reliable access to this data. This is generally called *[[Big Data|A Little Riak Book: Intro#big-data]]*.

<aside id="big-data" class="sidebar"><h3>So What is Big Data?</h3>

There's a lot of discussion around what constitutes <em>Big Data</em>.

I have a 6 Terabyte RAID in my house to store videos and other backups. Does that count? On the other hand, CERN grabbed about [200 Petabytes](http://www.itbusinessedge.com/cm/blogs/lawson/the-big-data-software-problem-behind-cerns-higgs-boson-hunt/?cs=50736) looking for the Higgs boson.

It's a hard number to pin down, because Big Data is a personal figure. What's big to one might be small to another. Ths is why many definitions don't refer to byte count at all, but instead about relative potentials. A reasonable, albeit wordy, [definition of Big Data](http://www.gartner.com/DisplayDocument?ref=clientFriendlyUrl&id=2057415) is given by Gartner.

<blockquote>Big Data are high-volume, high-velocity, and/or high-variety information assets that require new forms of processing to enable enhanced decision making, insight discovery and process optimization.</blockquote>
</aside>

The sweet-spot of Riak is high-volume (data that's available to read and write when you need it), high-velocity (easily responds to growth), and high-variety information assets (you can store any type of data as a value).

Riak was built as a solution to real Big Data problems, based on the [[Amazon Dynamo|Dynamo]] design. But Riak was also built to be easy to operate and remain highly available at all times, while respecting the reality of consistency tradeoffs at scale.

Riak is built to be highly available, meaning that it responds to requests quickly at very large scales, even if your application is storing and serving terabytes of data a day.

So do you need Riak? A good rule of thumb for potential users is to ask yourself if every moment of downtime will cost your system money. Not all systems require such extreme amounts of uptime, and if you don't, Riak may not be for you.

Riak has been used in production for years before it was spun off into it's own open-source project in 2009. It's currently used by Github, Comcast, Voxer, Disqus and others, with the larger system storing hundreds of TBs of data, and handling several GBs per node daily.

## Installing

This is not an "install and follow along" guide. This is a "read and comprehend" guide. Don't feel compelled to install before continuing to read.

## Launching

