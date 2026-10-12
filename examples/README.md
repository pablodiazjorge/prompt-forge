# Example: one curation cycle

A fictional team of three (@ana, @ben, @chen) works on a billing service. Each
uses a different agent: Claude Code, GitHub Copilot, and Codex. Everything here
is invented to show the formats.

## Before curation

Over two weeks, `record-lesson` wrote three candidate lessons as part of ordinary
pull requests:

| Lesson | Sightings | Reporters | What happened |
|---|---|---|---|
| [regenerate-client-after-schema-edit](lessons/regenerate-client-after-schema-edit.md) | 3 | 2 | Two people's agents edited the API schema and forgot the generated client |
| [seed-needs-db-container](lessons/seed-needs-db-container.md) | 2 | 2 | Two agents ran the seed script before the database was up |
| [port-3000-in-use](lessons/port-3000-in-use.md) | 4 | 1 | One person's agent kept hitting a busy port |

## Curation

@ana asked her agent to run `curate-lessons`. It worked on
`chore/curate-lessons-20261026` and:

- promoted the schema lesson to a three-line entry in
  [memory/api-client.md](memory/api-client.md) and deleted the lesson file;
- proposed fixing the seed script instead of writing memory (rung 1 of the
  promotion ladder), recorded that in the lesson's `fix:` field, and kept the
  lesson until the fix merges;
- held the port lesson: four sightings, all from one person.

The report it returned became the pull request description:
[curation-pr.md](curation-pr.md). @ben reviewed and merged it. From then on,
any teammate's agent about to touch `api/openapi.yaml` reads the matching memory
file first, whichever agent it is.

The `lessons/` files above show the state *before* curation. In the repository
after the merge, `regenerate-client-after-schema-edit.md` no longer exists.
