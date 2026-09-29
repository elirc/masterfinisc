## Story 1: Clarify Empty Secret Value Display
**Difficulty:** Easy
**Estimated Time:** 1 hour
**Skills You'll Practice:** reading component state, small UI copy, permission-aware display
**The Story:** As a project member, I want empty secret values to be visually clear so that I do not confuse hidden values with blank values.
**Acceptance Criteria:**
- [ ] Empty visible values render with a distinct text label.
- [ ] Hidden secret values still use the existing hidden-value behavior.
- [ ] No backend files are changed.
**Files You'll Likely Touch:** `frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretItem.tsx` because it derives default secret values [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretItem.tsx:185-207].
**High-Level Implementation Plan:**
1. Inspect `getDefaultValue` in `SecretItem.tsx` and identify hidden versus empty cases.
2. Add a display-only branch for empty visible values.
3. Confirm the branch does not affect submitted form values.
**Tips:**
- Keep `secretValueHidden` behavior intact [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretItem.tsx:185-207].
- Do not change `HIDDEN_SECRET_VALUE` semantics [frontend/src/hooks/api/secrets/queries.tsx:89-94].
- Treat this as display, not persistence.
**What Could Go Wrong:**
- Hidden values look blank if you ignore `secretValueHidden`.
- Empty labels get submitted as actual secret values if you alter form data instead of render text.
**Stretch Goal:** Add a tooltip explaining the empty value state.
**Connects To:** Story 2, because both are safe UI changes inside secret rows.

## Story 2: Add A Secret Row Metadata Count
**Difficulty:** Easy
**Estimated Time:** 1.5 hours
**Skills You'll Practice:** props, arrays, conditional rendering
**The Story:** As a project member, I want to see how many metadata fields a secret has so that I can quickly spot richly annotated secrets.
**Acceptance Criteria:**
- [ ] Each secret row can show a count when `secretMetadata` exists.
- [ ] Secrets with no metadata do not show a misleading count.
- [ ] Existing edit behavior remains unchanged.
**Files You'll Likely Touch:** `frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretItem.tsx` because row form/render logic owns per-secret presentation [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretItem.tsx:209-297].
**High-Level Implementation Plan:**
1. Find where row badges or secondary labels render in `SecretItem.tsx`.
2. Read `secret.secretMetadata` from the existing normalized secret object.
3. Render a small count only when length is greater than zero.
**Tips:**
- `secretMetadata` exists on `SecretV3RawSanitized` [frontend/src/hooks/api/secrets/types.ts:21-54].
- The raw-to-sanitized transform preserves metadata [frontend/src/hooks/api/secrets/queries.tsx:89-111].
- Avoid recalculating metadata from API raw fields in the component.
**What Could Go Wrong:**
- Rendering `0` everywhere adds noise.
- Editing metadata could appear stale if you read from the wrong object.
**Stretch Goal:** Show encrypted metadata count separately if `isEncrypted` exists.
**Connects To:** Story 3, because it also touches typed secret shape.

## Story 3: Add Secret Reminder Indicator Copy
**Difficulty:** Easy
**Estimated Time:** 2 hours
**Skills You'll Practice:** TypeScript fields, UI conditions, domain vocabulary
**The Story:** As a project member, I want a clearer reminder indicator so that I know which secrets need future attention.
**Acceptance Criteria:**
- [ ] Secrets with `reminderRepeatDays` or `reminder` display an indicator.
- [ ] Secrets without reminders are unchanged.
- [ ] No new API request is introduced.
**Files You'll Likely Touch:** `frontend/src/hooks/api/secrets/types.ts` for field awareness [frontend/src/hooks/api/secrets/types.ts:21-54]; `SecretItem.tsx` for display [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretItem.tsx:209-297].
**High-Level Implementation Plan:**
1. Confirm reminder fields on `SecretV3RawSanitized`.
2. Locate existing per-row action/status area.
3. Add conditional reminder indicator.
**Tips:**
- Reminder fields already flow from raw to sanitized [frontend/src/hooks/api/secrets/queries.tsx:97-110].
- Do not add a new query; the data is already in the row.
- Keep display small because secret rows are dense.
**What Could Go Wrong:**
- You display reminders for hidden or inaccessible secrets without checking available fields.
- You confuse repeat days with a scheduled reminder object.
**Stretch Goal:** Add a relative phrase like "Repeats every N days" when safe.
**Connects To:** Story 4, because the next story reads existing aggregate data.

## Story 4: Add A Metadata Filter Summary To The Dashboard
**Difficulty:** Medium
**Estimated Time:** 3 hours
**Skills You'll Practice:** query params, filter state, derived UI
**The Story:** As a project member, I want a compact summary of active filters so that I know why the secret list looks narrowed.
**Acceptance Criteria:**
- [ ] Active search, tag, and resource-type filters are summarized near the dashboard controls.
- [ ] Resetting filters clears the summary.
- [ ] The summary reflects URL query params on page load.
**Files You'll Likely Touch:** `SecretDashboardPage.tsx` for filter state and reset [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:250-286], [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:691-694]; possibly a new small component under `components/`.
**High-Level Implementation Plan:**
1. Read `getFilterStateFromQueryParams`.
2. Create a derived summary from `filter.tags`, `filter.searchFilter`, and `filter.include`.
3. Render summary close to existing filter controls.
4. Ensure `handleResetFilter` clears it.
**Tips:**
- URL state is parsed into `Filter` [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:250-286].
- Search is debounced separately [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:285-286].
- Keep summary derived, not separately stored.
**What Could Go Wrong:**
- Summary drifts if you add separate state.
- Query-param-loaded filters are missed if you only watch user actions.
**Stretch Goal:** Make each summary chip removable.
**Connects To:** Story 5, because both improve existing dashboard data visibility.

## Story 5: Show Pending Change Counts By Type
**Difficulty:** Medium
**Estimated Time:** 3 hours
**Skills You'll Practice:** Zustand selectors, derived counts, batch mode UX
**The Story:** As a project member using batch mode, I want to see how many pending creates, updates, and deletes I have so that I can review before committing.
**Acceptance Criteria:**
- [ ] Pending secret creates, updates, and deletes are counted separately.
- [ ] Pending folder creates, updates, and deletes are counted separately.
- [ ] Counts update as pending changes are added or reverted.
**Files You'll Likely Touch:** `SecretMainPage.store.tsx` for pending type definitions [frontend/src/pages/secret-manager/SecretDashboardPage/SecretMainPage.store.tsx:21-108]; `SecretDashboardPage.tsx` for commit UI area [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:1115-1123].
**High-Level Implementation Plan:**
1. Use `useBatchMode` to read `pendingChanges`.
2. Derive counts by `PendingAction`.
3. Render counts near `CommitForm`.
4. Verify counts change when changes are merged/reverted.
**Tips:**
- `PendingAction` is already used in merge logic [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:710-779].
- Avoid mutating `pendingChanges`.
- Counts should disappear when there are no pending changes.
**What Could Go Wrong:**
- Counting pending updates that were reverted if cleanup removes them [frontend/src/pages/secret-manager/SecretDashboardPage/SecretMainPage.store.tsx:460-477].
- Mixing folder and secret counts.
**Stretch Goal:** Add count badges to commit confirmation.
**Connects To:** Story 6, because the next story adds a new API read path.

## Story 6: Add A Secret By Key Quick Lookup Hook
**Difficulty:** Medium
**Estimated Time:** 4 hours
**Skills You'll Practice:** React Query keys, API hooks, URL encoding
**The Story:** As a project member, I want a reusable hook to fetch one secret by key so that detail views do not need to fetch a whole folder.
**Acceptance Criteria:**
- [ ] New hook fetches `/api/v4/secrets/:secretKey`.
- [ ] Hook accepts `projectId`, `environment`, `secretPath`, `secretKey`, and `viewSecretValue`.
- [ ] Hook uses a stable query key.
- [ ] Hook is disabled until required fields exist.
**Files You'll Likely Touch:** `frontend/src/hooks/api/secrets/queries.tsx` for query-key and fetch patterns [frontend/src/hooks/api/secrets/queries.tsx:33-80]; `frontend/src/hooks/api/secrets/types.ts` for DTO type [frontend/src/hooks/api/secrets/types.ts:128-170].
**High-Level Implementation Plan:**
1. Add a query key factory for secret-by-key.
2. Add a fetcher that calls `/api/v4/secrets/${encodeURIComponent(secretKey)}`.
3. Add a hook wrapping `useQuery`.
4. Export it from `frontend/src/hooks/api/secrets/index.ts`.
**Tips:**
- Follow `fetchProjectSecrets` style [frontend/src/hooks/api/secrets/queries.tsx:60-80].
- Backend supports get-by-name at `/api/v4/secrets/:secretName` [backend/src/server/routes/v4/secret-router.ts:289-400].
- Use `encodeURIComponent`, as mutations do [frontend/src/hooks/api/secrets/mutations.tsx:44-44].
**What Could Go Wrong:**
- Unencoded secret keys break keys with special characters.
- Query runs before `projectId` or `environment` exists.
**Stretch Goal:** Add an option to include imports.
**Connects To:** Story 7, because it builds toward targeted detail features.

## Story 7: Add A Secret Reference Tree Panel
**Difficulty:** Medium
**Estimated Time:** 5 hours
**Skills You'll Practice:** existing endpoints, component composition, loading states
**The Story:** As a project member, I want to inspect a secret's reference tree from the detail sidebar so that I can understand what depends on it.
**Acceptance Criteria:**
- [ ] Detail sidebar can request a secret reference tree.
- [ ] Loading, empty, and error states are shown.
- [ ] The panel uses existing API hooks or adds a hook around existing endpoint.
**Files You'll Likely Touch:** `frontend/src/hooks/api/secrets/queries.tsx` because reference tree hooks exist near [frontend/src/hooks/api/secrets/queries.tsx:332-368]; `SecretDetailSidebar.tsx` because it owns detail display [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:142-245].
**High-Level Implementation Plan:**
1. Inspect existing reference tree query helpers.
2. Add a panel component inside the detail sidebar.
3. Pass `projectId`, `environment`, `secretPath`, and `secretKey`.
4. Render nested nodes safely.
**Tips:**
- Existing route path uses `/api/v4/secrets/:secretKey/secret-reference-tree` [frontend/src/hooks/api/secrets/queries.tsx:332-344].
- Keep the panel lazy or conditional to avoid extra requests for every row.
- Use existing sidebar permission checks as a guide [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:142-245].
**What Could Go Wrong:**
- Fetching trees for every visible secret causes performance issues.
- Secret keys with slashes or spaces fail without encoding.
**Stretch Goal:** Add a "copy reference path" action.
**Connects To:** Story 8, because reference data prepares you for full-stack changes.

## Story 8: Persist A Secret Owner Note
**Difficulty:** Hard
**Estimated Time:** 8 hours
**Skills You'll Practice:** migration, schema generation, backend route schema, frontend types, form update
**The Story:** As a project member, I want to add an owner note to a secret so that teams know who to ask before changing it.
**Acceptance Criteria:**
- [ ] Owner note is persisted with the secret.
- [ ] Owner note appears in the secret detail/sidebar.
- [ ] Create and update flows can save owner note.
- [ ] Existing secret create/update behavior remains compatible.
**Files You'll Likely Touch:** Backend route schema `backend/src/server/routes/v4/secret-router.ts` [backend/src/server/routes/v4/secret-router.ts:423-648]; generated schema after migration `backend/src/db/schemas/secrets.ts` [backend/src/db/schemas/secrets.ts:1-38]; frontend types [frontend/src/hooks/api/secrets/types.ts:21-180]; mutation body [frontend/src/hooks/api/secrets/mutations.tsx:25-130]; row/sidebar UI [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretItem.tsx:209-297].
**High-Level Implementation Plan:**
1. Create a backend migration for nullable owner note.
2. Run migration and regenerate schema.
3. Add route validation/body handling for create and update.
4. Update service DTO/persistence for create/update.
5. Add frontend raw/sanitized fields.
6. Add form input in detail/sidebar or row editor.
7. Verify cache invalidation already covers create/update.
**Tips:**
- Do not hand-edit generated schema except as output from generation [backend/src/db/schemas/secrets.ts:1-4].
- Keep owner note out of audit logs or intentionally mask if sensitive.
- Match existing `secretComment` flow for shape, not blindly for security [backend/src/server/routes/v4/secret-router.ts:436-437].
**What Could Go Wrong:**
- Route accepts field but service drops it.
- Frontend saves field but raw-to-sanitized transform omits it.
- Migration/schema mismatch breaks type-check.
**Stretch Goal:** Add owner note filtering later.
**Connects To:** Story 9, because it practices full-stack persistence before a larger domain workflow.

## Story 9: Add Secret Expiration Status
**Difficulty:** Hard
**Estimated Time:** 10 hours
**Skills You'll Practice:** database field, backend validation, frontend display, audit considerations
**The Story:** As a project member, I want secrets to have an optional expiration date so that risky credentials are rotated or removed on time.
**Acceptance Criteria:**
- [ ] A secret can store an optional expiration date.
- [ ] Expired secrets render with a clear status.
- [ ] Upcoming expirations render differently from non-expiring secrets.
- [ ] Create/update flows can set or clear expiration.
- [ ] Backend validates date shape.
**Files You'll Likely Touch:** Same full-stack path as Story 8 plus any reminder-related UI because reminders already exist [frontend/src/hooks/api/secrets/types.ts:21-82], [backend/src/server/routes/v4/secret-router.ts:423-648], [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretItem.tsx:209-297].
**High-Level Implementation Plan:**
1. Add nullable expiration field through migration and schema generation.
2. Add Zod validation for create/update body.
3. Persist and return expiration from service.
4. Add frontend types and query transformation.
5. Add date input or picker to the secret edit UI.
6. Render expired/upcoming/none status.
**Tips:**
- Compare against existing reminder fields to avoid duplicating concepts [frontend/src/hooks/api/secrets/types.ts:29-31].
- Use ISO strings consistently at API boundary.
- Keep display derived from expiration date, not stored status.
**What Could Go Wrong:**
- Time zone confusion makes a secret appear expired too early.
- Clearing expiration fails if schema treats null/undefined incorrectly.
- Status is not recalculated after update because cache invalidation is incomplete.
**Stretch Goal:** Add dashboard filter for expired secrets.
**Connects To:** Story 10, because expiration naturally leads to caching and performance concerns.

## Story 10: Design A Cached Secret Detail Layer
**Difficulty:** Expert
**Estimated Time:** 14 hours
**Skills You'll Practice:** cache architecture, query key design, auth-sensitive data, performance review
**The Story:** As a project member, I want secret detail panels to load quickly without over-fetching folder data so that large projects remain responsive.
**Acceptance Criteria:**
- [ ] Detail fetches use a scoped query key that includes project, environment, path, key, and visibility options.
- [ ] Opening a detail panel does not refetch the entire dashboard unless mutation invalidation requires it.
- [ ] Hidden-value permissions are respected.
- [ ] Create/update/delete invalidation keeps detail data correct.
- [ ] Design notes explain cache invalidation and security tradeoffs.
**Files You'll Likely Touch:** `frontend/src/hooks/api/secrets/queries.tsx` for detail query keys [frontend/src/hooks/api/secrets/queries.tsx:33-80]; `frontend/src/hooks/api/secrets/mutations.tsx` for invalidation [frontend/src/hooks/api/secrets/mutations.tsx:57-210]; `SecretDetailSidebar.tsx` for detail rendering [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:142-245]; backend get-by-name route for contract verification [backend/src/server/routes/v4/secret-router.ts:289-400].
**High-Level Implementation Plan:**
1. Build or reuse the Story 6 single-secret hook.
2. Add detail-panel integration that fetches only when opened.
3. Add cache key that separates visible and hidden values.
4. Update mutation invalidation to include detail keys for affected secret.
5. Verify permission-hidden values never become cached as visible values for unauthorized views.
6. Write design notes in this story branch's PR description.
**Tips:**
- Existing raw secret key includes `viewSecretValue` for cache separation [frontend/src/hooks/api/secrets/queries.tsx:33-42].
- Axios refresh and auth are shared; do not implement token logic in the hook [frontend/src/config/request.ts:22-130].
- Backend get-by-name already supports `viewSecretValue` and auth modes [backend/src/server/routes/v4/secret-router.ts:289-400].
**What Could Go Wrong:**
- Cache key omits `viewSecretValue`, causing hidden/visible data confusion.
- Detail cache stays stale after update if invalidation only targets dashboard keys.
- Opening many panels triggers too many requests without lazy loading.
**Stretch Goal:** Prefetch detail on row hover only after measuring impact.
**Connects To:** This is the capstone; it prepares you to design future performance-sensitive features.

