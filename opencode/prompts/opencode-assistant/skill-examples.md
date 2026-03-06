# Skill Examples & Architecture

This document provides detailed examples of how skills are structured using progressive disclosure architecture.

## Progressive Disclosure Architecture

Skills load in three stages to prevent context bloat:

```
┌─────────────────────────────────────────────────────────────┐
│ Stage 1: SUMMARY (always loaded)                            │
│ ─────────────────────────────────────────────────────────── │
│ YAML Front Matter                                            │
│ • name: skill-name                                           │
│ • description: When to use this skill                        │
│                                                              │
│ This loads for ALL installed skills initially.              │
│ Claude scans these to decide which skill to activate.       │
└─────────────────────────────────────────────────────────────┘
                            ↓
              (Skill activated based on description match)
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 2: PROCESS (loaded when skill activates)              │
│ ─────────────────────────────────────────────────────────── │
│ skill.md Body                                                │
│ • Step-by-step instructions                                 │
│ • When to load reference files                              │
│ • Which scripts to execute                                  │
│                                                              │
│ This is the "how to use" guide for the skill.              │
└─────────────────────────────────────────────────────────────┘
                            ↓
                (skill.md references specific files)
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 3: KNOWLEDGE (loaded on-demand)                       │
│ ─────────────────────────────────────────────────────────── │
│ Reference Files                                              │
│ • references/knowledge-base.md                              │
│ • scripts/generate.py                                       │
│ • assets/examples/                                          │
│                                                              │
│ Only loaded when skill.md explicitly references them.       │
└─────────────────────────────────────────────────────────────┘
```

## Example 1: Marketing Ideas Skill

A well-structured skill that demonstrates "point don't dump" principle.

### Stage 1: YAML Front Matter (Summary)
```yaml
---
name: marketing-ideas
description: >
  When the user needs marketing ideas, inspiration or strategies for their
  SaaS or software product. Also used when the user asks for marketing ideas,
  growth ideas, how to market, marketing strategies, marketing tactics,
  ways to promote or ideas to grow. This skill provides 139 proven marketing
  approaches organized by category.
---
```

**Why this works:**
- Specific trigger phrases: "marketing ideas", "growth ideas", "how to market"
- Clear scope: SaaS/software products
- Mentions what it provides: 139 approaches by category
- Tells Claude exactly when to activate it

### Stage 2: skill.md Body (Process)
```markdown
# Marketing Ideas Skill

## Process

1. **Check for product context first**
   - Look for `docs/product-marketing-context.md`
   - This file should contain: product description, audience, stage, goals

2. **Suggest 3-5 most relevant ideas**
   - Based on the product context
   - Consider their current stage (early, growth, scale)
   - Match to their resources and constraints

3. **Provide implementation details**
   - For chosen ideas, give step-by-step guidance
   - Consider their: resources, time, budget, team size

4. **Reference the knowledge base**
   - For content marketing ideas → load `references/content-marketing.md`
   - For SEO strategies → load `references/seo-tactics.md`
   - For community building → load `references/community-growth.md`

## Output Format

Present ideas as:
- **Idea Name**: Brief description
- **Best For**: Stage/type of company
- **Implementation**: 2-3 concrete steps
- **Resources Needed**: Time/budget estimate
```

**Why this works:**
- Clear step-by-step process
- References external files only when needed
- Doesn't dump all 139 marketing ideas into skill.md
- Provides structured output format

### Stage 3: Reference Files (Knowledge)

**`references/content-marketing.md`** (excerpt):
```markdown
# Content Marketing Ideas

## Blog & SEO
1. **Ultimate Guides**: Create comprehensive 5000+ word guides
   - Best for: Early stage building authority
   - Timeline: 2-4 weeks per guide
   - Tools: Ahrefs for keyword research

2. **Problem-Solution Posts**: Address specific pain points
   - Best for: All stages, conversion-focused
   - Timeline: 1-2 days per post
   - Distribution: Reddit, forums, Slack groups

[... 40+ more detailed ideas ...]
```

**Why this works:**
- Detailed knowledge lives here, not in skill.md
- Only loaded when skill.md says "load content-marketing.md"
- Can have multiple reference files for different categories
- Easy to update knowledge without changing process

### Skill vs AGENTS.md

**When to use each:**

| AGENTS.md | Skills |
|-----------|--------|
| Project-wide "standard rulebooks" | Complex, multi-step "tricks" |
| Static context at session start | Dynamic context loaded on-demand |
| Build commands, code style, git conventions | Marketing ideas, code review checklists, testing procedures |
| Always loaded | Only loaded when explicitly invoked via `skill` tool |
| Keep under 500 lines | Can be extensive with references |

**Example AGENTS.md content:**
- "Use pytest for testing"
- "Follow PEP 8 style"
- "Commit messages: type: description"

**Example Skills content:**
- TDD workflow with red-green-refactor loop
- Content creation process with brand voice references
- API documentation generation with templates

---

## Example 2: SEO Content Writer (Multiple References)

Demonstrates how to use different reference files for different tasks.

### YAML Front Matter
```yaml
---
name: seo-content-writer
description: >
  Use when user wants to create SEO-optimized content including blog posts,
  landing pages, or product descriptions. Handles ideation, title generation,
  content structure, and final writing.
---
```

### skill.md Body
```markdown
# SEO Content Writer

## Workflow

### 1. Determine Task Type
Ask user: Are you ideating, creating titles, or writing full content?

### 2. Ideation Phase
If ideating:
- Ask about target audience, keywords, goals
- Generate 5-10 content ideas
- No references needed for ideation

### 3. Title Generation
If generating titles:
- Load `references/title-formulas.md`
- Apply formulas to user's topic
- Test for emotional triggers, clarity, SEO

### 4. Content Structure
If creating content structure:
- Load `references/content-structure-templates.md`
- Choose template based on content type
- Outline sections with keyword placement

### 5. Full Content Writing
If writing full content:
- Use structure from step 4
- Load `references/seo-best-practices.md`
- Write with natural keyword integration
```

**Why this works:**
- Different tasks load different references
- Doesn't load all references upfront
- Progressive: start simple, load more as needed

---

## Example 3: Image Generation (Script Execution)

Demonstrates how skills can execute scripts with minimal skill.md content.

### YAML Front Matter
```yaml
---
name: nano-banana-pro
description: >
  Generate or edit images using Gemini's Imagen 3 (Nano Banana Pro).
  Use for creating images from prompts or editing existing images.
---
```

### skill.md Body
```markdown
# Nano Banana Pro Image Generation

## Single Image Generation
Execute: `scripts/generate-image.py --prompt "[user's prompt]"`

## Image Editing
Execute: `scripts/generate-image.py --edit "[image_path]" --prompt "[edit instructions]"`

## Multiple Image Composition
Execute: `scripts/compose-images.py --images "[img1,img2,img3]" --layout "[layout_type]"`

## Output
Images saved to: `output/generated-images/`
```

**Why this works:**
- skill.md is ultra-concise (just when to run which script)
- Actual generation logic lives in Python scripts
- Scripts not loaded into context, just executed
- Easy to update generation logic without changing skill

**`scripts/generate-image.py`** (not loaded into context):
```python
# This script is executed, not read by Claude
import gemini_api
import argparse

def generate_image(prompt, model="imagen-3"):
    # ... implementation details ...
    pass

if __name__ == "__main__":
    # ... command line handling ...
```

---

## Debugging Skills

When a skill fails, identify whether it's a **process issue** or **knowledge issue**:

### Process Issue (Fix skill.md)
**Symptoms:**
- Skill activates but doesn't follow steps correctly
- Skips important instructions
- Doesn't load reference files when needed

**Solution:**
- Make skill.md steps more explicit
- Add conditional logic ("If X, then Y")
- Clarify when to load which references

### Knowledge Issue (Fix reference files)
**Symptoms:**
- Skill follows process correctly but output quality is poor
- Information is outdated or incomplete
- Examples don't match current standards

**Solution:**
- Update reference files with better examples
- Add more detailed guidance in references
- Include more comprehensive knowledge base

### Activation Issue (Fix YAML description)
**Symptoms:**
- Skill doesn't activate when it should
- Activates for wrong use cases
- User has to explicitly invoke skill instead of automatic

**Solution:**
- Add more trigger phrases to description
- Be more specific about when to use
- Test with various user phrasings

---

## Validation

Use `opencode debug skill` command to verify:
- Skill is discoverable
- YAML parses correctly
- References are found
- No silent YAML indentation failures
