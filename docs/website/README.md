# docs/website

Future user-facing docs site for maestro (planned: [Astro Starlight](https://starlight.astro.build)).

Only docs for people *using* maestro go here: install, quick start, CLI
reference, configuration, protocol. Internal docs (PRD, design notes,
conventions) live in [../development](../development).

Planned layout once the site exists:

```
docs/website/
  package.json          # Astro + Starlight, separate from the Go module
  astro.config.mjs      # site config, sidebar
  src/content/docs/     # pages (.md; .mdx only when a page needs components)
  public/               # images, favicons
```

Pages use plain Markdown with relative links so they read the same on GitHub,
in Obsidian and on the site.
