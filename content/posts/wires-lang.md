---
title: "Wires DSL w/ Clojure Spec"
date: 2017-10-12T14:19:31-04:00
draft: false 
---

A while ago I found [Beautiful Racket](https://beautifulracket.com/) by 
Matthew Butterick. As I worked through the tutorials I found myself wanting to
try the same thing with Clojure. Here I'm going to show how I implemented 
the Wires language from [Beautiful Racket](https://beautifulracket.com/) in 
Clojure with spec and macros. I think it's not a bad pattern for building 
complicated macros in Clojure. In this case the macro will take a program 
written in the Wires language and produce Clojure code that computes the result.

The first thing I did was write an example program written in the Wires Language.

{{<highlight clojure >}}
(wires 
  x AND y -> d
  x OR y -> e
  x LSHIFT 2 -> f
  y RSHIFT 2 -> g
  NOT x -> h
  NOT y -> i
  123 -> x
  456 -> y)
{{</highlight>}} 

## Specs

Then I started building up specs.


First constants
{{<highlight clojure >}}
(require '[clojure.spec.alpha :as spec])


(spec/def :wires/constant int?)
{{</highlight>}} 

Then names for the wires. Which in the examples I've seen are always a single
letter but here I allow for them to be of any length that match the regex.
{{<highlight clojure >}}
(spec/def :wires/name (spec/and simple-symbol? 
                                #(re-matches #"[a-z]+" (name %))))
{{</highlight>}}

An operand can be a constant or a variable.
{{<highlight clojure >}}
(spec/def :wires/operand (spec/or :constant :wires/constant 
                                  :name :wires/name))
{{</highlight>}}

The language appears to have three types of expressions. Below are the types
their specs.

Constant:
{{<highlight clojure >}}
123 -> x
{{</highlight>}} 

{{<highlight clojure >}}
(spec/def :wires/constant-expr 
          (spec/cat :operand :wires/operand 
                    :arrow #{'->} 
                    :out :wires/name))
{{</highlight>}} 

Unary:
{{<highlight clojure >}}
NOT x -> nx
{{</highlight>}} 

{{<highlight clojure >}}
(spec/def :wires/unary-expr 
          (spec/cat :op #{'NOT} 
                    :operand :wires/operand 
                    :arrow #{'->}
                    :out :wires/name))
{{</highlight>}} 


and Binary:
{{<highlight clojure >}}
x LSHIFT 2 -> f
{{</highlight>}} 

{{<highlight clojure >}}
(spec/def :wires/binary-expr 
          (spec/cat :left :wires/operand 
                    :op binary-ops 
                    :right :wires/operand 
                    :arrow #{'->} 
                    :out :wires/name))
{{</highlight>}} 

Now I combine the individual expression type specs into a single spec. 
{{<highlight clojure >}}
(spec/def :wires/expr (spec/alt :constant :wires/constant-expr
                                :unary :wires/unary-expr
                                :binary :wires/binary-expr))
{{</highlight>}} 

And because a program is just any number of these expressions I can now define
a spec for the whole language:
{{<highlight clojure >}}
(spec/def :wires/wires (spec/+ :wires/expr))
{{</highlight>}} 

From here I wanted to see the conformed value so that I can write a compiler
of sorts that translates the conformed value into Clojure code.
{{<highlight clojure >}}
(pprint/pprint
  (spec/conform :wires/wires 
                '(x AND y -> d
                  x OR y -> e
                  x LSHIFT 2 -> f
                  y RSHIFT 2 -> g
                  NOT x -> h
                  NOT y -> i
                  123 -> x
                  456 -> y)))
{{</highlight>}} 

{{<highlight clojure >}}
[[:binary
   {:left [:name x], :op AND, :right [:name y], :arrow -&gt;, :out d}]
  [:binary
   {:left [:name x], :op OR, :right [:name y], :arrow -&gt;, :out e}]
  [:binary
   {:left [:name x],
    :op LSHIFT,
    :right [:constant 2],
    :arrow -&gt;,
    :out f}]
  [:binary
   {:left [:name y],
    :op RSHIFT,
    :right [:constant 2],
    :arrow -&gt;,
    :out g}]
  [:unary {:op NOT, :operand [:name x], :arrow -&gt;, :out h}]
  [:unary {:op NOT, :operand [:name y], :arrow -&gt;, :out i}]
  [:constant {:operand [:constant 123], :arrow -&gt;, :out x}]
  [:constant {:operand [:constant 456], :arrow -&gt;, :out y}]]
{{</highlight>}} 

At this point I was pretty excited (even though this is a toy language). Now 
onto the compiler. 

## Compiler
I found it helpful to take the example from above and translate it manually into
what I think the compiler's output should be.
{{<highlight clojure >}}
(let [x (short 123)
      y (short 456)
      d (bit-and x y)
      e (bit-or x y)
      f (bit-shift-left x 2)
      g (bit-shift-right y 2)
      h (bit-not x)
      i (bit-not y)]
  {:x x :y y :d d :e e :f f :g g :h h :i i})
{{</highlight>}} 

Now I was tempted to just start translating all this into a `let` form, but then
I remembered that `let` forms are evaluated sequentially, so one can't use `x`
unless `x` was already bound to a name (or in scope some other way). But the 
Wires language doesn't appear to have this property. It allows the wires to be 
defined in any order.

For some reason I see directed graphs over and over again in programing. I see
it as the basis for a solution to this problem. If I say a node in the graph
is a name of a wire and the edges encodes the fact that one wire depends on 
the value of another wire, then I can run a topological sort on the graph to
get a valid ordering for the `let` form. 

For this I used the graph library [Loom](https://github.com/aysylu/loom) that 
has implementations for directed graphs and topological sort (among a decent 
amount of other good things).

First collect all the names of the wires from the conformed value.
{{<highlight clojure >}}
(defn wire-names
  [program]
  (map (comp :out second) program))
{{</highlight>}} 

Next collect the edges from the conformed value and return each edge as a 
vector. The trouble here is that this has to account for all the types of 
expressions.
{{<highlight clojure >}}
(defn make-dep
  "Returns a dependency edge for an output wire and an operand from the 
  conformed value"
  [out [operand-type operand-value]]
  (if (= operand-type :name)
    [operand-value out]
    []))

(defn wire-deps
  "Looks at each expression and returns all the dependency edges."
  [program]
  (into []
        (comp (mapcat (fn [[expr-type expr]]
                        (let [output (:out expr)]
                          (case expr-type
                            :binary [(make-dep output (:left expr))
                                     (make-dep output (:right expr))]
                            :unary [(make-dep output (:operand expr))]
                            :constant [(make-dep output (:operand expr))]))))
		          (remove empty?))
        program))
{{</highlight>}} 

Now that I have the nodes and the edges I can build a graph and from that 
graph get the order for how the wires in the `let` form. 
{{<highlight clojure >}}
(require '[loom.graph :as graph]
          [loom.alg :as graph-alg])

(defn dep-graph
  "Produce a dependency graph from the given conformed program."
  [program]
  (apply graph/add-edges
         (apply graph/add-nodes (graph/digraph) (wire-names program))
         (wire-deps program)))


(defn wire-order
  "Returns the wire names in the order they should be calculated"
  [program]
  (graph-alg/topsort (dep-graph program)))
{{</highlight>}} 

### Compiling Expressions 
So now I go basically go through all the specs again and write code to compile
their conformed values into Clojure code.

#### Operands
I'm going to cheat a little bit on the type of numbers that
the wires language deals with. It's supposed to be 16 bit unsigned integers
but, as far as I know, Java doesn't have unsigned integers so I used `short`s
because they are close enough.
{{<highlight clojure >}}
(defn compile-operand
  [[operand-type operand-value]]
  (cond (= operand-type :constant) `(short ~operand-value)
        (= operand-type :name) operand-value))
{{</highlight>}} 

#### Constant Expressions
Each expression is put in it's own list. This list represents one line of the
`let` block. Later each line/list will be combined into one vector.
{{<highlight clojure >}}
(defn compile-constant-expr
  [expr]
  (list (:out expr) (compile-operand (:operand expr))))
{{</highlight>}} 

Clojure has bit manipulation functions. I need a mapping between the Wires
language operators and Clojure's functions.
{{<highlight clojure >}}
(def op-map '{NOT bit-not
              AND bit-and
              OR bit-or
              RSHIFT bit-shift-right
              LSHIFT bit-shift-left})
{{</highlight>}} 

Now I can define the functions that compile unary and binary expressions.
{{<highlight clojure >}}
(defn compile-unary-expr
  [expr]
  (list (:out expr) (list (get op-map (:op expr))
                          (compile-operand (:operand expr)))))
{{</highlight>}} 

{{<highlight clojure >}}
(defn compile-binary-expr
  [expr]
  (list (:out expr) (list (get op-map (:op expr))
                          (compile-operand (:left expr))
                          (compile-operand (:right expr)))))
{{</highlight>}} 

I can now write a function to compile any single expression.
{{<highlight clojure >}}
(defn compile-wire
  [[expr-type expr]]
  (case expr-type
    :binary (compile-binary-expr expr)
    :unary (compile-unary-expr expr)
    :constant (compile-constant-expr expr)))
{{</highlight>}} 

Taking the example of a conformed value of a Wires program from above and mapping
each expression through the `compile-wire` function gives me:
{{<highlight clojure >}}
((d (bit-and x y))
 (e (bit-or x y))
 (f (bit-shift-left x (clojure.core/short 2)))
 (g (bit-shift-right y (clojure.core/short 2)))
 (h (bit-not x))
 (i (bit-not y))
 (x (clojure.core/short 123))
 (y (clojure.core/short 456)))
{{</highlight>}} 

Which isn't in the correct order, but from the pieces I've already built I can
build the correct let binding forms. To make things easier I'm going to index
the expressions by their output wire.
{{<highlight clojure >}}
(defn index-program
  [program]
  (reduce (fn [mapping expr]
            (assoc mapping (:out (second expr)) expr))
          {}
          program))
{{</highlight>}}

{{<highlight clojure >}}
(defn let-bindings
  [program]
  (let [indexed (index-program program)]
    (into []
          (mapcat (comp compile-wire #(get indexed %)))
          (wire-order program))))
{{</highlight>}} 

#### Output Map
`let`, of course, has two parts: the binding form and the body of code that uses
those bindings. Previously I chose that the output would be a map. So here I
define a function that builds the output map.
{{<highlight clojure >}}
(defn output-map
  [program]
  (let [names (wire-names program)]
    (zipmap (map keyword names) names)))
{{</highlight>}} 

Finally from all these pieces I can compose them into a macro that does the 
full compilation.
{{<highlight clojure >}}
(defmacro wires
  [& wires]
  (let [program (spec/conform :wires/wires wires)
        bindings (let-bindings program)
        out (output-map program)]
    `(let ~bindings ~out)))
{{</highlight>}} 

Example macro expansion:
{{<highlight clojure >}}
(pprint/pprint
  (macroexpand-1 '(wires 
                    x AND y -> d
                    x OR y -> e
                    x LSHIFT 2 -> f
                    y RSHIFT 2 -> g
                    NOT x -> h
                    NOT y -> i
                    123 -> x
                    456 -> y)))
{{</highlight>}} 

{{<highlight clojure >}}
(clojure.core/let
  [y (clojure.core/short 456)
   g (bit-shift-right y (clojure.core/short 2))
   i (bit-not y)
   x (clojure.core/short 123)
   f (bit-shift-left x (clojure.core/short 2))
   d (bit-and x y)
   h (bit-not x)
   e (bit-or x y)]
  {:d d, :e e, :f f, :g g, :h h, :i i, :x x, :y y})
{{</highlight>}} 

Looks fantastic! Now I'm going to run a program!
{{<highlight clojure >}}
(wires 
  x AND y -> d
  x OR y -> e
  x LSHIFT 2 -> f
  y RSHIFT 2 -> g
  NOT x -> h
  NOT y -> i
  123 -> x
  456 -> y)
{{</highlight>}} 

{{<highlight clojure >}}
{:d 72, :e 507, :f 492, :g 114, :h -124, :i -457, :x 123, :y 456}
{{</highlight>}} 

## Summary
I used Clojure Spec to build a grammar for toy language. Then I wrote a macro
that took the conformed value of a program and compiled it into Clojure code.
I embedded this compiler into a macro.

While this language and program isn't very useful by itself I think its a decent
pattern for building complicated DSLs in Clojure. Of course all the trade offs
with making a DSL apply. I'd think hard about doing it but if this was a good
solution to the problem I was solving then this seems like a good pattern. 

In general I think Spec is a great tool for describing and conforming inputs
to macros.
