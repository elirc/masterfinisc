# Frontend / React — 12 Question Cards

## Q1: How do you manage server state in a React app?
Round: frontend. Repo anchor: [queries.tsx:33-58, 139-170](../../frontend/src/hooks/api/secrets/queries.tsx), [reactQuery.tsx:220-226](../../frontend/src/hooks/api/reactQuery.tsx).
Junior: "useEffect + useState, or Redux."
Mid adds: server state ≠ app state; React Query with key factories, staleTime policy (60s default here, `0` for auth-fresh data, `Infinity` for server config), invalidation on write.
Senior includes: cache as *identity* system — keys must contain every request param; the manual-invalidation tax and when optimistic updates/subscriptions pay for themselves.
Follow-ups: "why not put query data in Redux?" Drill: recite the four params in `getProjectSecret`'s key and why each must be there.

## Q2: A list shows stale data after a create. Debug it.
Round: frontend/debugging. Repo anchor: [mutations.tsx:58-86](../../frontend/src/hooks/api/secrets/mutations.tsx).
Junior: "force a refetch."
Mid adds: bisect — did the list request re-fire (invalidation) and did it contain the row (server)? Param-by-param key comparison; knows this repo invalidates *nine* families on create for exactly this reason.
Senior includes: the class-level fix (shared key factories, never inline keys) and the staleTime/refetchOnWindowFocus interplay ([reactQuery.tsx:222](../../frontend/src/hooks/api/reactQuery.tsx)) that makes "it fixed itself after a minute" a *symptom, not noise*.
Follow-ups: "when is invalidation the wrong tool?" Drill: Scenario 1 in [05/03-systematic-debugging](../05-quality-engineering/03-systematic-debugging.md), narrated in 3 min.

## Q3: Render vs commit — what actually re-renders and when?
Round: frontend. Repo anchor: [OverviewPage.tsx](../../frontend/src/pages/secret-manager/OverviewPage/OverviewPage.tsx) as the cautionary scale.
Junior: "state change re-renders the component."
Mid adds: render = calling the function + diff, commit = DOM mutation; parent render re-renders children by default; memoization interrupts it; state *placement* (hoisted selection state in a 3,759-line page re-renders the world) beats memo scattering.
Senior includes: profiler-driven workflow; "memoize as caching with invalidation bugs" (deps arrays); when splitting a component is the real fix.
Follow-ups: "controlled input lags at 60fps table — what first?" Drill: pick one state in OverviewPage and argue where it should live.

## Q4: Explain useEffect misuse — what belongs in effects, what doesn't?
Round: frontend. Repo anchor: the *absence* — data fetching lives in React Query hooks, not effects ([hooks/api/](../../frontend/src/hooks/api/)); route guards live in router middleware ([routes.ts:3-4](../../frontend/src/routes.ts)).
Junior: "effects run after render for side effects."
Mid adds: effects are for syncing with external systems; fetching-in-effect problems (races, no cache, no dedupe, unmount leaks) are why the API layer exists; derived state never needs an effect.
Senior includes: stale-closure class; effect deps as an invalidation contract; event-vs-effect framing ("this code runs because the user did X" belongs in the handler).
Follow-ups: "how would you abort an in-flight fetch on unmount — and who does it for you here?" Drill: find one legitimate useEffect in a page and defend it.

## Q5: How does routing state work in a typed SPA?
Round: frontend. Repo anchor: [routes.ts](../../frontend/src/routes.ts) DSL + generated routeTree; Zod-validated search params; middleware layers (`authenticate`, `inject-org-details`).
Junior: "react-router with route components."
Mid adds: URL as typed state (search params validated like any input); beforeLoad middleware replacing redirect-effects; codegen for type-safe links.
Senior includes: URL-vs-memory state placement decisions (shareable/refreshable state belongs in the URL — filters, path, env); auth-guard ordering (route middleware runs before render — no flash of protected UI).
Follow-ups: "where would a 'selected environment' live and why?" Drill: trace `/organizations/$orgId/projects/.../secrets/$envSlug` through routes.ts to its page component.

## Q6: Token refresh with concurrent requests — design it.
Round: frontend (the classic). Repo anchor: [request.ts:52-89](../../frontend/src/config/request.ts).
Junior: "on 401 call refresh then retry."
Mid adds: the stampede problem; singleton in-flight promise; retry-once flag against loops; walks the real code.
Senior includes: replay safety (only because the 401 happened at the auth gate, before the handler ran); failure path UX (bookmark redirect target with expiry); critique of message-string matching as the trigger.
Follow-ups: "two tabs?" (per-tab module state — acceptable? shared worker?). Drill: whiteboard it blind, compare to the file, note what you forgot (usually the `finally`).

## Q7: How do you gate UI by permissions, and what's it worth?
Round: frontend. Repo anchor: `useProjectPermission` ([OverviewPage.tsx:300](../../frontend/src/pages/secret-manager/OverviewPage/OverviewPage.tsx)), HOCs in [hoc/](../../frontend/src/hoc/), contexts in [context/](../../frontend/src/context/).
Junior: "hide the button if not admin."
Mid adds: client checks mirror server CASL abilities for UX only — server remains the enforcer; permission context fetched once, consumed via hooks/HOC gates.
Senior includes: drift risk between UI gates and server actions (ticket J13); never branch *data* fetching on client-side permission guesses (information leak via cached responses).
Follow-ups: "user's role changes mid-session — what happens?" Drill: map one button's UI gate to its backend CASL action.

## Q8: CSS architecture — what does Tailwind buy and cost at scale?
Round: frontend. Repo anchor: Tailwind v4 + cva variants in [components/v2](../../frontend/src/components/v2/), v3 preferred ([frontend/CLAUDE.md](../../frontend/CLAUDE.md)); tokens via CSS custom properties in [index.css](../../frontend/src/index.css).
Junior: "utility classes, fast to write."
Mid adds: colocation kills dead-CSS problem; design tokens centralize theming; `cva` gives variant APIs; `tailwind-merge` resolves conflicts.
Senior includes: the v2→v3 component-library migration as the real story — how design systems version, and the "always use v3 for new code" rule as migration governance.
Follow-ups: "how do you keep 100 devs consistent?" Drill: open one v3 generic component and describe its variant API.

## Q9: Frontend performance — walk me through diagnosing a slow page.
Round: frontend. Repo anchor: Scenario 5 in [05/03](../05-quality-engineering/03-systematic-debugging.md); fan-out at [queries.tsx:173-215](../../frontend/src/hooks/api/secrets/queries.tsx).
Junior: "React.memo and useMemo."
Mid adds: partition first — network waterfall vs server time vs render frames; names one real repo hotspot per bucket (per-env query fan-out; giant page component).
Senior includes: measurement artifacts (Profiler flamegraph, waterfall screenshot) as the deliverable; budget thinking; fix at the guilty layer only.
Follow-ups: "when is a spinner the right fix?" (perceived vs actual). Drill: [04-performance-thinking](../05-quality-engineering/04-performance-thinking.md)'s drill.

## Q10: Forms — how do you handle validation and errors properly?
Round: frontend. Repo anchor: react-hook-form + Zod resolvers ([frontend/CLAUDE.md](../../frontend/CLAUDE.md)); same Zod philosophy as the backend boundary.
Junior: "onChange handlers and error state."
Mid adds: schema-driven validation shared conceptually with the server; uncontrolled inputs for perf; server errors mapped back to fields; the client validates for UX, server for truth.
Senior includes: the double-validation contract (client schema can drift from server schema — how do you notice?); optimistic vs pessimistic submit UX by operation risk.
Follow-ups: "file upload with progress?" Drill: find one form component and trace submit → mutation → invalidation → notification.

## Q11: What is a stale closure bug? Produce one and fix it three ways.
Round: frontend. Repo anchor: conceptual — no direct anchor (React Query's key-driven refetch is the architectural dodge).
Junior: struggles to produce one.
Mid adds: interval/callback capturing old state; fixes: functional setState, deps array correctness, refs for latest-value; explains why key-driven data flow (change key → new query) avoids the class.
Senior includes: linting (`exhaustive-deps`) as contract enforcement; when a ref is *hiding* a design smell.
Follow-ups: "why does adding the dep cause an infinite loop, and what's the real fix?" (unstable object identity — memo the input or restructure). Drill: write the setInterval counter bug from memory.

## Q12: Accessibility — what do you actually check?
Round: frontend. Repo anchor: Radix primitives under v2/v3 components ([frontend/CLAUDE.md](../../frontend/CLAUDE.md)) — accessible behavior (focus trap, aria, keyboard) inherited from the primitive layer.
Junior: "alt text and contrast."
Mid adds: keyboard operability of menus/dialogs/tables, focus management on route change, labels on inputs; the leverage of building on Radix instead of hand-rolling.
Senior includes: a11y as *component-library* responsibility (fix once in the primitive); testing approach (axe pass + manual keyboard sweep on critical flows: login, secret create).
Follow-ups: "your custom dropdown fails keyboard nav — options?" Drill: keyboard-walk the secret-create dialog in the dev stack; note the focus behavior Radix gives free.
