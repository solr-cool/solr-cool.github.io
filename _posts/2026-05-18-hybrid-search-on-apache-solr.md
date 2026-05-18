---
layout: post
title: Hybrid Search Architecture for Apache Solr 10 and beyond
title_html: 'Hybrid Search Architecture<br />for <span class="hl">Apache&nbsp;Solr&nbsp;10</span> and <span class="ul">beyond</span>'
lede: 'Lexical search plus vectors, fused with RRF, optionally reranked. The question is no longer <em>whether</em> an engine can do this &mdash; it&rsquo;s <em>how mature, how operationally expensive, how scalable</em>. A working assessment for teams sitting on Apache Solr.'
description: "An honest 2026 assessment of open-source hybrid-search options on top of Apache Solr — Solr 10, OpenSearch, Elasticsearch, Vespa, Qdrant/Weaviate — and the layered architecture that keeps the engine replaceable."
published: 2026-05-18
updated: 2026-05-18
reading_time: "~26&nbsp;min"
tags_display:
  - { text: "hybrid-search",      style: "tag--red tag--rot1" }
  - { text: "apache-solr-10",     style: "tag--ink tag--rot2" }
  - { text: "opensearch",         style: "tag--yellow tag--rot3" }
  - { text: "semantic-search",    style: "tag--rot1" }
  - { text: "solr-cloud",         style: "tag--rot2" }
  - { text: "agentic-retrieval",  style: "tag--red tag--rot3" }
  - { text: "colbert",            style: "tag--rot1" }
  - { text: "rag",                style: "tag--rot2" }
toc:
  - { id: starting-point, label: "Starting Point" }
  - { id: candidates,     label: "The Candidates in Detail" }
  - { id: matrix,         label: "Evaluation Matrix" }
  - { id: serp,           label: "Where the SERP Is Heading" }
  - { id: recommendation, label: "Recommendation" }
  - { id: readers-map,    label: "A Reader&rsquo;s Map" }
  - { id: api-stack,      label: "A Resilient API Stack" }
  - { id: agentic,        label: "The Agentic Alternative" }
  - { id: latency,        label: "Latency &amp; Paying for the Loop" }
  - { id: layers,         label: "Layer 1 &rarr; 6" }
  - { id: filters,        label: "Filters and Facets" }
  - { id: autosuggest,    label: "Autosuggest" }
  - { id: indexing,       label: "The Indexing Path" }
  - { id: together,       label: "Putting It Together" }
  - { id: sources,        label: "Sources" }
---

## Starting Point  {#starting-point}

"Hybrid search" today almost always means: lexical search (BM25) **plus** vector search (dense embeddings, optionally sparse like SPLADE), merged via Reciprocal Rank Fusion (RRF) or weighted linear combination, often with a downstream reranker (cross-encoder, ColBERT). The question is no longer *whether* an engine can do this — it's *how mature*, *how operationally expensive*, and *how scalable*.

Equally important is the forward-looking perspective: the most transformative innovations of the coming years are happening not in the index, but in the layers *above* it — LLM query rewriting, agentic retrieval planning, cross-encoder and LLM reranking, generative answer synthesis, multimodal search, late-interaction models like ColPali for visually rich documents. This matters for engine choice because some of these trends are engine-neutral and some are not.

The serious open-source candidates fall into three categories:

1. **Lucene-based search platforms:** Solr, OpenSearch, Elasticsearch
2. **AI-native search engine:** Vespa
3. **Vector-first databases with BM25:** Qdrant, Weaviate, Milvus

The evaluation of these categories runs through the following functional areas, which together in modern search systems make the difference between "works" and "competitive":

1. **Full-text and hybrid search** — BM25, dense vectors, sparse models, fusion (RRF), cross-encoder and LLM reranking
2. **Filters and selections** — structured, deterministic constraints on the result set; in the hybrid path implemented as pre-filter to the KNN search
3. **Facets and aggregations** — counted refinements on the current result set, hierarchical or pivot, distinct from OLAP-style aggregations
4. **Autosuggest / search-as-you-type** — its own path with its own index, latency class (P99 &lt; 50&nbsp;ms), and ranking logic
5. **Ranking and personalization** — from static boosts through learning-to-rank to real-time multi-phase ranking with user features
6. **Generative SERP layer** — RAG answers, agentic query plans, multimodal and late-interaction retrieval, dynamic result composition

> The most honest answer to **"which engine ages best"**: the one you hard-wire the **least**.
{:.epigraph}

## The Candidates in Detail  {#candidates}

### Apache Solr 10 <small style="font-weight:400;font-size:16px;color:var(--ink-soft)">(available since early&nbsp;2026)</small>

Solr 10 is no longer the "old classic that can barely do vectors." The release brings substantial improvements: scalar and binary quantization of dense vectors, optional GPU acceleration via cuVS-Lucene as a pluggable codec, new `efSearch` parameters for HNSW tuning, feature-vector caching for learning-to-rank, and with `SeededKnnVectorQuery` and `PatienceKnnVectorQuery` (early termination) two specific hybrid accelerators. Hybrid retrieval constructions (`{!bool should=$lex should=$knn}`) and hybrid ranking work — though they are still underdocumented in the reference guide (SOLR-17103). The `TextToVectorQParser` allows the query to be encoded directly within Solr.

<div class="table-wrap">
  <table>
    <thead><tr><th>Pros</th><th>Cons</th></tr></thead>
    <tbody><tr>
      <td>No migration needed &mdash; schema and ops knowledge stay. Genuine ASF governance, no corporate overlord, Apache&nbsp;2.0. Very strong faceted search, geo, parallel SQL &mdash; if relevant. Learning-to-rank is mature and has been able to use vector similarity as a feature since 9.3.</td>
      <td>Hybrid DX is raw &mdash; a lot of manual XML/JSON, pagination with BoolQParser&nbsp;+&nbsp;KNN is tricky, RRF not out of the box (actively being worked on). External ZooKeeper dependency for SolrCloud. Java&nbsp;21 as minimum (operational implication). Community smaller and shrinking relative to Elastic/OpenSearch. Multi-vector / late-interaction fields (ColBERT/ColPali) are not yet first-class in Lucene &mdash; the most relevant future weakness.</td>
    </tr></tbody>
  </table>
</div>

### OpenSearch (3.x)

Apache 2.0, Linux Foundation governance since 2024, Lucene-based. Version 3.2 explicitly expanded "agentic AI" and native hybrid search, supports FAISS and nmslib engines alongside Lucene HNSW, vector dimensions up to 16k. RRF and score normalization are built in as pipeline processors.

<div class="table-wrap">
  <table>
    <thead><tr><th>Pros</th><th>Cons</th></tr></thead>
    <tbody><tr>
      <td>Truly open source. Security (RBAC, FLS/DLS, audit) is in the free distribution &mdash; with Elastic this costs Platinum/Enterprise. Very active push toward AI features. Large ecosystem, Kibana-equivalent dashboards. AWS integration if desired.</td>
      <td>Performance benchmarks show it lags 40&ndash;140% behind Elasticsearch (vendor benchmarks, read with caution). Operational complexity similar to Elasticsearch. A migration from Solr is a real migration: schema, query language, tooling, configuration. Multi-vector late-interaction shares the Lucene weakness with Solr.</td>
    </tr></tbody>
  </table>
</div>

### Elasticsearch (8.x / 9.x)

License is OSI-compliant again since 2024 via AGPLv3 option (alongside SSPL and the Elastic License). Mature hybrid search with RRF, ELSER (Elastic's own sparse model for out-of-domain semantics), built-in reranking API.

<div class="table-wrap">
  <table>
    <thead><tr><th>Pros</th><th>Cons</th></tr></thead>
    <tbody><tr>
      <td>Probably the most polished hybrid search experience in the Lucene family, excellent documentation, mature ML pipelines, Kibana. Strongest DX for hybrid out of the box.</td>
      <td>The licensing nightmare isn&rsquo;t fully over &mdash; AGPLv3 is OSI-compliant but tricky for many enterprise contexts. Many premium features (ML, security tier, RAG API) remain gated. TCO at larger cluster sizes is relevant. If the customer is trying to move <em>away</em> from commercial pressure, this is the wrong signal.</td>
    </tr></tbody>
  </table>
</div>

### Vespa

Formerly Yahoo, open source under Apache&nbsp;2.0 since 2017. Unlike the Lucene family, a vector-native architecture: mutable in-memory data structures (no refresh interval), multi-phase ranking on content nodes (not scatter-gather), ONNX/LightGBM executable locally.

<div class="table-wrap">
  <table>
    <thead><tr><th>Pros</th><th>Cons</th></tr></thead>
    <tbody><tr>
      <td>Clear performance king for hybrid at scale &mdash; vendor benchmarks claim 8.5&times; higher hybrid throughput per core compared to Elasticsearch, 12.9&times; for pure vector. True real-time visibility. First-class tensor and ranking expressiveness, ColBERT/late-interaction native. The only engine that does <em>retrieval and complex ranking in a single query round trip</em>. Exactly the architecture that supports real-time personalization and multi-phase ranking.</td>
      <td>The steepest learning curve in this list &mdash; its own configuration language, its own query language (YQL), its own mental model. Smaller community, fewer Stack Overflow answers. Operationally demanding for self-hosting; Vespa Cloud is the pragmatic alternative. Overkill if data volume is "medium" and latency isn&rsquo;t critical in single-digit ms.</td>
    </tr></tbody>
  </table>
</div>

### Qdrant / Weaviate / Milvus <small style="font-weight:400;font-size:16px;color:var(--ink-soft)">(Vector-first with BM25)</small>

Qdrant (Rust, Apache&nbsp;2.0), Weaviate (Go, BSD-3), Milvus (Go/C++, Apache&nbsp;2.0) are primarily vector DBs but by now all ship usable BM25 + hybrid fusion (RRF, DBSF, alpha-blending). Qdrant integrates IDF calculation into the engine, Weaviate has the `with_hybrid(alpha=...)` API. ColBERT / ColPali support is first-class here — so they're strongest precisely where the Lucene family is weakest.

<div class="table-wrap">
  <table>
    <thead><tr><th>Pros</th><th>Cons</th></tr></thead>
    <tbody><tr>
      <td>Best DX for vector + hybrid when starting greenfield. Quick to set up, clear APIs, small footprints. Reranking hooks (ColBERT, cross-encoder) are first-class. Multimodal workflows (CLIP, SigLIP, ColPali for PDFs/images) come with less friction than the Lucene engines.</td>
      <td>Weaker on the "classical" lexical side &mdash; tokenizers, analyzers, synonyms, fuzzy matching, phrase slop, highlighting, faceted search, spell-check are not at Lucene level. If you&rsquo;re running Solr in production today, you almost certainly use features that are missing here or would have to be built. Better suited as a RAG backend than as a universal site/product search.</td>
    </tr></tbody>
  </table>
</div>

### Candidate Evaluation Matrix  {#matrix}

<div class="table-wrap">
  <table>
    <thead><tr>
      <th>Criterion</th><th>Solr&nbsp;10</th><th>OpenSearch</th><th>Elasticsearch</th><th>Vespa</th><th>Qdrant / Weaviate</th>
    </tr></thead>
    <tbody>
      <tr><td>License (clean OSS)</td><td><span class="ok">✔</span> Apache 2.0</td><td><span class="ok">✔</span> Apache 2.0</td><td><span class="warn">⚠</span> AGPLv3 / SSPL</td><td><span class="ok">✔</span> Apache 2.0</td><td><span class="ok">✔</span> Apache 2.0 / BSD</td></tr>
      <tr><td>Hybrid search DX</td><td><span class="warn">⚠</span> raw</td><td><span class="ok">✔</span> good</td><td><span class="ok">✔</span> very good</td><td><span class="ok">✔</span> excellent</td><td><span class="ok">✔</span> excellent</td></tr>
      <tr><td>Lexical depth</td><td><span class="ok">✔</span> excellent</td><td><span class="ok">✔</span> excellent</td><td><span class="ok">✔</span> excellent</td><td><span class="ok">✔</span> very good</td><td><span class="warn">⚠</span> basic</td></tr>
      <tr><td>Faceting / aggregations</td><td><span class="ok">✔</span> excellent</td><td><span class="ok">✔</span> excellent</td><td><span class="ok">✔</span> excellent</td><td><span class="ok">✔</span> very good</td><td><span class="warn">⚠</span> weak</td></tr>
      <tr><td>Autosuggest (e-comm level)</td><td><span class="warn">⚠</span> building blocks</td><td><span class="warn">⚠</span> building blocks</td><td><span class="ok">✔</span> search_as_you_type + LTR</td><td><span class="ok">✔</span> reference</td><td><span class="warn">⚠</span> basic</td></tr>
      <tr><td>Vector performance</td><td><span class="ok">✔</span> good (with 10)</td><td><span class="ok">✔</span> good</td><td><span class="ok">✔</span> good</td><td><span class="ok">✔</span> top tier</td><td><span class="ok">✔</span> very good</td></tr>
      <tr><td>Late interaction (ColBERT/ColPali)</td><td><span class="warn">⚠</span> weak</td><td><span class="warn">⚠</span> weak</td><td><span class="warn">⚠</span> in progress</td><td><span class="ok">✔</span> native</td><td><span class="ok">✔</span> first-class</td></tr>
      <tr><td>Ranking flexibility</td><td><span class="ok">✔</span> LTR mature</td><td><span class="ok">✔</span> good</td><td><span class="ok">✔</span> ML stack</td><td><span class="ok">✔</span> multi-phase</td><td><span class="warn">⚠</span> rerank hook</td></tr>
      <tr><td>Operational maturity</td><td><span class="ok">✔</span> high</td><td><span class="ok">✔</span> high</td><td><span class="ok">✔</span> high</td><td><span class="warn">⚠</span> steep</td><td><span class="ok">✔</span> simple</td></tr>
      <tr><td>Migration cost (from current)</td><td><span class="ok">✔</span> none</td><td><span class="bad">✘</span> large</td><td><span class="bad">✘</span> large</td><td><span class="bad">✘</span> very large</td><td><span class="bad">✘</span> large</td></tr>
      <tr><td>Community momentum</td><td><span class="warn">⚠</span> stable</td><td><span class="ok">✔</span> growing</td><td><span class="ok">✔</span> large</td><td><span class="warn">⚠</span> niche</td><td><span class="ok">✔</span> growing</td></tr>
    </tbody>
  </table>
</div>

## Where Is the SERP Heading — and What Does That Mean for Engine Choice?  {#serp}

Before deciding, it's worth looking at the direction of innovation. Six trends I see as defining for the next 2–4&nbsp;years:

- **Late-interaction models migrate from reranker to retrieval layer.** ColBERT was the start; ColPali/ColQwen are the natural continuation — multi-vector representations per document, MaxSim matching, no OCR pipeline drama with PDFs or images. Vespa, Qdrant and Weaviate support this in production today; Lucene-based engines have a harder time structurally because the index has historically been single-vector-centric.
- **LLM and cross-encoder rerankers become standard stage&nbsp;2.** The math is uncontested: hybrid retrieval on top-100, then a cross-encoder or LLM reranker on top-10. Voyage, Cohere, Jina, FlashRank, ColBERT-v2 are the building blocks. Engine-neutral, runs externally.
- **Generative answers and "generative UI" on the SERP.** The display becomes dynamic: comparison table when the query looks like one; map when geo; carousel when products; pure answer when FAQ-like. The engine doesn't decide this; the layer above does.
- **Agentic search and multi-step query plans.** An LLM decomposes the user question into sub-queries, calls retrieval as a tool, checks the results, refines, asks back. MCP is becoming the standard interface here.
- **Real-time personalization in the ranking stage.** Multi-phase ranking where user context, session, embedding similarity to past behavior, and business logic come together. Native in Vespa, via LTR in Lucene-based engines.
- **Multimodality as default.** Image-to-text, text-to-image, mixed queries. CLIP, SigLIP, ColPali are the tools — for visually rich sites a realistic use case in 2–3&nbsp;years.

**What's engine-relevant, what isn't?** Cross-encoder reranking, generative answers, and agentic orchestration live almost entirely *above* the engine. Late interaction, real-time multi-phase ranking, and (with caveats) multimodality are the trends where index architecture genuinely makes a difference. That's where the Lucene family has structural work to do, while Vespa and the vector-first DBs are already ahead.

### Recommendation  {#recommendation}

**If the customer were starting greenfield** — without the existing Solr investment — and the profile is "classical search engine with hybrid extension, medium-to-large data volume, no megascale RAG," I would recommend **OpenSearch**. The hybrid DX is mature, RRF and score normalization are built in, the license is clean, security features are included at no extra cost, and the ecosystem is large enough that for most problems someone has already posted a solution.

**However:** The customer is *not* starting greenfield — they're facing the Solr&nbsp;9-to-10 upgrade. And here the recommendation flips: **Solr&nbsp;10 is sufficient in the overwhelming majority of cases for hybrid search**, and migration cost to OpenSearch would be substantial (schema modeling, query language, indexing pipeline, ops, monitoring, team skills). Solr&nbsp;10 closes the exact gaps that 9.x still had — with quantization, GPU codec, SeededKnn and PatienceKnn termination.

**Looking ahead reinforces this recommendation — with one important caveat.** The truly innovative layers of the SERP for the next several years (generative answers, agentic orchestration, query rewriting, LLM reranking) are engine-neutral and live in the application layer. Anyone thinking "I'll buy engine&nbsp;X and that gets me AI search" is wrong — regardless of which engine. Only three trends are genuinely engine-architecture-relevant: late interaction (ColBERT/ColPali), real-time multi-phase ranking, native multimodality.

**Concretely as a two-stage approach:**

1. **Now:** Run the upgrade to Solr&nbsp;10. As part of it, build a hybrid retrieval setup as a PoC — DenseVectorField, an embedding model (e.g., multilingual-e5 or bge-m3), `{!bool should=$lex should=$knn}` with RRF in the application layer, optionally a cross-encoder reranker as a second stage. Within a few weeks you'll know whether the relevance gain justifies the complexity.
2. **If the PoC hits limits** — missing multi-phase ranking on large data sets, need for native late interaction for visual documents, real-time personalization requirements — then the question is *where to migrate*, and the answer depends on the specific bottleneck (Vespa for ranking power and real-time, Qdrant/Weaviate for RAG/multimodal use cases, OpenSearch for broader platform).

> **Upgrade to Solr&nbsp;10.** Add hybrid. Build it so the engine stays replaceable.
{:.is-red}

The worst move would be to migrate off working Solr without a concrete pain point to justify the bill. Every serious engine in 2026 does hybrid search — the real differentiator isn't "can it?" but ranking quality, embedding choice, reranking strategy, and the evaluation loop. That work is engine-independent. And it's what will actually shape the SERP of the next few years.

## What Follows — A Reader's Map  {#readers-map}

The recommendation above is the *what*. The remainder covers the *how* — the architecture and the disciplines that turn the recommendation into a working system, built so that today's deterministic stack can host tomorrow's agent without a rewrite.

<div class="reader-map">
  <h4>Reader&rsquo;s Map</h4>
  <ul>
    <li><strong>A Resilient API Stack</strong> &mdash; the layered architecture from client to engine, the contract that keeps the engine replaceable, contrasted with the agentic alternative.</li>
    <li><strong>Filters and Facets</strong> &mdash; the second, non-relevance path through the same stack; why pure filter queries should skip half the pipeline.</li>
    <li><strong>Autosuggest</strong> &mdash; its own subsystem, different latency class, different signals, different pool.</li>
    <li><strong>The Indexing Path</strong> &mdash; embeddings, evaluation, the cross-cutting disciplines that decide whether the system improves over time.</li>
    <li><strong>Putting It Together</strong> &mdash; the synthesis, and the one rule that decides whether the engine stays replaceable.</li>
  </ul>
</div>

## A Resilient API Stack — Architecture Hygiene in Concrete Terms  {#api-stack}

There are two ways to design a search API today, and a system built well can support both. The first is the *deterministic pipeline* — query understanding, retrieval, fusion, reranking, composition — laid out as imperative code that runs the same plan every time. The second is the *agentic orchestration* — a model that owns the plan, calls the engine as a tool, evaluates results, and iterates. The deterministic version is what every search team has been building for two decades; the agentic version is what teams are starting to ship in production.

<pre>Query path (synchronous)                   Indexing path (async)
────────────────────────                   ─────────────────────

┌──────────────────────────────┐           ┌──────────────────────────┐
│ Client (Web, App, Agent,MCP) │           │   Source systems / CMS   │
│   speaks stable Domain API   │           │      CDC or Webhook      │
└──────────────┬───────────────┘           └────────────┬─────────────┘
               │                                        │
               ▼                                        ▼
┌──────────────────────────────┐           ┌──────────────────────────┐
│   Search BFF / Domain API    │           │    Indexing pipeline     │
│ /search /suggest /facets …   │           │  Normalize Enrich Chunk  │
│       engine-agnostic        │           └────────────┬─────────────┘
└──────────────┬───────────────┘                        │
               │                                        ▼
               ▼                              ┌──────────────────────────┐
┌──────────────────────────────┐              │    Embedding service     │
│      Query understanding     │◀─────────────│   versioned models,      │
│ Rewrite Expansion Intent     │              │       dual-write         │
│         Sub-queries          │              └────────────┬─────────────┘
└──────────────┬───────────────┘                           │
               │                                           │
               ▼                                           │ Bulk index
┌──────────────────────────────┐                           │
│    Retrieval orchestrator    │                           │
│ Plan Fan-out Fusion(RRF)     │                           │
│            Top-K             │                           │
└──────────────┬───────────────┘                           │
               │                                           │
               ▼                                           │
┌──────────────────────────────┐                           │
│        Engine adapter        │                           │
│  translates Query-IR to engine                           │
└──────────────┬───────────────┘                           │
               │                                           │
               ▼                                           ▼
┌──────────────────────────────────────────────────────────────────────┐
│                            Search engine                             │
│              Solr / OpenSearch / Vespa / Qdrant                      │
└──────────────┬───────────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────┐           ┌──────────────────────────┐
│       Reranking stage        │           │  Eval & experimentation  │
│  Cross-encoder ColBERT LLM   │◀──────────│ Goldset A/B online metr. │
└──────────────┬───────────────┘           └────────────┬─────────────┘
               │                                        │
               ▼                                        │
┌──────────────────────────────┐                        │
│      Result composition      │                        │
│ Hits Facets Highlights       │                        │
│         RAG answer           │                        │
└──────────────┬───────────────┘                        │
               │                                        │
               ▼                                        │
┌──────────────────────────────┐                        │
│    Telemetry & click logs    │◀───────────────────────┘
│ structured, linked to Query-IR
└──────────────────────────────┘</pre>

### The Agentic Alternative — Thin Primitives, an Orchestrating Agent  {#agentic}

The deterministic-pipeline assumption is exactly what the next few years will challenge most directly. Doug Turnbull made the case sharply in [a recent post](https://softwaredoug.com/blog/2026/05/11/the-new-agentic-search-models){:target="_blank" rel="noopener"}: the "thick search monolith" is being unbundled. In its place: a small set of *thin retrieval primitives* (basic keyword search, basic embedding search, a few filters), orchestrated by an agent that sees the whole problem rather than executing reductive steps.

Frontier models like GPT-5 and Sonnet already do the 80% case well — they understand most queries with general knowledge, and they can drive a retrieval tool reasonably. But Doug's central point is about the last 20%: the domain knowledge that *isn't* in a frontier model's training. A furniture store knows that "bistro tables" means small outdoor tables, not restaurant equipment; GPT-5 doesn't. Specialized agentic search models — SID-1, Glean's Waldo, startups like Charcoal — get trained on the domain and on search-as-task specifically.

#### What the agentic shift changes in the layers

- **The Retrieval Orchestrator becomes the agent's seat.** An LLM occupies this layer and runs a loop: call the engine, evaluate the result, decide whether to refine, filter, expand, or retry. No longer imperative code; a model with tools.
- **The engine adapter becomes hot.** A deterministic pipeline calls the engine once or twice per user query. An agentic orchestrator may call it five or ten times in a loop. The adapter must be idempotent, fast, safe to call repeatedly, with clear failure modes the agent can interpret.
- **The reranker may shrink.** When the agent itself selects across iterations — keeping promising candidates, dropping bad ones — it *is* reranking, spread across the loop. A dedicated Cross-Encoder stage may still earn its place for raw quality, but it stops being mandatory.

#### What the agentic shift doesn't change

What survives unchanged is the discipline: a stable domain API at the boundary, engine-agnostic hit schemas, an evaluation loop, versioned embeddings, a dedicated suggest path. The agent has to talk to *something*, and that something is the layered stack.

> **Design the engine adapter as a tool, not a remote procedure.** The orchestrator calling it today is your code. The orchestrator calling it in three years is a model.

### The Latency Problem — and How to Pay for the Loop  {#latency}

The honest cost of going agentic is latency. A deterministic pipeline runs one query plan: query understanding (~5&nbsp;ms) → engine call (~50&nbsp;ms) → rerank (~50&nbsp;ms) → compose. Total: ~100&nbsp;ms for the fast path. A plan-act-analyze loop costs *(LLM inference for planning + engine call + LLM inference for analysis)* per iteration. With a frontier model at 200–400&nbsp;ms per call and three iterations, you're at 750&nbsp;ms to 1.5&nbsp;seconds before the user sees anything. That's the difference between "feels instant" and "feels broken."

The bottleneck also *moves*. In the deterministic pipeline the engine dominates and you tune Solr. In the agentic loop the LLM dominates by a factor of 4–10×, and tuning the engine harder buys you almost nothing. Seven mitigations, ordered roughly by impact:

- **Specialized, smaller orchestrator models.** A 50&nbsp;ms domain-tuned model vs a 300&nbsp;ms frontier model changes the equation entirely. SID-1, Waldo and similar models are designed to be cheap enough to call multiple times per query. For online search, the single biggest lever.
- **Speculative parallelism.** Fire multiple candidate retrievals in parallel from the first plan and let the analysis step pick. Two iterations of serial latency collapse to one.
- **Hot-path bypass for simple queries.** A small fast classifier decides: simple queries → deterministic pipeline (~100&nbsp;ms), complex or ambiguous queries → agent (500–1500&nbsp;ms).
- **Caching at multiple layers.** Query-IR caching, retrieval caching, reranker caching by `(query_hash, doc_id)`. Cache hit rates of 30–60% on hot queries are realistic.
- **Streaming results during iteration.** Start streaming partial output from the first iteration while the agent decides whether to refine. The user perceives latency as "time to first useful content," not "time to final response."
- **Iteration budgets and timeouts.** Hard cap on agent iterations: typically 2–3 for online queries.
- **Deterministic plan and analyze, with LLM escalation.** Implement the *plan* and *analyze* steps as rules, heuristics, lookups, small fast classifiers — and reach for an LLM only when the deterministic version reports low confidence. You keep the agentic *architecture* while running it at deterministic-pipeline cost for 90% of queries.

> The agentic architecture and the LLM tax are **separable**. Build the plan-act-analyze loop deterministically. Open up to LLM-driven plan and analyze selectively, where measurement shows rules can't carry the load.

The combination matters more than any individual mitigation. A realistic production setup: a deterministic plan-act-analyze loop for every query (~120&nbsp;ms baseline); hot-path bypass skipping the loop entirely for trivial queries (~80&nbsp;ms, 40% of traffic); LLM escalation in plan or analyze for genuinely ambiguous queries (+200–300&nbsp;ms, 8% of traffic); full multi-iteration LLM-driven loop reserved for the hardest cases (~600&nbsp;ms, 2% of traffic). Weighted average: well under 150&nbsp;ms.

> Agentic search is a **latency tax** — and the bill comes due on every iteration. Don't ship a 1.5-second loop and hope users forgive you.
{:.is-red}

### The Guiding Idea  {#layers}

A resilient stack accepts three truths. First, *the engine is the longest-lived component, but not the most valuable one* — you swap it maybe once every five years; the layers above grow every year. Second, *ranking is its own subsystem*, not an engine feature. Third, *the SERP is composed in the application layer*, not in the index.

#### Layer&nbsp;1 — Stable Domain API (the Search BFF)

The most important decision in the whole stack. The client (web, app, later agents via MCP) speaks *not* with the engine but with its own domain API, formulated in the language of your search — `/search?q=...&filter=type:trick&page=2`, not `/solr/select?q=...&fq=...&rows=10`. The response format is also independent: `{ hits: [...], facets: [...], suggestions: [...], answer?: {...} }` — and contains *no* Solr-specific fields.

Take this seriously, and you can switch engines later without touching the client. Don't, and in two years you have `solrFacetCount` in your React code and never get out again.

#### Layer&nbsp;2 — Query Understanding

Incoming query → outgoing structured representation (the internal *Query IR*). Spellcheck/did-you-mean, synonym expansion, language detection, intent classification, and increasingly LLM-based: sub-query decomposition, HyDE-style query hypotheses, entity linking to your own vocabulary.

Important: this stage returns an object, not a rewritten string. A good query IR looks like:

<pre class="is-json">{
  "raw": "new tricks for beginners",
  "normalized": "new tricks for beginners",
  "language": "en",
  "intent": "browse",
  "entities": [{"type": "skill_level", "value": "beginner"}],
  "expanded_terms": ["tricks", "stunts", "moves"],
  "embeddings": { "dense": [], "sparse": {} },
  "subqueries": []
}</pre>

**Vector search is not semantic search.** This distinction lives here, in Query Understanding. *Vector search* embeds the query string and finds documents whose embeddings are close — a similarity operation, not a meaning operation. *True semantic search* takes the actual meaning of the query and reflects it into retrieval, often by rewriting or augmenting the query before it touches the engine.

The classic example is "wireless bras." A general-purpose embedding model puts "wireless bras" near documents about bras in general — the word "wireless" is a weaker signal in the embedding than the word "bras," and the model has no domain knowledge that, in this product category, "wireless" means "no underwire." Pure vector search will happily return underwire bras as top results. True semantic search recognizes the intent — *no underwire* — and acts on it.

> Vector search asks **"what's nearby?"** Semantic search asks **"what did you mean?"** The first is math. The second is domain knowledge — and the document index alone won't give it to you.

#### Layer&nbsp;3 — Retrieval Orchestrator

The ranking brain. The orchestrator decides: *which* retrieval strategies run (BM25, dense, sparse/SPLADE, late interaction), *in parallel or sequentially*, *how to fuse* (RRF, linear combination, learned), and *how much* (top-K). This is where you can later *emulate* Vespa-style multi-phase ranking even if the engine only delivers phase&nbsp;1.

#### Layer&nbsp;4 — Engine Adapter

The adapter translates the internal query IR into what the specific engine understands. Solr gets `{!bool should=$lex should=$knn}`, OpenSearch gets a `hybrid` pipeline, Qdrant gets a `query_points` call with prefetch. The adapter must contain *no* business logic — that belongs in the orchestrator or reranking. The adapter is dumb and mechanical; that's its virtue.

#### Layer&nbsp;5 — Reranking as Its Own Stage

The most important *additional* service in this stack — and the one most teams get the biggest relevance gain from. In practice you run two tracks here: a fast cross-encoder or ColBERT for the default path (~50–100&nbsp;ms on top-50), and optionally an LLM reranker for high-value queries. Reranker outputs are cacheable by `(query_hash, doc_id)` pair.

#### Layer&nbsp;6 — Result Composition

The SERP is assembled here. Hits from the reranker, facets from the engine, highlights, optionally a generative answer (RAG with the top-3 hits as context), possibly a dynamic UI hint. This layer will grow the most in the next several years, because generative UI and AI-Overview-style features dock here. That's exactly why it must not touch the engine directly.

## Filters and Facets — The Second Path  {#filters}

The layers above optimize the *relevance path*: full-text query in, ranked hits out. Filters and facets are different in nature — deterministic, set-based, and need neither embeddings nor reranking. A future-proof architecture treats them as a second, leaner path through the same stack.

<pre>Browse path (filters, no full-text query)
─────────────────────────────────────────

┌──────────────────────────────┐
│ Client (Web, App, Agent,MCP) │
│ Filters+facets, no q         │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│   Search BFF / Domain API    │
│ /search?filter=…&facet=…     │
└──────────────┬───────────────┘
               │ (Query Understanding,
               │  Orchestrator, Reranking
               │  are skipped)
               ▼
┌──────────────────────────────┐
│        Engine adapter        │     ┌──────────────────────────┐
│ Filters as pre-filter        │ ◀── │ Facet-only / Suggest     │
│ Facet aggregations           │     │ (cacheable, separate)    │
└──────────────┬───────────────┘     └──────────────────────────┘
               │
               ▼
┌──────────────────────────────┐
│        Search engine         │
│ Filters + Facet in 1 round   │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│      Result composition      │
│ Hits + Facets + Selections   │
└──────────────────────────────┘</pre>

### Where Filters and Facets Land in the Layers

- **Domain API:** Filters and facets must be *first-class*. `/search?q=...&filter[category]=trick&facet[]=brand`. The response format needs its own `facets` section with buckets, counts, and the currently active selection.
- **Query Understanding** does noticeably less here. The exception is *natural-language filter extraction*: "cheap BMX bikes under 500 euros" should become `{q: "BMX bikes", filter: {price: "<500"}}`.
- **Retrieval Orchestrator:** the browse path forks from the relevance path. Pure filter queries need no hybrid fusion, no RRF, no embeddings.
- **Engine Adapter:** the most important technical pitfall is here. Filters must go to the KNN search as *pre-filter*, not as *post-filter*. Solr&nbsp;10 supports pre-filtering via the `filter` clause of the KNN query, OpenSearch via `efficient_filter`, Qdrant via native filter conditions.
- **Reranking** is skipped in the browse path. Reranking a purely filtered list with no query is pointless.
- **Result Composition** builds the facet UI from the engine's buckets — and decides *which* facets are displayed (sticky, conditional, hierarchical).

### Do Facets Have to Come from the Search Engine?

The honest answer: usually yes, but not necessarily. The dividing line runs along the question of whether the facet refers to the *current result set* or to the *full corpus or analytics data*.

**Should come from the engine** are all facets that aggregate over the current search/filter result set — the classic refinement facets. **Don't have to come from the engine** are global counts and analytics-style aggregates — those belong in an OLAP store like ClickHouse or Druid.

> The decisive question: does the facet count the **current result set**, or the **whole corpus**? Result set → engine. Corpus → can live elsewhere.

### When Filters Cost You Recall — and How LLMs Change the Calculus

There's a rule every senior search engineer has evangelized at some point: **do not pre-select filters from a free-text query.** The reasoning is sound. Pre-selecting filters destroys recall in two ways at once. *Misclassification:* the system infers a filter the user didn't intend, and correct documents disappear. *Missing attribute data:* documents that *would* match are tagged inconsistently or not at all in the filter field. The user sees a thin, wrong result set and walks.

The question is whether LLMs change the calculus, and the honest answer is: yes, but only with deliberate safeguards. Three patterns make filter inference safer:

- **Filters as boosts, not gates.** `boost:underwire=false^3.0` instead of `filter:underwire=false`. Trades a small amount of precision for a meaningful amount of safety.
- **Confidence-aware filter application.** The LLM returns a confidence score with each candidate. High-confidence numeric constraints → filters. Lower-confidence semantic inferences → boosts or omitted.
- **Agentic iteration with recall checks.** Apply the inferred filter, look at the result count. If the result set collapsed below threshold, drop the filter and re-run. The orchestrator detects the failure mode and self-corrects.

> The old rule "never pre-select filters from a free-text query" wasn't wrong — it was right for a system that **couldn't recover.** With LLM-driven query understanding and an orchestrator that can iterate, the rule becomes "pre-select as **boosts**, with **confidence**, with a **fallback path**." Same caution, more tools.

### Consequences for Engine Choice

Solr and OpenSearch have the most mature faceting engines in the Lucene family. If a use case is heavily browse- and filter-driven (product catalog, classical site search), Lucene-based stays the natural choice. For RAG-centric use cases where facets play a minor role, the weakness of the vector-first DBs is acceptable.

> The split between **relevance path** and **browse path** belongs in the orchestrator — not the adapter, not the composer. Miss it, and pure filter queries push embeddings through the stack for nothing.
{:.is-red}

## Autosuggest — The Underestimated Lever  {#autosuggest}

Autosuggest is not an afterthought in e-commerce. Vinted reports that over 20% of all search sessions now *start* with a click on a suggest result — a few years ago it was below 8%. The system handles 4,700 queries per second with P99 of 31&nbsp;ms against a pool of 125&nbsp;million suggestions. That's not UX polish, that's a direct conversion lever.

### Autosuggest Is Not Ordinary Search

- **Latency class:** P99 below ~30–50&nbsp;ms against a large suggestion pool, on every keystroke. Full-text search may take 200&nbsp;ms; suggest may not.
- **Load profile:** 5–8 suggest calls per submitted search — suggest QPS is typically 5–10× higher than search QPS.
- **Its own index, its own ranking logic:** we rank *queries*, not documents. At Vinted, query-log candidates make up only 2% of the pool but generate about half of all clicks.
- **Ranking signals differ:** not BM25 + vector but STR (sell-through rate), suggestion CTR, prefix-level click frequency, and crucially: *input length*.
- **Its own fallback logic:** progressive relaxation — exact prefix → fuzzy(1) → fuzzy(2) — with stop-as-soon-as-10-results.

> Suggest is its own **subsystem** — its own index, its own latency class, its own ranking model. Treat it as a setting on full-text search and you build a feature. Architect it as its own path and you build a **conversion lever**.

### What Solr&nbsp;10 Brings to the Table

Solr has traditionally had a rich suggester infrastructure. The building blocks are solid, but the gap to the Vinted/Vespa reference architecture is real.

**Existing building blocks in Solr&nbsp;10:** `AnalyzingInfixSuggester` and `BlendedInfixSuggester` (Lucene-based, with a real analyzer chain); `FuzzySuggester` for Levenshtein-based typo tolerance; `WFSTCompletionLookup` / `FSTCompletionLookup` for very fast FST-based lookups (FSTLookupFactory is the new default in 10); EdgeNGram field type as a manual path; context filtering; chained suggesters mapping the tier architecture; mature LTR with vector features since 9.3.

**Where Solr&nbsp;10 falls structurally behind Vespa:** LTR in the hot path on every keystroke is possible but uncomfortable. Real-time feature store for user features is missing. Accent tolerance with intent preservation isn't out-of-the-box. Streaming-mode indexing for suggest-pool updates is doable but not the standard path.

### Concrete Recommendation for Building Autosuggest

If the customer today has Solr&nbsp;9 with rudimentary suggest and wants to raise the level with Solr&nbsp;10, I would *not* start with LTR. Vinted's data are very clear: the biggest lever wasn't ML reranking, but adding query-log candidates to the pool.

1. **Raise the baseline:** BlendedInfixSuggester on a dedicated suggest core, pool from product metadata + search logs, simple heuristic, progressive relaxation in two tiers. A 2–3 week project, probably captures 80% of the Vinted effect.
2. **Build out tier matching and measure:** add the third fuzzy tier, set up A/B tests. Tune Solr suggest performance to P99 &lt;&nbsp;30&nbsp;ms.
3. **Personalization via reranker service:** only then add LightGBM reranking as its own stage. Start with few, high-impact features.
4. **Session awareness and personal history** as API features, no engine changes needed.

> The biggest suggest lever isn't the **model** — it's the **pool**. Real user queries from your search logs beat any personalization you can bolt on top.

## The Indexing Path  {#indexing}

The indexing pipeline is *the* place where embedding discipline is decided. Three rules:

- **Embeddings are versioned.** Every embedding carries a model tag (`bge-m3-v1`, `e5-large-v2`). When you change the model, dual-write runs: all new documents get both embeddings, the backfill runs in the background, and only when 100% coverage is reached does the query side switch over.
- **Embedding generation as its own service**, not as an engine plugin. Solr&nbsp;10's `TextToVectorQParser` is tempting, but it binds the embedding logic to the engine. Better: a small dedicated service called both from the indexing pipeline and from query understanding. Same model on both sides — that's the point that often goes wrong.
- **The pipeline is declarative**, ideally CDC-driven. A document update in the CMS → an event → the pipeline normalizes, chunks, embeds, indexes. No cron job, no "reindex button."

### The Central Cross-Layer — Evaluation

This is the service 80% of teams forget, and it has the largest lever. Three components:

- A **goldset** with query → expected top-K, maintained by the business side. A nightly job computes NDCG, MRR, recall@K with explicit metric targets.
- An **A/B infrastructure** running two configurations in parallel and measuring online metrics (CTR, position of first click, reformulation rate, zero-result rate).
- **Structured telemetry** linking every click to the query IR active at the time and the displayed hit list. This is simultaneously the training-data pipeline for later learning-to-rank.

Without this layer you can't measure improvements, and without measurement every change becomes an act of faith.

## Putting It Together — What This Means for Solr&nbsp;10  {#together}

In the customer's context: Solr is the engine in the "Search engine" box. Around it sit embedding service (standalone), query understanding (standalone, initially simple), retrieval orchestrator (initially thin, just hybrid + RRF), adapter (Solr-specific), reranker (standalone, with a cross-encoder), composition (standalone). Search BFF at the top.

If you build it this way, a later switch to OpenSearch costs only the adapter swap and a reindex, no replatforming. A switch to Vespa costs more — parts of the orchestrator and reranker migrate into Vespa, because Vespa does this natively — but the domain API and the client stay untouched.

> Keep the **domain API**, the **reranker**, and the **composer** Solr-free. Those three layers clean, everything else is fixable. Those three layers dirty, nothing is.
{:.is-red}

The honest answer to "which engine ages best" is therefore: the one you hard-wire the least.

## Sources for Deeper Research  {#sources}

#### Engine documentation and releases

- [Apache Solr&nbsp;10 Reference Guide — Suggester](https://solr.apache.org/guide/solr/latest/query-guide/suggester.html){:target="_blank" rel="noopener"}
- [Major Changes in Solr&nbsp;10](https://solr.apache.org/guide/solr/latest/upgrade-notes/major-changes-in-solr-10.html){:target="_blank" rel="noopener"}
- [Sease.io blog on Solr vector search and KNN optimization](https://sease.io/category/apache-solr){:target="_blank" rel="noopener"}
- [Vespa.ai documentation](https://docs.vespa.ai/){:target="_blank" rel="noopener"} and [Vespa blog](https://blog.vespa.ai/){:target="_blank" rel="noopener"}
- [Qdrant articles](https://qdrant.tech/articles/){:target="_blank" rel="noopener"} — BM42, RRF, DBSF, hybrid reranking patterns
- [Elasticsearch search-as-you-type field type](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-as-you-type.html){:target="_blank" rel="noopener"}

#### E-commerce search field reports

- [Vinted Engineering: How Vinted Serves Personalised Search Autocomplete](https://vinted.engineering/2026/04/22/personalized-search-autocomplete/){:target="_blank" rel="noopener"}
- [Vinted Engineering: Goodbye Elasticsearch, Hello Vespa](https://vinted.engineering/2024/09/05/goodbye-elasticsearch-hello-vespa/){:target="_blank" rel="noopener"}
- [Alexander Reelsen: Mirror, mirror, what am I typing next?](https://spinscale.de/posts/2023-01-18-mirror-mirror-what-am-i-typing-next.html){:target="_blank" rel="noopener"}
- [Alexander Reelsen: Implementing a Modern E-Commerce Search](https://spinscale.de/posts/2020-06-22-implementing-a-modern-ecommerce-search.html){:target="_blank" rel="noopener"}
- [Pureinsights: Elasticsearch vs OpenSearch in 2025](https://pureinsights.com/blog/2025/elasticsearch-vs-opensearch-2025/){:target="_blank" rel="noopener"}

#### Research and curated collections

- [frutik/awesome-search](https://github.com/frutik/awesome-search){:target="_blank" rel="noopener"}
- [Doug Turnbull: Agentic Search Models](https://softwaredoug.com/blog/2026/05/11/the-new-agentic-search-models){:target="_blank" rel="noopener"}
- [SID-1 research note](https://www.sid.ai/research/sid-1){:target="_blank" rel="noopener"}
- [Glean: Waldo launch](https://www.glean.com/blog/waldo-launch){:target="_blank" rel="noopener"}
- [ColPali: Efficient Document Retrieval with Vision Language Models](https://arxiv.org/abs/2407.01449){:target="_blank" rel="noopener"}
- [Counterfactual Learning to Rank for Utility-Maximizing Query Autocompletion](https://arxiv.org/abs/2204.10936){:target="_blank" rel="noopener"}
- [Pruning Radix Trie (Wolf Garbe, SeekStorm Blog)](https://seekstorm.com/blog/pruning-radix-trie/){:target="_blank" rel="noopener"}
- [Lucidworks: Auto-Suggest from Popular Queries Using EdgeNGrams](https://lucidworks.com/post/auto-suggest-from-popular-queries-using-edgengrams/){:target="_blank" rel="noopener"}
- [SIGIR Workshop on eCommerce](https://sigir-ecom.github.io/){:target="_blank" rel="noopener"}

<aside class="process-note">
  <span class="process-note__label">Colophon</span>
  <h4 class="process-note__head">How this came together</h4>
  <p>
    This document is the residue of <strong>a couple of weeks of musing
    with Claude</strong> &mdash; drafts that turned into chapters, chapters
    that collapsed back into footnotes, arguments rewritten against
    themselves.
  </p>
  <p>
    What you&rsquo;re reading is a <em>living document</em>. As Solr&nbsp;10
    matures, as the agentic layer shifts, as the field reports keep
    landing, the recommendation gets re-tested and the prose gets re-cut.
    The thinking is mine; the iteration speed and the willingness to argue
    against yesterday&rsquo;s position are not entirely.
  </p>
  <p class="process-note__sig">
    <span>— Torsten Bøgh Köster, May&nbsp;2026</span>
    <span class="process-note__stamp">Published&nbsp;May&nbsp;18,&nbsp;2026</span>
  </p>
</aside>
