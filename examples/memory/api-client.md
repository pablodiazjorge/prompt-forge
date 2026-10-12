---
description: Read when editing api/openapi.yaml or code under src/generated/.
---

# API client

- Regenerate the client with `make gen` after editing `api/openapi.yaml`, and
  never hand-edit `src/generated/`: CI type-checks the committed client.
  <!-- verified 2026-10-26 | review after 2027-04 | from lesson regenerate-client-after-schema-edit -->
