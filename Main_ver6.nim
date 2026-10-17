import std/[algorithm, sequtils, strutils, math, macros, sugar,
            tables, sets, deques, heapqueue, bitops, options]

static:
  doAssert sizeof(int) == 8, "Use a 64-bit Nim target."

const
  infInt = high(int) div 4
  mod998 = 998244353
  mod107 = 1000000007
  dir4 = [(1, 0), (-1, 0), (0, 1), (0, -1)]

type FastInput = object
  text: string
  pos: int

var cpInput: FastInput
var cpInputReady = false

proc setInput(text: string) =
  cpInput = FastInput(text: text, pos: 0)
  cpInputReady = true

proc cpSkipSpace() {.inline.} =
  if not cpInputReady:
    setInput(stdin.readAll())
  while cpInput.pos < cpInput.text.len and cpInput.text[cpInput.pos] <= ' ':
    inc cpInput.pos
  if cpInput.pos == cpInput.text.len:
    raise newException(EOFError, "No more input tokens")

proc readInt(): int {.inline.} =
  cpSkipSpace()
  var negative = false
  if cpInput.text[cpInput.pos] in {'-', '+'}:
    negative = cpInput.text[cpInput.pos] == '-'
    inc cpInput.pos
  let start = cpInput.pos
  let limit = uint(high(int)) + uint(ord(negative))
  var magnitude = 0'u
  while cpInput.pos < cpInput.text.len and cpInput.text[cpInput.pos] > ' ':
    let c = cpInput.text[cpInput.pos]
    if c < '0' or c > '9':
      raise newException(ValueError, "Invalid integer token")
    let digit = uint(ord(c) - ord('0'))
    if magnitude > limit div 10 or
       (magnitude == limit div 10 and digit > limit mod 10):
      raise newException(ValueError, "Integer is outside the int range")
    magnitude = magnitude * 10 + digit
    inc cpInput.pos
  if cpInput.pos == start:
    raise newException(ValueError, "An integer token needs digits")
  if negative:
    if magnitude == uint(high(int)) + 1'u:
      return low(int)
    return -int(magnitude)
  int(magnitude)

proc readWord(): string =
  cpSkipSpace()
  let start = cpInput.pos
  while cpInput.pos < cpInput.text.len and cpInput.text[cpInput.pos] > ' ':
    inc cpInput.pos
  cpInput.text[start..<cpInput.pos]

proc readFloat(): float64 = parseFloat(readWord())

proc readInts(n: int): seq[int] =
  if n < 0: raise newException(ValueError, "Negative input length")
  result = newSeq[int](n)
  for i in 0..<n: result[i] = readInt()

proc readWords(n: int): seq[string] =
  if n < 0: raise newException(ValueError, "Negative input length")
  result = newSeq[string](n)
  for i in 0..<n: result[i] = readWord()

proc readInt2(): tuple[a, b: int] =
  result.a = readInt()
  result.b = readInt()

proc readInt3(): tuple[a, b, c: int] =
  result.a = readInt()
  result.b = readInt()
  result.c = readInt()

proc readIntGrid(h, w: int): seq[seq[int]] =
  if h < 0 or w < 0: raise newException(ValueError, "Negative grid size")
  result = newSeq[seq[int]](h)
  for r in 0..<h: result[r] = readInts(w)

proc print(args: varargs[string, `$`]) =
  stdout.writeLine(args.join(" "))

proc printSeq[T](a: openArray[T]) =
  var line = ""
  for i, x in a:
    if i > 0: line.add(' ')
    line.add($x)
  stdout.writeLine(line)

proc printGrid[T](a: openArray[seq[T]]) =
  for row in a: printSeq(row)

proc yesNo(ok: bool, upper = false) =
  if upper: print(if ok: "YES" else: "NO")
  else: print(if ok: "Yes" else: "No")

proc chmin[T](target: var T, candidate: T): bool {.inline, discardable.} =
  if candidate < target:
    target = candidate
    return true
  false

proc chmax[T](target: var T, candidate: T): bool {.inline, discardable.} =
  if target < candidate:
    target = candidate
    return true
  false

template makeSeq(n: int, initial: untyped): untyped =
  block:
    let size = n
    if size < 0: raise newException(ValueError, "Negative sequence size")
    newSeqWith(size, initial)

template makeGrid(h, w: int, initial: untyped): untyped =
  block:
    let height = h
    let width = w
    if height < 0 or width < 0:
      raise newException(ValueError, "Negative grid size")
    newSeqWith(height, newSeqWith(width, initial))

proc sumAs[T, U](a: openArray[T], accumulatorType: typedesc[U]): U =
  result = U(0)
  for x in a: result += U(x)

proc prefixSum[T: SomeNumber](a: openArray[T]): seq[T] =
  result = newSeq[T](a.len + 1)
  for i, x in a: result[i + 1] = result[i] + x

proc prefixSumAs[T, U](a: openArray[T], accumulatorType: typedesc[U]): seq[U] =
  result = newSeq[U](a.len + 1)
  result[0] = U(0)
  for i, x in a: result[i + 1] = result[i] + U(x)

proc sortedUnique[T](a: openArray[T]): seq[T] =
  result = @a
  result.sort()
  var used = 0
  for i in 0..<result.len:
    if used == 0 or result[used - 1] != result[i]:
      result[used] = result[i]
      inc used
  result.setLen(used)

proc argsort[T](a: openArray[T]): seq[int] =
  let n = a.len
  result = newSeq[int](n)
  for i in 0..<n: result[i] = i
  var work = newSeq[int](n)
  var width = 1
  while width < n:
    var left = 0
    while left < n:
      let middle = left + min(width, n - left)
      let right = middle + min(width, n - middle)
      var i = left
      var j = middle
      var dest = left
      while i < middle and j < right:
        if a[result[j]] < a[result[i]]:
          work[dest] = result[j]
          inc j
        else:
          work[dest] = result[i]
          inc i
        inc dest
      while i < middle:
        work[dest] = result[i]
        inc i
        inc dest
      while j < right:
        work[dest] = result[j]
        inc j
        inc dest
      left = right
    swap(result, work)
    if width >= n - width: break
    width *= 2

proc rearrange[T](a: openArray[T], order: openArray[int]): seq[T] =
  result = newSeq[T](order.len)
  for i, p in order:
    if p < 0 or p >= a.len:
      raise newException(ValueError, "rearrange index out of range")
    result[i] = a[p]

proc compress[T](a: openArray[T]): tuple[values: seq[T], ranks: seq[int]] =
  result.values = sortedUnique(a)
  result.ranks = newSeq[int](a.len)
  for i, x in a: result.ranks[i] = result.values.lowerBound(x)

proc tally[T](a: openArray[T]): Table[T, int] =
  result = initTable[T, int]()
  for x in a: result[x] = result.getOrDefault(x) + 1

proc runLengths[T](a: openArray[T]): seq[tuple[value: T, count: int]] =
  for x in a:
    if result.len > 0 and result[^1].value == x:
      inc result[^1].count
    else:
      result.add((value: x, count: 1))

proc cpCheckDivisor(a, b: int) {.inline.} =
  if b == 0: raise newException(ValueError, "Division by zero")
  if a == low(int) and b == -1:
    raise newException(ValueError, "Quotient is outside the int range")

proc floorDiv(a, b: int): int =
  cpCheckDivisor(a, b)
  result = a div b
  let r = a mod b
  if r != 0 and ((r < 0) != (b < 0)): dec result

proc ceilDiv(a, b: int): int =
  cpCheckDivisor(a, b)
  result = a div b
  let r = a mod b
  if r != 0 and ((r < 0) == (b < 0)): inc result

proc floorMod(a, b: int): int =
  if b == 0: raise newException(ValueError, "Modulo by zero")
  if a == low(int) and b == -1: return 0
  result = a mod b
  if result != 0 and ((result < 0) != (b < 0)): result += b

proc cpBinding(spec: NimNode): tuple[index, domain: NimNode] {.compileTime.} =
  if spec.kind != nnkInfix or spec.len != 3 or
     not spec[0].eqIdent("in") or spec[1].kind != nnkIdent:
    error("Expected: k in 0..<n (a single integer index)", spec)
  (spec[1], spec[2])

proc cpScoreType(index, expression: NimNode): NimNode {.compileTime.} =
  let probe = quote do:
    block:
      var `index`: int
      `expression`
  result = newCall(bindSym"typeof", probe)

proc cpReduce(spec, expression, initial: NimNode, multiply: bool): NimNode {.compileTime.} =
  let (index, domain) = cpBinding(spec)
  let accumulator = genSym(nskVar, "accumulator")
  var seed = initial
  if seed.kind == nnkEmpty:
    let typ = cpScoreType(index, expression)
    seed = newCall(typ, newLit(if multiply: 1 else: 0))
  let update = newTree(nnkInfix, ident(if multiply: "*=" else: "+="),
                       accumulator, expression)
  result = quote do:
    block:
      var `accumulator` = `seed`
      for `index` in `domain`:
        `update`
      `accumulator`
  result.copyLineInfo(spec)

macro sigma(spec, expression: untyped): untyped =
  cpReduce(spec, expression, newEmptyNode(), false)
macro sigma(spec, expression, initial: untyped): untyped =
  cpReduce(spec, expression, initial, false)
macro product(spec, expression: untyped): untyped =
  cpReduce(spec, expression, newEmptyNode(), true)
macro product(spec, expression, initial: untyped): untyped =
  cpReduce(spec, expression, initial, true)

proc cpExtreme(spec, expression: NimNode, largest, argument: bool): NimNode {.compileTime.} =
  let (index, domain) = cpBinding(spec)
  let typ = cpScoreType(index, expression)
  let best = genSym(nskVar, "best")
  let bestIndex = genSym(nskVar, "bestIndex")
  let seen = genSym(nskVar, "seen")
  let candidate = genSym(nskLet, "candidate")
  let better = if largest:
    newTree(nnkInfix, ident"<", best, candidate)
  else:
    newTree(nnkInfix, ident"<", candidate, best)
  let returned = if argument: bestIndex else: best
  result = quote do:
    block:
      var `best`: `typ`
      var `bestIndex` = 0
      var `seen` = false
      for `index` in `domain`:
        let `candidate` = `expression`
        if not `seen` or `better`:
          `best` = `candidate`
          `bestIndex` = int(`index`)
          `seen` = true
      if not `seen`:
        raise newException(ValueError, "Extremum of an empty domain")
      `returned`
  result.copyLineInfo(spec)

macro minOf(spec, expression: untyped): untyped =
  cpExtreme(spec, expression, false, false)
macro maxOf(spec, expression: untyped): untyped =
  cpExtreme(spec, expression, true, false)
macro argmin(spec, expression: untyped): untyped =
  cpExtreme(spec, expression, false, true)
macro argmax(spec, expression: untyped): untyped =
  cpExtreme(spec, expression, true, true)

macro forall(spec, condition: untyped): untyped =
  let (index, domain) = cpBinding(spec)
  let answer = genSym(nskVar, "allAnswer")
  result = quote do:
    block:
      var `answer` = true
      for `index` in `domain`:
        if not (`condition`):
          `answer` = false
          break
      `answer`

macro exists(spec, condition: untyped): untyped =
  let (index, domain) = cpBinding(spec)
  let answer = genSym(nskVar, "anyAnswer")
  result = quote do:
    block:
      var `answer` = false
      for `index` in `domain`:
        if `condition`:
          `answer` = true
          break
      `answer`

macro countWhere(spec, condition: untyped): untyped =
  let (index, domain) = cpBinding(spec)
  let answer = genSym(nskVar, "countAnswer")
  result = quote do:
    block:
      var `answer` = 0
      for `index` in `domain`:
        if `condition`: inc `answer`
      `answer`
const debugLimit = 16

proc debugText[T](x: T): string = $x
proc debugText(x: string): string =
  let n = min(x.len, 160)
  result = escape(x[0..<n])
  if n < x.len: result.add("... (bytes=" & $x.len & ")")

proc debugText[T](a: seq[T]): string =
  mixin debugText
  result = "["
  for i in 0..<min(a.len, debugLimit):
    if i > 0: result.add(", ")
    result.add(debugText(a[i]))
  if a.len > debugLimit: result.add(", ...")
  result.add("] (len=" & $a.len & ")")

proc debugText[T](q: Deque[T]): string =
  mixin debugText
  result = "deque["
  var shown = 0
  for x in q.items:
    if shown == debugLimit: break
    if shown > 0: result.add(", ")
    result.add(debugText(x))
    inc shown
  if q.len > shown: result.add(", ...")
  result.add("] (len=" & $q.len & ")")

proc debugText[T](q: HeapQueue[T]): string =
  mixin debugText
  var copy = q
  result = "heap["
  for i in 0..<min(q.len, debugLimit):
    if i > 0: result.add(", ")
    result.add(debugText(copy.pop()))
  if copy.len > 0: result.add(", ...")
  result.add("] (len=" & $q.len & ")")

proc debugText[K, V](table: Table[K, V]): string =
  mixin debugText
  result = "{"
  var shown = 0
  for key, value in table.pairs:
    if shown == debugLimit: break
    if shown > 0: result.add(", ")
    result.add(debugText(key) & ": " & debugText(value))
    inc shown
  if table.len > shown: result.add(", ...")
  result.add("} (len=" & $table.len & ")")

proc debugText[T](s: HashSet[T]): string =
  mixin debugText
  result = "set{"
  var shown = 0
  for x in s.items:
    if shown == debugLimit: break
    if shown > 0: result.add(", ")
    result.add(debugText(x))
    inc shown
  if s.len > shown: result.add(", ...")
  result.add("} (len=" & $s.len & ")")

macro dbg(args: varargs[untyped]): untyped =
  var statements = newStmtList()
  for arg in args:
    let label = newLit(arg.repr & " = ")
    statements.add quote do:
      stderr.writeLine(`label` & debugText(`arg`))
  result = quote do:
    when defined(LOCAL):
      block:
        `statements`

proc cpShowGrid[T](a: seq[seq[T]], rows, cols: int) =
  mixin debugText
  for r in 0..<min(a.len, max(rows, 0)):
    var line = $r & ":"
    for c in 0..<min(a[r].len, max(cols, 0)):
      line.add(" " & debugText(a[r][c]))
    if a[r].len > cols: line.add(" ...")
    stderr.writeLine(line)
  if a.len > rows: stderr.writeLine("... (rows=" & $a.len & ")")

template dbgGrid(a: untyped, rows: int = 8, cols: int = 12) =
  when defined(LOCAL):
    cpShowGrid(a, rows, cols)
type UnionFind = object
  parentOrSize: seq[int]
  count: int

proc initUnionFind(n: int): UnionFind =
  if n < 0: raise newException(ValueError, "Negative DSU size")
  result.parentOrSize = newSeqWith(n, -1)
  result.count = n

proc leader(uf: var UnionFind, v: int): int =
  if v < 0 or v >= uf.parentOrSize.len:
    raise newException(ValueError, "DSU vertex out of range")
  result = v
  while uf.parentOrSize[result] >= 0: result = uf.parentOrSize[result]
  var current = v
  while current != result:
    let next = uf.parentOrSize[current]
    uf.parentOrSize[current] = result
    current = next

proc same(uf: var UnionFind, a, b: int): bool = uf.leader(a) == uf.leader(b)
proc groupSize(uf: var UnionFind, v: int): int = -uf.parentOrSize[uf.leader(v)]
proc groupCount(uf: UnionFind): int = uf.count

proc unite(uf: var UnionFind, a, b: int): bool {.discardable.} =
  var x = uf.leader(a)
  var y = uf.leader(b)
  if x == y: return false
  if uf.parentOrSize[x] > uf.parentOrSize[y]: swap(x, y)
  uf.parentOrSize[x] += uf.parentOrSize[y]
  uf.parentOrSize[y] = x
  dec uf.count
  true

type Fenwick[T] = object
  data: seq[T]

proc initFenwick[T: SomeNumber](n: int): Fenwick[T] =
  if n < 0: raise newException(ValueError, "Negative Fenwick size")
  result.data = newSeq[T](n + 1)

proc initFenwick[T: SomeNumber](a: openArray[T]): Fenwick[T] =
  result = initFenwick[T](a.len)
  for i, x in a:
    let index = i + 1
    result.data[index] += x
    let parent = index + (index and -index)
    if parent <= a.len: result.data[parent] += result.data[index]

proc add[T: SomeNumber](bit: var Fenwick[T], index: int, delta: T) =
  if index < 0 or index >= bit.data.len - 1:
    raise newException(ValueError, "Fenwick index out of range")
  var i = index + 1
  while i < bit.data.len:
    bit.data[i] += delta
    i += i and -i

proc prefix[T: SomeNumber](bit: Fenwick[T], right: int): T =
  if right < 0 or right >= bit.data.len:
    raise newException(ValueError, "Fenwick boundary out of range")
  var i = right
  while i > 0:
    result += bit.data[i]
    i -= i and -i

proc rangeSum[T: SomeNumber](bit: Fenwick[T], left, right: int): T =
  if left < 0 or left > right or right >= bit.data.len:
    raise newException(ValueError, "Invalid Fenwick interval")
  bit.prefix(right) - bit.prefix(left)
type
  Graph = seq[seq[int]]
  WeightedEdge = tuple[to, cost: int]
  WeightedGraph = seq[seq[WeightedEdge]]

proc readGraph(n, m: int, directed = false, oneBased = true): Graph =
  if n < 0 or m < 0: raise newException(ValueError, "Negative graph size")
  result = newSeq[seq[int]](n)
  for i in 0..<m:
    var (u, v) = readInt2()
    if oneBased:
      dec u
      dec v
    if u < 0 or u >= n or v < 0 or v >= n:
      raise newException(ValueError, "Graph vertex out of range")
    result[u].add(v)
    if not directed: result[v].add(u)

proc readWeightedGraph(n, m: int, directed = false, oneBased = true): WeightedGraph =
  if n < 0 or m < 0: raise newException(ValueError, "Negative graph size")
  result = newSeq[seq[WeightedEdge]](n)
  for i in 0..<m:
    var (u, v, cost) = readInt3()
    if oneBased:
      dec u
      dec v
    if u < 0 or u >= n or v < 0 or v >= n:
      raise newException(ValueError, "Graph vertex out of range")
    result[u].add((to: v, cost: cost))
    if not directed: result[v].add((to: u, cost: cost))

proc bfs(g: Graph, start: int): seq[int] =
  if start < 0 or start >= g.len: raise newException(ValueError, "Invalid start")
  result = newSeqWith(g.len, -1)
  result[start] = 0
  var queue = @[start]
  var head = 0
  while head < queue.len:
    let v = queue[head]
    inc head
    for to in g[v]:
      if result[to] >= 0: continue
      result[to] = result[v] + 1
      queue.add(to)

proc dijkstra(g: WeightedGraph, start: int): seq[int] =
  if start < 0 or start >= g.len: raise newException(ValueError, "Invalid start")
  when defined(LOCAL):
    for edges in g:
      for edge in edges:
        doAssert edge.to >= 0 and edge.to < g.len
        doAssert edge.cost >= 0, "Dijkstra requires nonnegative costs"
  result = newSeqWith(g.len, infInt)
  result[start] = 0
  var queue = initHeapQueue[tuple[distance, vertex: int]]()
  queue.push((distance: 0, vertex: start))
  while queue.len > 0:
    let (distance, vertex) = queue.pop()
    if distance != result[vertex]: continue
    for edge in g[vertex]:
      if edge.cost >= infInt - distance: continue
      let next = distance + edge.cost
      if chmin(result[edge.to], next):
        queue.push((distance: next, vertex: edge.to))

proc topologicalOrder(g: Graph): Option[seq[int]] =
  var degree = newSeq[int](g.len)
  for edges in g:
    for to in edges: inc degree[to]
  var order: seq[int] = @[]
  for v in 0..<g.len:
    if degree[v] == 0: order.add(v)
  var head = 0
  while head < order.len:
    let v = order[head]
    inc head
    for to in g[v]:
      dec degree[to]
      if degree[to] == 0: order.add(to)
  if order.len == g.len: some(order)
  else: none(seq[int])
proc powMod(base, exponent, modulus: int): int =
  if exponent < 0 or modulus < 1 or modulus > 3_037_000_499:
    raise newException(ValueError, "powMod: exponent >= 0, 1 <= mod <= 3037000499")
  var x = floorMod(base, modulus)
  var e = exponent
  result = 1 mod modulus
  while e > 0:
    if (e and 1) != 0: result = result * x mod modulus
    e = e shr 1
    if e > 0: x = x * x mod modulus

proc divisors(n: int): seq[int] =
  if n <= 0: raise newException(ValueError, "divisors requires n > 0")
  var large: seq[int] = @[]
  var d = 1
  while d <= n div d:
    if n mod d == 0:
      result.add(d)
      if d != n div d: large.add(n div d)
    inc d
  large.reverse()
  result.add(large)

proc primeFactors(n: int): seq[tuple[prime, exponent: int]] =
  if n < 1: raise newException(ValueError, "primeFactors requires n >= 1")
  var remaining = n
  var d = 2
  while d <= remaining div d:
    if remaining mod d == 0:
      var count = 0
      while remaining mod d == 0:
        remaining = remaining div d
        inc count
      result.add((prime: d, exponent: count))
    if d == 2: d = 3
    else: d += 2
  if remaining > 1: result.add((prime: remaining, exponent: 1))

proc primeTable(n: int): seq[bool] =
  if n < 0: raise newException(ValueError, "Negative sieve limit")
  result = newSeqWith(n + 1, true)
  result[0] = false
  if n >= 1: result[1] = false
  var p = 2
  while p <= n div p:
    if result[p]:
      var x = p * p
      while x <= n:
        result[x] = false
        if p > n - x: break
        x += p
    inc p


proc solve() =
  discard

when isMainModule:
  solve()
