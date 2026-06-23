# Instance comparison system

The system's goal is to give users a place on each instance where they can understand the state of the Pepeunit network.

## Unified parser service

1. The service polls all instances it knows about for their state.
1. The service goes through all available instances within 1 hour, distributing requests evenly.
1. When returning data, it should return an increment for 3 hours; if it returns everything at once, it should at least have a large per-IP limit.
1. Approximate geolocation, ping, etc. are determined by IP.
1. Items are added manually.
1. Data from the parser service is cached once per hour.

## Data generation for the parser
1. `domain.com/pepeunit` endpoint: system state with settings is returned through REST and GQL requests with caching and an update once per hour.
1. GQL and REST endpoints return a paginated list of domains known to the instance.

Data includes:
1. Basic instance feature flags.
1. Basic instance settings.
1. When integration tests last passed and their result.
1. Instance statistics.
1. Instance owner contacts.
1. Remove the author field, it has become redundant information.

## Admin will be able to

1. Trigger integration tests from the frontend; all passwords are generated randomly, and overall the tests are restructured so they can run without checking private repository functionality, through a special flag. Tests must take feature flags into account.
1. Use a button for forced scanning of external instances; it goes through all domains separately and updates information.
1. Use a button for forced scanning of a specific instance.
1. Use a button that asks other instances for their list of domains, allowing domain lists to be synchronized across instances.
1. In general, all routine tasks should report their execution more clearly. I think we can create a database table with the latest execution status of all main routine tasks.
1. Maintain blacklists and whitelists.

## Implementation

An `instances` table is needed to store all available instances:
- Instance domain.
- Instance IP address.
- Ping.
- Geolocation information.
- Information collection time.
- Cumulative counter for successful data collections.
- Latest collection status.
- Collection error, if any.
- Store complete JSON responses and work by schema versions to achieve compatibility between different instances. Each subsequent version will know the nuances of previous ones.

1. The integration testing concept will need to be fully rebuilt.
1. Config fact-checking is needed on startup for some variables, for example owner contacts.

### Frontend or Grafana, needs thought

1. A map with server geolocations is shown.
1. A table with sorting by all parameters.
