# Draft: Agent Modes Overview

This draft documents two orchestration modes used by the agent system to gather context and maximize discovery: Search-Mode and Analyze-Mode. It defines when to use each mode, how they orchestrate Explore/Librarian/Oracle/Metis/Momus, and how results flow into decision-making.

## 1) Search-Mode: MAXIMIZE SEARCH EFFORT
- Objective: Exhaustively search the codebase and external references in parallel, using multiple exploration and librarian tasks. Do not stop at the first result; aim for comprehensive coverage.
- Components:
  - Explore agents: codebase patterns, file structures, AST-based pattern hunting
  - Librarian agents: remote repositories, official docs, GitHub examples
  - Direct tools: Grep, rg, ast-grep (sg)
- Execution characteristics:
  - Parallel, background execution
  - Exploration depth guided by prompts and ongoing synthesis
- Outputs:
  - Catalog of patterns, file paths, references, and evidence
  - Candidate patterns with confidence scores
- Success criteria:
  - >=2 distinct codebase patterns identified
  - >=2 credible external references per pattern
  - No critical gaps left uncovered by at least one round of exploration
- Failure modes and handling:
  - Incomplete results: spawn additional explores or librarian tasks
  - Duplicated results: deduplicate and reconcile
- Interactions:
  - If a complex design decision emerges, escalate to Oracle or Artistry
- Example delegate_task prompts:
  - delegate_task(subagent_type="explore", load_skills=[], run_in_background=true, prompt="...pattern hunt in src/")
  - delegate_task(subagent_type="librarian", load_skills=[], run_in_background=true, prompt="...external docs for pattern X")

- Rationale: This mode accelerates coverage when the problem space is broad and uncertain.

## 2) Analyze-Mode: ANALYSIS MODE
- Objective: Gather structured context before deep-diving; synthesize a preliminary situational picture.
- Composition:
  - 1-2 explore tasks (patterns/implementations)
  - 1-2 librarian tasks (external context if relevant)
  - Tools: Grep, AST-grep, LSP for targeted searches
- Execution characteristics:
  - Parallel, background exploration
- Outputs:
  - Synthesized context document and decision points
- Success criteria:
  - Comprehensive synthesis with minimal ambiguities
  - At least 2 questions for clarification (if needed)
- Collaboration:
  - If complex constraints arise, bring in Oracle (architecture debug) or Artistry (non-traditional approaches)
- Protocol:
  - Synthesis first, then decisions; proceed with plan only when context is clear
- Example delegate_task prompts:
  - delegate_task(subagent_type="explore", load_skills=[], run_in_background=true, prompt="...context gather for module X")
  - delegate_task(subagent_type="librarian", load_skills=[], run_in_background=true, prompt="...docs around module X")

## 3) Agent Roles and Handoff
- Explore: surface-level and deep patterns in codebase
- Librarian: external docs and examples
- Oracle: architecture/design consensus and complex logic
- Metis: gap identification and decision journaling
- Momus: verification and QA signal generation

## 4) Initialization Prompts (recommended)
- Explore: "Map codebase patterns and file structures relevant to the current task."
- Librarian: "Fetch official docs and high-signal external references for identified patterns."
- Oracle: "Provide architecture-level alternatives and trade-offs with risk assessment."
- Metis: "Identify gaps and define acceptance criteria for the plan."
- Momus: "Prepare verification criteria for the proposed plan."

## 5) Collaboration Strategy
- Parallel execution whenever possible
- Ensure Metis creates guardrails and acceptance criteria
- Final plan only after Momus-approved verification

## 6) Decision Points
- If multiple viable patterns exist, escalate to Oracle/Artistry
- If context is insufficient, revert to Analyze-Mode or additional Explore tasks

## 7) Next Steps
- Choose initial mode and delegate tasks accordingly.
