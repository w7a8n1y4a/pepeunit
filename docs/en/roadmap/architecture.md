# Architecture refactoring

Goals:

- Prepare the backend for a rewrite in a compiled language.
- Make the backend as consistent and easy to read as possible.

## Planned changes

1. Use Cases — replace large service-layer classes and make the overall logic easier to read by introducing a consistent unit of application logic.
1. DDD — organize domain rules more logically.
1. Clean Architecture — make the main abstraction layers independent so they can be changed separately.
1. Integration tests — stop calling the service layer directly and exercise the REST API with simulated Units instead.
1. Module tests — increase coverage as much as possible.
