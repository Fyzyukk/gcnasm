# vmcnt_relax on clang 23 -- positive, and wrong

`build23.sh` rebuilds the section-28 relaxations with clang 23, where (unlike
clang 20) they actually change the ISA: 5 of 7 `vmcnt(0)` become `vmcnt(N)`.

`RELAX=1` reads +0.26%, 5/5 wins, and is clean at 8192^3.  It is still a race:
it fails at 8192x4096x16384 (1414 errors) where the retained build is clean.
The variant's safety argument only holds for the A0_THREE_SLOT structure, which
issues a newer request to occupy the freed slots; the retained config issues
nothing after the wait.  `RELAX=2` fails outright at 8192^3.

Closed on correctness.  Lesson: a single-shape 0-error run plus 5/5 wins is not
evidence -- relaxing synchronization must be swept over shapes, especially K.
