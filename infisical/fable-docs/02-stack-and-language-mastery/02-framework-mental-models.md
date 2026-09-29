# Framework Mental Models

## Fastify: plugins, decoration, hooks

Mental model: Fastify is a *pipeline builder*. You register plugins that decorate the server/request with capabilities, and hooks that run per-request in a fixed order. This repo uses exactly three ideas:

1. **Decoration** — `server.decorate("services", {...})` at [routes/index.ts:3291](../../backend/src/server/routes/index.ts) makes the whole service graph available in handlers as `server.services.*`; `server.decorateRequest("permission", null)` at [inject-permission.ts:8](../../backend/src/server/plugins/auth/inject-permission.ts) reserves a per-request slot.
2. **Hooks** — `onRequest` hooks run before handlers: identity extraction ([inject-identity.ts:155](../../backend/src/server/plugins/auth/inject-identity.ts)), permission injection ([inject-permission.ts:9](../../backend/src/server/plugins/auth/inject-permission.ts)), then per-route `onRequest: verifyAuth([...])` ([secret-router.ts:168](../../backend/src/server/routes/v4/secret-router.ts)).
3. **Schema-first routes** — the Zod type provider turns each route's `schema` into request validation, response serialization, *and* OpenAPI docs (`operationId: "listSecretsV4"` in [secret-router.ts:56](../../backend/src/server/routes/v4/secret-router.ts)). One artifact, three jobs — that's why changing a schema is a public API change.

Sharp edge: plugin *registration order is semantic*. EE routes register before community routes (lines 3572-3573 of [routes/index.ts](../../backend/src/server/routes/index.ts)) so enterprise can shadow community handlers. If you've only used Express, note the difference: Fastify plugins are encapsulated scopes, not global middleware.

## React 18: render vs commit, and where state lives

Mental model: a component is a function that *describes* UI from state; React calls it (render), diffs the result, then touches the DOM (commit). Anything that isn't describing UI — subscriptions, fetches, imperative DOM — belongs in effects or, better, in a library that manages it (React Query here).

Where this repo puts state (the important decision):

| Kind | Lives in | Example |
| --- | --- | --- |
| Server state | React Query cache | `useGetProjectSecrets` ([queries.tsx:139-170](../../frontend/src/hooks/api/secrets/queries.tsx)) |
| Global app context | React Context providers | Org/Project/Permission contexts in [frontend/src/context/](../../frontend/src/context/) |
| Local UI state | `useState` / Zustand | popovers, filters inside pages |
| URL state | TanStack Router search params, Zod-validated | route definitions in page `route.tsx` files |

The senior insight juniors miss: **server state is not app state.** Copying query data into `useState` creates a second source of truth that immediately starts drifting. This repo's pages read query results directly and reshape via `select` ([queries.tsx:168](../../frontend/src/hooks/api/secrets/queries.tsx)).

Stale closure, the classic: an effect or callback captures an old value of a variable. React Query's design dodges most of these by making the query key the dependency: change `{projectId, environment, secretPath}` and it's a *different query*, no manual effect bookkeeping ([queries.tsx:160-166](../../frontend/src/hooks/api/secrets/queries.tsx)).

Sharp edge in this repo: [OverviewPage.tsx](../../frontend/src/pages/secret-manager/OverviewPage/OverviewPage.tsx) is 3,759 lines. Big page components are where render performance and reasoning both die — see the refactor kata in [06-contribution-practice/04](../06-contribution-practice/04-refactor-and-design-katas.md).

## TanStack Query: cache as the contract

Mental model: the cache is a normalized map from *query key* → data + freshness. Everything follows:

- **Keys are identity.** `secretKeys.getProjectSecret({projectId, environment, secretPath, viewSecretValue})` ([queries.tsx:33-41](../../frontend/src/hooks/api/secrets/queries.tsx)) — omit a param from the key and two different screens share (corrupt) data.
- **Freshness is policy.** Global `staleTime: 60_000`, `refetchOnWindowFocus: false`, `retry: 1` ([reactQuery.tsx:222-224](../../frontend/src/hooks/api/reactQuery.tsx)); real-time data overrides with `staleTime: 0`.
- **Writes must invalidate.** `useCreateSecretV3` invalidates nine key families ([mutations.tsx:58-86](../../frontend/src/hooks/api/secrets/mutations.tsx)) — dashboards, imports, snapshots, commits, approval counts. Forgetting one is the repo's most likely UI-bug class.

## TanStack Router: routes as data

Routes are declared in a typed DSL in [routes.ts](../../frontend/src/routes.ts) (see `middleware()` helper at lines 3-4 wrapping auth/org guards) and compiled into `routeTree.gen.ts` (generated — never hand-edit). Route-level `beforeLoad` middleware replaces ad-hoc "redirect if not logged in" effects; search params are Zod-validated so URL state is typed like everything else.

## Drills

1. Predict, then verify: which query keys must `useUpdateSecretV3` invalidate that `useCreateSecretV3` doesn't? Compare in [mutations.tsx](../../frontend/src/hooks/api/secrets/mutations.tsx).
2. Find one Context provider in [frontend/src/context/](../../frontend/src/context/) that uses `staleTime: Infinity` and argue why that's correct for its data.
3. In `routes.ts`, trace which middlewares wrap the secret-manager overview page and what each guards.

## Interview angle

- "How do you manage server state in React?" → query-key factories, staleTime policy, invalidation-on-write, with the nine-invalidation example. ([08-interview-prep/02](../08-interview-prep/02-frontend-framework-questions.md) Q1–Q4)
- "What's wrong with fetching in useEffect + setState?" → duplicated source of truth, no dedupe/caching/retry; contrast with this repo's layer.
- "Fastify vs Express?" → schema-first validation + serialization, encapsulated plugins, decoration; cite the route shape. (08-prep/03 covers API design.)
- "How do you keep UI in sync after a mutation?" → invalidation lists; mention the alternative (optimistic updates) and when it's worth the complexity.
