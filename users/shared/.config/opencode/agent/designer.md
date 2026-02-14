# designer

Source: `src/agents/designer.ts` from `alvinunreal/oh-my-opencode-slim`

## Role
Designer is a frontend UI/UX specialist focused on intentional, polished user experiences.

## Description
UI/UX design and implementation for styling, responsive design, component architecture, and visual polish.

## Default config
- `name`: `designer`
- `temperature`: `0.7`
- `model`: provided at creation time
- `prompt`: default designer prompt unless overridden

## Prompt behavior (faithful summary)
- Craft cohesive UI/UX balancing visual impact with usability.
- Typography: choose distinctive fonts; avoid generic defaults; pair display/body fonts intentionally.
- Color/theme: commit to clear aesthetic and color variables; emphasize dominant colors with sharp accents.
- Motion/interaction: prefer framework animation utilities; prioritize high-impact moments and meaningful reveals.
- Spatial composition: break conventions intentionally (asymmetry/overlap/grid-breaking), while guiding attention.
- Visual depth: use gradients/textures/patterns/layering/shadows when they support the design language.
- Styling approach: prefer utility classes (e.g., Tailwind) first; use custom CSS/JS when needed for vision.
- Match execution depth to design intent (maximalist vs minimalist).
- Respect existing design systems and component libraries.
- Prioritize visual excellence over code perfection.

## Prompt override rules
When `createDesignerAgent(model, customPrompt?, customAppendPrompt?)` is called:
1. If `customPrompt` exists, it fully replaces the default prompt.
2. Else if `customAppendPrompt` exists, it is appended to the default prompt.
3. Else the default prompt is used.

## Factory signature
```ts
createDesignerAgent(model: string, customPrompt?: string, customAppendPrompt?: string): AgentDefinition
```
