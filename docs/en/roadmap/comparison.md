# Instance comparison system

## Unified parser service

The only task of the service is to parse the state of all instances installed in it and show tables for users explaining what is where and how.

## On the instance side
The system state with settings is exposed via REST and GQL requests with caching and an update every 1 hour.

1. Basic feature flags of the instance.
1. When integration tests last passed.
1. Time of the last backup.
1. > 2.0.0 Monetization parameters and metrics.

## Admin will be able to

1. Trigger integration tests from the frontend; all passwords are generated randomly in this case, overall the tests are restructured to be invoked without checking functionality of private repositories.
1. Create backups with a flag that they are for the whole instance and when this was done.
