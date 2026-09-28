---
description: 'Turn an open technical question into a spike document, research it, and end with a recommendation and follow-up backlog items.'
agent: Technical spike research mode
argument-hint: 'The technical question'
---

Research this technical question:

${input:question:for example: we want messages from the bus to be delivered idempotently — what is the status and what do you recommend?}

1. Create a spike document with the `create-technical-spike` skill in `docs/spikes/`. Split the
   question into a primary question and secondary questions, and write success criteria.
2. Start with the current state *in this repository*: find where the topic is implemented today,
   what is already guaranteed and what is not, with file references.
3. Research the external side (official documentation, known patterns, limits of the platform)
   and cite every source.
4. Ask before running any experiment or creating code outside the spike document.
5. Finish the document with a clear recommendation, the rationale, and the alternatives rejected.
6. End with follow-up backlog items (title, why, draft acceptance criteria) that I can hand to the
   PBI Refiner.
