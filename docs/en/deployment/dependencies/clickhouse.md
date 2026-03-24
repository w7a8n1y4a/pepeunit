# ClickHouse

:::danger
The standard `ClickHouse` container does not run on all `arm` systems, as it requires `ARMv8.2-A` instructions. Because of this, [Pepeunit](/en/conception/overview) cannot be launched on `rpi` series devices version `4` and below.

An alternative container based on the binary version of `ClickHouse` is being developed to support `rpi3b+` and above.
:::

[ClickHouse](https://clickhouse.com/) is an open-source column-oriented analytical DBMS that allows you to run analytical queries on structured data using [SQL](/en/definitions#sql). [More about environment variables](/en/deployment/env-variables/clickhouse)

::::info
[Backend](/en/deployment/dependencies/backend) stores the following information in ClickHouse:
1. [Unit](/en/definitions#unit) logs
1. [DataPipe](/en/deployment/dependencies/datapipe) data
::::

