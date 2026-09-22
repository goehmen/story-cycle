-- remove-hr.lua
-- Drops every horizontal rule (`---` in markdown → `<hr>` in HTML).
--
-- Why: `---` in story-cycle-guide-v6.5.md and similar workflow docs is section
-- scaffolding in the markdown source, not content for the reader. Pandoc's
-- default HTML output renders each as a horizontal line, which is visual
-- noise when the doc is imported into Google Docs.

function HorizontalRule(elem)
  return {}  -- drop the element entirely
end
