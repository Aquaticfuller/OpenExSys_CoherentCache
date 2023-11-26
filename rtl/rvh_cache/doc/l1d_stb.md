# function
the store buffer should have following functions:
1. buffer store     : multiple stores may come into stb, th stb buffer them and send them to l1d bank at some timeout;
2. store merge      : when different st req hit the same cache line, stb shoul merge them into one cache line, set its write mask, and send them to l1d bank as one write req;
3. load bypass      : the st reqs in stb are commited, so it has latest data, when a load req comes, it has to search the stb for its data;
4. eviction         : when the eviction condition is met, e.g. stb full, load partical hit, the stb need to evict one or all stb entries to l1d bank;
5. coherence snoop  : snoop will search the stb, if there is a hit, it should wait for the stb entry evicted to the l1d bank and then start its coherence operation.

# load req (vipt)
| stage | l1d stb                                                                                                    | l1d bank                                                             |
| ----- | ---------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| s0    | as vipt, no physical tag at s0, do nothing                                                                 | read tag ram, data ram, lst                                          |
| s1    | get tlb resp, read/comapre line addr, the one which is evict hak at that cycle is taken as miss            | get tlb resp, compare tag, compare state, select data                |
| s2    | if full hit: resp data; if partial hit: ldq replay, force the stb entry go into l1d bank; if miss: no resp | if hit: resp data; if miss: alloc new mshr, if mshr full: ldq replay |
|       |                                                                                                            |                                                                      |

# stb store req (pipt) vs load req (vipt)
| stage | l1d stb store                                                                                                                                              | l1d stb load                                                                                               |
| ----- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| s0    | read/comapre line addr, if miss(the one which is evict hak at that cycle is taken as miss) & no empty stb entry(include the one in s1): lower ready signal | as vipt, no physical tag at s0, do nothing                                                                 |
| s1    | if hit: select the hit entry idx, merge and write; if miss: alloc new stb entry                                                                            | get tlb resp, read/comapre line addr                                                                       |
| s2    |                                                                                                                                                            | if full hit: resp data; if partial hit: ldq replay, force the stb entry go into l1d bank; if miss: no resp |

# stb evict (when stb full / stb entry timeout)
## when evict (with priority)
1. stb flush (evict all)
1. coherence snoop hit
2. load partial hit
3. stb full
4. stb entry timeout (optional)
## steps
* s0:
1. choose one stb entry to evict (by maintaining a fifo input is new stb entry idx, output is the entry to evict)
2. send out the req valid to l1d bank input arbiter
3. if handshake, invalid the stb entry