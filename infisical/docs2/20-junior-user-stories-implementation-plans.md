# 20 Junior Engineer User Stories With Senior Implementation Plans

This document is written as a product owner/product manager assigning real tickets to a junior engineer, followed by senior-engineer implementation guidance. The stories stay centered on the Infisical secret-management experience because that path is already well represented in the codebase: the dashboard page coordinates route/search state and permission-gated queries [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:105-360], the route validates search parameters [frontend/src/pages/secret-manager/SecretDashboardPage/route.tsx:10-23], the secret list owns row-level CRUD operations [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretListView.tsx:79-199], the frontend API layer owns secret query/mutation hooks [frontend/src/hooks/api/secrets/queries.tsx:33-80], [frontend/src/hooks/api/secrets/mutations.tsx:25-210], and the backend v4 secrets router validates/authenticates secret read/write operations [backend/src/server/routes/v4/secret-router.ts:47-248], [backend/src/server/routes/v4/secret-router.ts:404-730].

Use these stories as implementation assignments. A junior engineer should not code all 20 at once. Pick one, open the files named in the plan, trace the existing pattern, implement the smallest coherent change, and run focused checks.

## Shared Orientation Before Any Story

Before starting any ticket, trace these files once:

1. `frontend/src/pages/secret-manager/SecretDashboardPage/route.tsx`  
   This is where the secrets page URL validates search fields like `secretPath`, `search`, `tags`, and `filterBy` [frontend/src/pages/secret-manager/SecretDashboardPage/route.tsx:10-23].

2. `frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx`  
   This is the page coordinator. It reads org/project/env route state [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:105-160], computes permissions [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:194-248], fetches dashboard data [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:307-360], merges pending changes [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:696-839], and renders resource sections [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:1057-1124].

3. `frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretListView.tsx`  
   This owns row-level create/update/delete calls, pending-change navigation blocking, and the detail sidebar wiring [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretListView.tsx:79-103], [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretListView.tsx:110-199], [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretListView.tsx:658-678].

4. `frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx`  
   This owns detail-drawer form state, lazy secret-value fetching, secret versions, access lists, reference-tree modal, and redaction actions [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:90-148], [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:282-289], [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:352-375], [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:776-812].

5. `frontend/src/hooks/api/secrets/queries.tsx` and `frontend/src/hooks/api/secrets/mutations.tsx`  
   Query keys, fetchers, and mutations live here [frontend/src/hooks/api/secrets/queries.tsx:33-80], [frontend/src/hooks/api/secrets/mutations.tsx:25-210].

6. `backend/src/server/routes/v4/secret-router.ts`  
   The v4 raw secrets API validates read, create, and update contracts and calls the secret service [backend/src/server/routes/v4/secret-router.ts:47-248], [backend/src/server/routes/v4/secret-router.ts:404-730].

## Story 1: Empty Secret Value Should Not Look Like A Loading Failure

**PM Assignment:** As a project member, I want empty visible secret values to have a clear visual state so I can distinguish "blank on purpose" from "hidden" or "failed to load."

**Acceptance Criteria:**
- Empty visible values show a clear placeholder such as "Empty value".
- Hidden values still use the current hidden-value behavior.
- Failed value loads still show the existing error state.
- No API or backend files change.

**Senior Implementation Plan:**

1. Start in `SecretItem.tsx`, because row form defaults are derived there. Read `getDefaultValue`, `getOverrideDefaultValue`, and the form initialization around [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretItem.tsx:185-231].
2. Identify the three cases already handled: loading, hidden, and error. Preserve those branches exactly.
3. Add a display-only helper near the render section, not inside the submitted form value. The key lesson: do not write `"Empty value"` into `value` because that would become a real secret value on save.
4. Find the JSX where the value field or value display is rendered in `SecretItem.tsx`; add the placeholder only when `secret.value === ""` or the watched value is empty and `secret.secretValueHidden` is false.
5. Manual verification path: open a visible empty secret row, a hidden secret row, and a row that still uses `HIDDEN_SECRET_VALUE`; verify they look different. `HIDDEN_SECRET_VALUE` is assigned when a hidden raw value is normalized [frontend/src/hooks/api/secrets/queries.tsx:89-94].
6. Run `cd frontend && npm run type:check` because this is a frontend-only TypeScript change [frontend/package.json:11-14].

**Likely Files:** `frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretItem.tsx`.

## Story 2: Show A Metadata Count On Each Secret Row

**PM Assignment:** As a project member, I want to see how many metadata fields a secret has so I can quickly identify secrets with operational context.

**Acceptance Criteria:**
- A secret with metadata shows a compact count.
- A secret with no metadata shows no count.
- The count updates after edits without a full browser refresh.

**Senior Implementation Plan:**

1. Confirm the normalized secret shape includes `secretMetadata` [frontend/src/hooks/api/secrets/types.ts:21-54].
2. Confirm the raw-to-sanitized transform preserves `secretMetadata` [frontend/src/hooks/api/secrets/queries.tsx:88-111].
3. In `SecretItem.tsx`, find where tags, action icons, or secondary row metadata are rendered. Use that existing style rather than introducing a new visual language.
4. Calculate `const metadataCount = secret.secretMetadata?.length ?? 0`.
5. Render only when `metadataCount > 0`.
6. Verify that metadata edits in the detail sidebar still flow into row state. The sidebar uses a `useFieldArray` named `secretMetadata` [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:230-233].
7. Run `cd frontend && npm run type:check`.

**Likely Files:** `frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretItem.tsx`; possibly `frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx` if the count needs a shared formatter.

## Story 3: Add A Clear Reminder Indicator To Secret Rows

**PM Assignment:** As a project member, I want secrets with reminders to show a small indicator so I know which credentials need future follow-up.

**Acceptance Criteria:**
- Secrets with reminder fields show a reminder indicator.
- Secrets without reminders are unchanged.
- Indicator does not block editing, copying, or opening the detail sidebar.

**Senior Implementation Plan:**

1. Inspect reminder fields on `SecretV3RawSanitized`: `reminderRepeatDays`, `reminderNote`, `reminderRecipients`, and `reminder` [frontend/src/hooks/api/secrets/types.ts:21-54].
2. Verify the API normalization maps reminder fields from raw secret data [frontend/src/hooks/api/secrets/queries.tsx:96-110].
3. Open `SecretItem.tsx`; it already imports and uses `CreateReminderForm`, so stay in the existing reminder area rather than creating a separate concept [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretItem.tsx:55-55], [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretItem.tsx:617-617].
4. Add a boolean such as `const hasReminder = Boolean(secret.reminder || secret.reminderRepeatDays || secret.reminderNote)`.
5. Render a small indicator near existing row controls.
6. Confirm the indicator respects read-only or managed secrets by not adding any new action unless existing reminder actions allow it.
7. Run frontend type-check.

**Likely Files:** `frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretItem.tsx`.

## Story 4: Add Active Filter Summary Chips

**PM Assignment:** As a project member, I want to see a summary of active filters so I understand why the dashboard list is narrowed.

**Acceptance Criteria:**
- Search text, selected tags, and selected resource-type filters appear as summary chips.
- The summary initializes correctly from URL search params.
- Resetting filters clears the summary.

**Senior Implementation Plan:**

1. Read the route search schema. `search`, `tags`, and `filterBy` are validated in the route file [frontend/src/pages/secret-manager/SecretDashboardPage/route.tsx:10-18].
2. Read `getFilterStateFromQueryParams`, which converts URL search state into `Filter` state [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:250-286].
3. Read `handleResetFilter`, which currently resets filter state and search [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:691-694].
4. Create a small component under `frontend/src/pages/secret-manager/SecretDashboardPage/components/`, for example `ActiveFilterSummary.tsx`.
5. Props should be plain and easy: `filter`, `onReset`, and optionally `debouncedSearchFilter`. Avoid giving the component route objects.
6. Render summary chips by deriving from `filter.tags`, `filter.searchFilter`, and `filter.include`.
7. Mount the component in `SecretDashboardPage.tsx` near the existing dashboard controls, not inside a secret row.
8. Verify that loading a URL with `?search=abc&tags=x&filterBy=secret` shows the expected chips.

**Likely Files:** `SecretDashboardPage.tsx`; new `components/ActiveFilterSummary.tsx`; optional component export file if the folder has one.

## Story 5: Make Resource Counts Easier To Understand

**PM Assignment:** As a project member, I want resource counts to explain what they include so I can understand the mix of folders, imports, dynamic secrets, rotations, and static secrets.

**Acceptance Criteria:**
- Count display includes clear labels for each resource type.
- Pending creates are included in the shown count where the dashboard already includes them.
- Empty categories do not add noise.

**Senior Implementation Plan:**

1. Find where `SecretTableResourceCount` is rendered in pagination start adornment [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:1135-1150].
2. Read the count inputs immediately above the render: `totalImportCount`, `totalFolderCount`, `totalDynamicSecretCount`, `totalSecretCount`, `totalSecretRotationCount`, and pending create adjustments [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:345-360], [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:1135-1150].
3. Open the `SecretTableResourceCount` component via its import path from the dashboard [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:72-72].
4. Modify display only. Do not change the totals being passed unless the current component drops required data.
5. Use a small tooltip or label pattern that already exists in the app.
6. Verify that pending secret and folder creates are included, because the dashboard already adds pending creates before passing counts [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:1140-1147].

**Likely Files:** `frontend/src/pages/secret-manager/OverviewPage/components/SecretTableResourceCount` path from import; `SecretDashboardPage.tsx` if props need light reshaping.

## Story 6: Pending Change Counts By Action

**PM Assignment:** As a project member using batch mode, I want to see how many pending creates, updates, and deletes I have before committing.

**Acceptance Criteria:**
- Pending secret creates, updates, and deletes are counted.
- Pending folder creates, updates, and deletes are counted.
- Counts disappear when there are no pending changes.
- Counts update after reverted edits are removed from pending state.

**Senior Implementation Plan:**

1. Read the pending change union types [frontend/src/pages/secret-manager/SecretDashboardPage/SecretMainPage.store.tsx:21-108].
2. Read the pending-change cleanup/merge behavior so you understand why reverted updates may disappear [frontend/src/pages/secret-manager/SecretDashboardPage/SecretMainPage.store.tsx:390-483].
3. In `SecretDashboardPage.tsx`, find where `pendingChanges` is already read [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:128-130].
4. Derive counts with `useMemo` from `pendingChanges.secrets` and `pendingChanges.folders`.
5. Render the count summary next to `CommitForm`, which appears only when pending secret or folder changes exist [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:1115-1123].
6. Keep it presentational. Do not alter pending state in this story.
7. Test manually by creating, editing, deleting, and reverting a pending change.

**Likely Files:** `SecretDashboardPage.tsx`; optional new `PendingChangeSummary.tsx`.

## Story 7: Add A Safer Unsaved Changes Message

**PM Assignment:** As a project member in batch mode, I want the unsaved-changes warning to explain what will be lost so I can make a confident navigation decision.

**Acceptance Criteria:**
- Navigation blocker message mentions pending secret/folder changes.
- Message appears only when pending changes exist.
- Existing blocking behavior remains unchanged.

**Senior Implementation Plan:**

1. Open `SecretListView.tsx`; it already calls `useNavigationBlocker` when pending changes exist [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretListView.tsx:90-103].
2. Read how `pendingChanges` is obtained from `useBatchMode` [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretListView.tsx:90-92].
3. Build a message string from pending counts. Example: "You have 2 pending secret changes and 1 pending folder change."
4. Pass the improved message into `useNavigationBlocker`.
5. Do not change the `shouldBlock` condition unless you find it does not match acceptance criteria.
6. Verify with one pending secret change and one pending folder change.

**Likely Files:** `frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretListView.tsx`.

## Story 8: Add "Copy Current Secret Path" Action

**PM Assignment:** As a project member, I want to copy the current secret path so I can paste it into CLI commands or teammates' instructions.

**Acceptance Criteria:**
- User can copy the current `secretPath`.
- Copy action uses the current path from URL/search state.
- Success notification appears after copy.

**Senior Implementation Plan:**

1. Read how `secretPath` is derived from route search params in `SecretDashboardPage.tsx` [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:157-160].
2. Find the page header and breadcrumb area where path-related actions would make sense [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:849-909].
3. Reuse the app's notification helper if available in this file; `createNotification` is already used for invalid environment navigation [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:291-305].
4. Add a compact icon button near `FolderBreadCrumbs` or the page header. The dashboard renders `FolderBreadCrumbs` and `EnvironmentTabs` together [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:908-909].
5. Use `navigator.clipboard.writeText(secretPath)` and handle failure with an error notification.
6. Verify root path `/` and nested paths.

**Likely Files:** `SecretDashboardPage.tsx`; possibly a new small `CopySecretPathButton.tsx`.

## Story 9: Improve No-Access Secret Explanation

**PM Assignment:** As a project member, I want no-access secret rows to explain why I cannot see them so I know whether to request access.

**Acceptance Criteria:**
- If `noAccessSecretCount > 0`, the UI explains that some secrets exist but cannot be read.
- Existing `SecretNoAccessListView` remains the display owner or is extended carefully.
- The permission-denied banner behavior is unchanged.

**Senior Implementation Plan:**

1. Locate where `SecretNoAccessListView` renders [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:1124-1124].
2. Locate where the complete permission denied banner renders [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:1127-1130].
3. Open `SecretNoAccessListView` via its import from `components/SecretListView` [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:84-84].
4. Add explanatory copy in `SecretNoAccessListView`, not directly in the page, unless the component is too generic.
5. Confirm that users with no resource access still get `PermissionDeniedBanner`, while users with partial access get the no-access count.
6. Run frontend type-check.

**Likely Files:** `frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/*`; `SecretDashboardPage.tsx` only if props need passing.

## Story 10: Add A Detail Sidebar "Access Summary" Header

**PM Assignment:** As a project member, I want the secret detail sidebar to summarize who can access the secret before listing every entity.

**Acceptance Criteria:**
- Sidebar shows counts for users, identities, and groups with access.
- Counts use the existing access-list query.
- Loading state does not flash misleading zeros.

**Senior Implementation Plan:**

1. Open `SecretDetailSidebar.tsx` and read the access-list hook call [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:289-289].
2. Read the existing access-list render area for users, identities, and groups [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:812-875].
3. Add a summary just above the detailed lists. Use `isPending` to avoid showing zero before data arrives [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:289-289].
4. Derive counts from `secretAccessList.users.length`, `secretAccessList.identities.length`, and `secretAccessList.groups.length`.
5. Keep the detailed list unchanged.
6. Verify with secrets that have different access-list shapes.

**Likely Files:** `frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx`.

## Story 11: Add A Secret Version Count Label

**PM Assignment:** As a project member, I want the detail sidebar to show how many versions are loaded so I understand version history at a glance.

**Acceptance Criteria:**
- Version count appears near the version history section.
- Count is based on the existing version query response.
- Empty or loading states are clear.

**Senior Implementation Plan:**

1. In `SecretDetailSidebar.tsx`, read the `useGetSecretVersion` call [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:282-282].
2. Find where `SecretVersionItem` is rendered [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:776-782].
3. Inspect the version query hook signature in `frontend/src/hooks/api/secrets/queries.tsx` [frontend/src/hooks/api/secrets/queries.tsx:273-273].
4. Add a label like "Versions loaded: N" only when data exists.
5. Do not alter pagination or fetch limits in this junior story.
6. Verify that the count does not show while loading.

**Likely Files:** `SecretDetailSidebar.tsx`.

## Story 12: Add A Secret Reference Tree Entry Point Explanation

**PM Assignment:** As a project member, I want the reference-tree action to explain what it shows so I understand when to use it.

**Acceptance Criteria:**
- Reference-tree button has helpful tooltip or nearby accessible label.
- Existing reference-tree modal still opens.
- No API changes.

**Senior Implementation Plan:**

1. In `SecretDetailSidebar.tsx`, find the popup definitions for `secretReferenceTree` [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:219-223].
2. Read the modal content that renders `SecretReferenceTree` [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:359-375].
3. Find the button that opens the reference tree [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:923-923].
4. Add tooltip copy that says the tree shows references/dependencies for the current secret.
5. Keep the click handler as `handlePopUpOpen("secretReferenceTree", secretKey)`.
6. Verify keyboard focus and hover both reveal usable context if the design system supports it.

**Likely Files:** `SecretDetailSidebar.tsx`.

## Story 13: Add A "Reveal Value On Focus" Hint

**PM Assignment:** As a project member, I want the detail sidebar to tell me that secret values load when focused so I understand why values may initially appear hidden.

**Acceptance Criteria:**
- Hint appears only when the value can be fetched lazily.
- Hint disappears or becomes irrelevant after the value is loaded.
- Hidden/no-permission values do not promise reveal behavior.

**Senior Implementation Plan:**

1. Read lazy value-fetch conditions: `canFetchSecretValue`, `fetchSecretValueParams`, and `useGetSecretValue` with `enabled: canFetchSecretValue && isFieldFocused` [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:110-127].
2. Read `hasFetchedSecretValue` [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:129-130].
3. Add a small hint near the value input when `canFetchSecretValue && !hasFetchedSecretValue`.
4. Do not change the fetch trigger. This story is communication-only.
5. Verify hidden values and empty values do not show an incorrect hint.

**Likely Files:** `SecretDetailSidebar.tsx`.

## Story 14: Make Tag Filter Chips Removable

**PM Assignment:** As a project member, I want to remove one active tag filter at a time so I do not need to reset all filters.

**Acceptance Criteria:**
- Each active tag filter can be removed independently.
- URL search params update after removing a tag.
- Other filters remain untouched.

**Senior Implementation Plan:**

1. Read tag parsing in `getFilterStateFromQueryParams` [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:263-274].
2. Read how `navigate` is created for this page [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:108-110].
3. If Story 4's `ActiveFilterSummary` exists, extend it. Otherwise create it now.
4. Add an `onRemoveTag(tagSlug)` callback in `SecretDashboardPage.tsx`.
5. In that callback, remove the tag from `filter.tags`, update local state, and call `navigate({ search: ... })` to update the URL.
6. Preserve `search` and `filterBy` search params.
7. Verify by loading a URL with multiple tags and removing one.

**Likely Files:** `SecretDashboardPage.tsx`; `ActiveFilterSummary.tsx`.

## Story 15: Add A "Request Access" Context Message

**PM Assignment:** As a project member, I want request-access prompts to explain which permission is missing so I know what I am asking for.

**Acceptance Criteria:**
- Read access prompt explains missing read permission.
- Edit/delete prompt explains missing edit and/or delete permission.
- Existing request-access modal opening remains unchanged.

**Senior Implementation Plan:**

1. Find the read access prompt branch in `SecretDashboardPage.tsx` [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:1021-1026].
2. Find the edit/delete access prompt branch [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:1028-1053].
3. Keep `handlePopUpOpen("requestAccess", ...)` exactly as-is unless the modal contract requires additional data.
4. Update only the surrounding text or add a compact helper line.
5. Verify the arrays passed to request access still include the correct actions [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:1045-1049].
6. Confirm the prompt does not appear for users who have permissions.

**Likely Files:** `SecretDashboardPage.tsx`.

## Story 16: Add A Create Secret Form Helper For Multiline Encoding

**PM Assignment:** As a project member creating a secret, I want helper text around multiline encoding so I know when to enable or skip it.

**Acceptance Criteria:**
- Create secret form explains the multiline encoding option.
- Existing submit behavior is unchanged.
- Batch mode create behavior remains unchanged.

**Senior Implementation Plan:**

1. Open `CreateSecretForm.tsx`; it owns create-secret modal form behavior and calls `useCreateSecretV3` [frontend/src/pages/secret-manager/SecretDashboardPage/components/CreateSecretForm/CreateSecretForm.tsx:49-68].
2. Read the create path for batch mode and normal mode. The form creates `PendingSecretCreate` in batch mode and closes the popup [frontend/src/pages/secret-manager/SecretDashboardPage/components/CreateSecretForm/CreateSecretForm.tsx:97-127].
3. Find the field for `skipMultilineEncoding`.
4. Add helper text near that field. Do not rename the field or change submit payload.
5. Verify normal create still calls `createSecretV3`, and batch mode still adds a pending create.

**Likely Files:** `frontend/src/pages/secret-manager/SecretDashboardPage/components/CreateSecretForm/CreateSecretForm.tsx`.

## Story 17: Add A Create Secret Duplicate-Name Precheck Message

**PM Assignment:** As a project member creating a secret in batch mode, I want clearer duplicate-name feedback so I understand why my new secret was not added.

**Acceptance Criteria:**
- Duplicate secret names in pending state show a clear error.
- Existing duplicate prevention remains intact.
- Message includes the conflicting key name if safe to show.

**Senior Implementation Plan:**

1. Read duplicate-name logic in the page store. Duplicate secret creates are rejected when an existing key or pending effective key conflicts [frontend/src/pages/secret-manager/SecretDashboardPage/SecretMainPage.store.tsx:322-368].
2. Note the current notification text: "A secret with this name already exists" [frontend/src/pages/secret-manager/SecretDashboardPage/SecretMainPage.store.tsx:344-348], [frontend/src/pages/secret-manager/SecretDashboardPage/SecretMainPage.store.tsx:362-367].
3. Update the notification message to include `change.secretKey` or `change.newSecretName` as appropriate.
4. Avoid exposing secret values. Names are already visible in the dashboard path, but values are sensitive.
5. Verify create duplicate and rename duplicate cases.

**Likely Files:** `frontend/src/pages/secret-manager/SecretDashboardPage/SecretMainPage.store.tsx`.

## Story 18: Add A Raw Secret Query Hook For One Secret

**PM Assignment:** As a project member, I want secret detail panels to be able to fetch one secret directly so the UI does not need to depend only on folder-level data.

**Acceptance Criteria:**
- A new hook fetches one secret by key using the existing backend endpoint.
- Query key includes project, environment, path, key, and visibility options.
- Hook is disabled until required fields are present.
- No component uses the hook yet unless paired with a separate story.

**Senior Implementation Plan:**

1. Read existing `secretKeys` query-key factory [frontend/src/hooks/api/secrets/queries.tsx:33-58].
2. Read existing `fetchProjectSecrets` style for `apiRequest.get` [frontend/src/hooks/api/secrets/queries.tsx:60-80].
3. Read backend get-by-name endpoint shape: `GET /api/v4/secrets/:secretName` validates `projectId`, `environment`, `secretPath`, `viewSecretValue`, `expandSecretReferences`, and `includeImports` [backend/src/server/routes/v4/secret-router.ts:289-400].
4. Add a DTO type in `frontend/src/hooks/api/secrets/types.ts`, near existing get-secret DTOs [frontend/src/hooks/api/secrets/types.ts:128-170].
5. Add `secretKeys.getProjectSecretByKey`.
6. Add `fetchProjectSecretByKey` using `encodeURIComponent(secretKey)`, following mutations that already encode keys [frontend/src/hooks/api/secrets/mutations.tsx:44-44].
7. Add `useGetProjectSecretByKey` with `enabled: Boolean(projectId && environment && secretKey)`.
8. Export the hook from the secrets API index.
9. Run frontend type-check.

**Likely Files:** `frontend/src/hooks/api/secrets/types.ts`; `frontend/src/hooks/api/secrets/queries.tsx`; `frontend/src/hooks/api/secrets/index.ts`.

## Story 19: Add A Detail Sidebar Refresh Action

**PM Assignment:** As a project member, I want to manually refresh a secret's detail data so I can confirm I am seeing the latest version after another teammate changes it.

**Acceptance Criteria:**
- Detail sidebar has a refresh action.
- Refresh invalidates or refetches relevant detail/version/access queries.
- Refresh does not refetch the whole dashboard unless necessary.

**Senior Implementation Plan:**

1. Read `SecretDetailSidebar.tsx` imports: it already has `useQueryClient`, `dashboardKeys`, `useGetSecretVersion`, and `useGetSecretAccessList` [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:18-19], [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:57-63].
2. Read version and access-list hook calls [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:282-289].
3. Add an icon button in the sidebar header.
4. In the click handler, invalidate the query keys for version and access list. If a key factory exists for each, use it; do not string-match unless no factory is exposed.
5. If Story 18 has been implemented and the sidebar uses the one-secret hook, invalidate that detail query too.
6. Show a success notification only after invalidation/refetch is triggered, not before.
7. Verify the dashboard list does not unnecessarily refresh.

**Likely Files:** `SecretDetailSidebar.tsx`; possibly `frontend/src/hooks/api/secrets/queries.tsx` if a missing key factory needs export.

## Story 20: Add Secret Owner Note As A Guided Full-Stack Starter

**PM Assignment:** As a project member, I want to store an optional owner note on a secret so my team knows who to contact before editing or deleting it.

**Acceptance Criteria:**
- Owner note can be created, edited, displayed, and cleared.
- Owner note is persisted in the backend.
- Owner note appears in the raw and sanitized frontend secret types.
- Existing secret create/update behavior remains compatible.
- Audit logs do not expose sensitive owner note content unless product explicitly decides it is non-sensitive.

**Senior Implementation Plan:**

1. Treat this as a paired story. A junior can implement it with senior review because it touches database, backend service, API schema, frontend hooks, and UI.
2. Start with the backend route body shape. Create and update bodies currently validate secret value, comment, metadata, tags, reminder fields, and related properties [backend/src/server/routes/v4/secret-router.ts:423-452], [backend/src/server/routes/v4/secret-router.ts:581-614].
3. Add a migration for a nullable owner-note column. Do not manually edit generated schema as the source of truth; generated schemas warn they are generated by automation [backend/src/db/schemas/secrets.ts:1-4].
4. Run the repo's schema generation workflow after migration. Backend docs mention migrations and schema generation commands [backend/CLAUDE.md:29-33].
5. Update service DTO handling in the secret service. Route handlers pass create fields into `createSecretRaw` [backend/src/server/routes/v4/secret-router.ts:464-481] and update fields into `updateSecretRaw` [backend/src/server/routes/v4/secret-router.ts:628-648].
6. Update backend response shaping so owner note returns wherever raw secret data returns. Use the existing raw secret response schema areas as the checklist [backend/src/server/routes/v4/secret-router.ts:140-166], [backend/src/server/routes/v4/secret-router.ts:453-460], [backend/src/server/routes/v4/secret-router.ts:615-623].
7. Decide audit behavior with the product owner. Existing encrypted metadata is masked in audit logs [backend/src/server/routes/v4/secret-router.ts:515-519], [backend/src/server/routes/v4/secret-router.ts:683-687]. If owner note might contain sensitive text, mask it or omit it.
8. Update frontend raw and sanitized types [frontend/src/hooks/api/secrets/types.ts:21-82].
9. Update raw-to-sanitized transformation [frontend/src/hooks/api/secrets/queries.tsx:82-137].
10. Update create and update mutation DTO/body [frontend/src/hooks/api/secrets/mutations.tsx:25-130].
11. Add the owner note field to `CreateSecretForm.tsx` and `SecretDetailSidebar.tsx`. The create form already calls `useCreateSecretV3` [frontend/src/pages/secret-manager/SecretDashboardPage/components/CreateSecretForm/CreateSecretForm.tsx:49-68], and the detail sidebar owns editable form state [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretDetailSidebar.tsx:174-192].
12. Confirm create/update invalidation already refreshes dashboard and raw secret caches [frontend/src/hooks/api/secrets/mutations.tsx:57-86], [frontend/src/hooks/api/secrets/mutations.tsx:131-165].
13. Verification checklist: create with owner note, edit owner note, clear owner note, create without owner note, check list display, check detail display, check audit log does not leak sensitive content.
14. Run `make reviewable-api` and `make reviewable-ui`, which run lint-fix and type-check for backend/frontend [Makefile:22-32].

**Likely Files:** backend migration; `backend/src/server/routes/v4/secret-router.ts`; secret service files under `backend/src/services/secret`; generated schema under `backend/src/db/schemas`; `frontend/src/hooks/api/secrets/types.ts`; `frontend/src/hooks/api/secrets/queries.tsx`; `frontend/src/hooks/api/secrets/mutations.tsx`; `CreateSecretForm.tsx`; `SecretDetailSidebar.tsx`.

## Suggested Assignment Order

Assign these in this order to build confidence without hiding the real codebase:

1. Stories 1-3: row-level display and type awareness.
2. Stories 4-7: dashboard state, filters, pending changes, and navigation safety.
3. Stories 8-13: path actions and detail-sidebar comprehension.
4. Stories 14-17: URL/filter interactions and store-level duplicate handling.
5. Stories 18-19: query-hook architecture and targeted refresh.
6. Story 20: first paired full-stack feature.

## Review Checklist For The Junior Engineer

Before opening a PR, answer these:

1. What route/page owns the user-facing state I changed? Cite the file and lines.
2. What type describes the data I used? For secrets, start with [frontend/src/hooks/api/secrets/types.ts:21-82].
3. Did I alter API behavior or only presentation?
4. If I changed a mutation, did I preserve cache invalidation [frontend/src/hooks/api/secrets/mutations.tsx:57-210]?
5. If I changed backend secret behavior, did I update validation, service handling, response shape, audit behavior, and generated schema paths [backend/src/server/routes/v4/secret-router.ts:404-730]?
6. Did I run the smallest relevant check, usually frontend type-check for UI-only work or `make reviewable-*` for larger work [Makefile:22-32]?

