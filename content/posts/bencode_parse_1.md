---
title: "bencode Parsing Part 1"
date: 2019-05-29T21:28:49-06:00
draft: false
---


Recently I read about [bencode](https://en.wikipedia.org/wiki/Bencode) and 
decided to write a parser for it. I have a bit of experience (but not much) 
writing grammars for languages for parser generators but bencode has an 
interesting property that I'm not sure can be expressed in a formal language
grammar. That is the encoding for a string. A string is an array of bytes and
looks like this: 

{{<highlight sql>}}
<ascii encoded size of array>:<byte array>
{{</highlight>}}

The part I'm not sure how to express is the fact the number of bytes in the
string is determined by a previously parsed value. I'm not sure how to feed
that in using a grammar. So I decided to do something different and "hand roll"
a parser. I have two implementations. Below is an annotated version of the 
first.

The interface of this parser is that a function is called when a character is 
read and that function returns the next function that can be called when the
next character is read and so on. When a function returns a value parsing is 
done and that value is the result of the parse. Like so:

{{<highlight clojure>}}
(let [p0 (new-parser)
      p1 (p0 first-char)
      p2 (p1 second-char)
      p3 (p2 third-char)
      ...
      parsed-val (pn nth-char)]
  parsed-val)
{{</highlight>}}

I got the idea from wanting to read bencoded data from a Java `InputStream` one
byte at a time and having parser where I could just feed it one byte at a time.


### Constructor
Here is the constructor that returns a function ready to accept the first byte.
It just returns the next parser function based which type of thing is next 
indicated by input character `c`.

{{<highlight clojure>}}
(defn new-parser
  []
  (fn [c]
    (cond (= c \i) (int-parser)
          (= c \d) (dict-parser)
          (= c \l) (list-parser)
          (<= 0x30 c 0x39) (string-parser c)
          :else (throw (IllegalStateException. "Invalid bencode")))))
{{</highlight>}}


### Integer Parser
The easiest thing to parse is an integer. It's encoded in ASCII prefixed by an
`i` and suffixed by and `e`. The first parser consumes the `i` so the next
character is a digit. This parser keeps returning a function that keeps an
accumulator in a closure until an `e` is found. Then it takes all the bytes
in the accumulator buts them together into a string. Finally it takes that
string and turns it into the Java long that it represents.

{{<highlight clojure>}}
(defn int-parser
  ([] (int-parser []))
  ([acc]
   (fn [c]
     (if (= c \e)
        (Long/valueOf (apply str acc))
        (int-parser (conj acc c))))))
{{</highlight>}}


### String Parser
As mentioned earlier strings are formatted by first the ascii representation of
a integer indicating the number of bytes in the string then a ':' then that
indicated number of bytes. I broke parsing the length and the string into 
separate parsers. First the string parser delegates to the string length parser.

{{<highlight clojure>}}
(defn string-parser
  [c0]
  (string-len-parser [c0]))
{{</highlight>}}

Next is the string length parser works exactly the same as the `int-parser` 
except that it looks for a ':' to know when the integer is done instead of an 
'e' and then delegates to the string value parser to finish the string parsing.

{{<highlight clojure>}}
(defn string-len-parser
  [acc]
  (fn [c]
    (if (= c \:)
      (string-val-parser [] (Long/valueOf (apply str acc)))
      (string-len-parser (conj acc c)))))
{{</highlight>}}


Lastly the string value parser reads the string by counting down until the 
indicated number of characters have been consumed.

{{<highlight clojure>}}
(defn string-val-parser
  [acc i]
  (if (< 1 i)
    (string-val-parser (conj acc c) (dec i))
    (apply str (conj acc c))))
{{</highlight>}}


### List Parser


### Dict Parser
