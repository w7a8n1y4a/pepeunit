# Frontend refactor

## Style update

Migration to shadcn; most likely we will have to write some custom solutions based on shadcn components.

## API re-calls

Find unnecessary repeated calls caused by `useEffect`; in version 0.9.0 similar redundant failing requests were removed. We can add temporary debug logs on the backend that would show more information about the incoming requests.

## Re-renders

Add counters and check the frequency of re-renders. Measure the time of these re-renders: if they are fast, it does not matter; if they are slow, fix them.
