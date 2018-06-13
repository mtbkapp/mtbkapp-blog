---
title: "Datomic Datalog Rollup"
date: 2018-05-17T10:19:50-06:00
draft: false 
---

Recently I've been looking at different ways to calculate roll-up aggregations
in a tree of data. These calculations can be done with recursive algorithms. Here 
I show an example in Datomic.


The datomic schema. Just three attributes: `:o/name`, `:o/parent`, and `:o/x` 
(the rollup field).
{{<highlight clojure >}}
[{:db/ident :o/name
  :db/valueType :db.type/string
  :db/cardinality :db.cardinality/one
  :db/unique :db.unique/value
  :db/id #db/id[:db.part/db]
  :db.install/_attribute :db.part/db}
 {:db/ident :o/parent
  :db/valueType :db.type/ref
  :db/cardinality :db.cardinality/one
  :db/id #db/id[:db.part/db]
  :db.install/_attribute :db.part/db}
 {:db/ident :o/x
  :db/valueType :db.type/long
  :db/cardinality :db.cardinality/one
  :db/index true
  :db/id #db/id[:db.part/db]
  :db.install/_attribute :db.part/db}]
{{</highlight>}}



Next I define a small tree as a vector of vectors in the form `[node parent]`:

{{<highlight clojure >}}
[[:pi nil] ;no parent
 [:pf1 :pi]
 [:pf2 :pi]
 [:us1 :pf1]
 [:us2 :pf1]
 [:us3 :us2]
 [:us4 :us2]
 [:us5 :pf2]
 [:us6 :pf2]
 [:us7 :us6]]
{{</highlight>}}


The date is processed and inserted into the Datomic db. Below is a visualization 
of the tree (drawn with graphviz, note that the arrow are reversed from what 
is in the data):

<div style="width: 100%">
  <img style="display: block; margin: 0 auto;" src="../tree.png" />
</div>


## Ancestor Rule 
`?root` is an ancestor of `?node` if `?root` is `?node`'s parent *or* if `?root`
is the parent of some node `?x` and `?x` is an ancestor of `?node`. 

{{<highlight clojure >}}
[[(ancestor ?root ?node) ; base case
  [?node :o/parent ?root]] 
 [(ancestor ?root ?node) ; recursive case
  [?x :o/parent ?root]
  [ancestor ?x ?node]]]
{{</highlight>}}

## Queries

Find all the decendent's for the node named by `(name :pi)`:

{{<highlight clojure >}}
(d/q '[:find ?descedant-name 
       :in $ % ?root-name
       :where 
       [?root :o/name ?root-name]
       [ancestor ?root ?dec]
       [?dec :o/name ?descedant-name]]
     (d/db conn)
     ancestor-rules
     (name :pi))
{{</highlight>}}

{{<highlight clojure >}}
user=> [#{["us2"] ["us1"] ["us4"] ["us3"] ["us6"] ["us5"] ["us7"] ["pf2"] ["pf1"]} 
{{</highlight>}}



Find all the "leaf" nodes in the tree rooted at the node named `?root-name`.

{{<highlight clojure >}}
(d/q '[:find ?dec-name 
       :in $ % ?root-name
       :where 
       [?root :o/name ?root-name]
       [ancestor ?root ?dec]
       [?dec :o/name ?dec-name]
       (not [_ :o/parent ?dec])] ; no parent points to dec
     (d/db conn)
     ancestor-rules
     (name :pi))
{{</highlight>}}

{{<highlight clojure >}}
user=> #{["us1"] ["us4"] ["us3"] ["us5"] ["us7"]}
{{</highlight>}}


Sum all the leaf nodes' `:o/x` attribute.
{{<highlight clojure >}}
(d/q '[:find (sum ?x) 
       :with ?dec
       :in $ % ?root-name
       :where 
       [?root :o/name ?root-name]
       ; no parent points to dec
       (not [_ :o/parent ?dec])
       [ancestor ?root ?dec]
       [?dec :o/x ?x]]
     (d/db conn)
     ancestor-rules
     (name :pi))
{{</highlight>}}

{{<highlight clojure >}}
user=> [[50]]]
{{</highlight>}}

## Summary
Just three Datomic Datalog queries for working with rollup aggregations
in a tree structure.  I'm not sure if any of these queries are performant.


