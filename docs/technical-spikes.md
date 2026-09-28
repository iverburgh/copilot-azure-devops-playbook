# Technical spikes

Some questions are not backlog items yet, because nobody knows what the item should be:

> We want messages from the service bus to be delivered idempotently. What is the status of this,
> and what do you recommend?

The **Technical spike research mode** agent, from
[github/awesome-copilot](https://github.com/github/awesome-copilot), researches a question
systematically and keeps a spike document up to date while it works. It is included unmodified; see
[THIRD-PARTY-NOTICES.md](../THIRD-PARTY-NOTICES.md).

## Running it

`/spike <question>` does the whole sequence:

1. Creates a spike document in `docs/spikes/` with the (also upstream) `create-technical-spike`
   skill: primary and secondary questions, success criteria, a timebox.
2. Establishes **the current state in your repository first** — where the topic is implemented,
   what is already guaranteed and what is not, with file references. For the example above: which
   consumers already deduplicate, which rely on at-least-once delivery without protection, and what
   the transport is configured to do.
3. Researches the outside world — official documentation, known patterns, platform limits — and
   cites every source in the document as it goes.
4. Asks before running experiments or writing code outside the document.
5. Ends with a recommendation, its rationale and the rejected alternatives.
6. Lists **follow-up backlog items** with draft acceptance criteria, ready for the
   [PBI Refiner](refinement.md).

The upstream agent insists on a spike document before it starts; the prompt creates one first, so
you can start from a bare question.

## Why a document and not a chat answer

A spike answer that lives in a chat window is gone by next sprint. The document records what was
checked, what was found, which sources were used and what was decided — so when someone asks
"why did we choose this", the answer exists. Commit it next to the ADRs; if the recommendation is an
architectural decision, the Refiner will ask for an ADR anyway.
