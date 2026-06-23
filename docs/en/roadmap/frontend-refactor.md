# Frontend refactor

## Style update

Migration to shadcn. Most likely, some custom solutions based on shadcn components will need to be written somewhere.

## API re-calls

Find unnecessary repeated calls caused by `useEffect`. In version 0.9.0, similar unnecessary failing requests were removed. Temporary debug comments can be added on the backend to show more information about incoming requests.

## Re-renders

Add counters and check the frequency of re-renders. Measure how long these re-renders take: if they are fast, it does not matter; if they are slow, fix them.
