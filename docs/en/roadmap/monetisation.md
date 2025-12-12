# Monetization for instance owners

## Main problem

Load tracking — there are topics without the `/pepeunit` prefix that also consume EMQX bandwidth. While it is still possible to determine and calculate the data volume in DataPipe for all users' Units, tracking how much bandwidth is occupied is very difficult.

EMQX allows such tracking only in the paid version, which does not fit the project concept.

Apparently we will need to create another Go service.

:::danger
Until this problem is solved, the following items basically do not make sense.
:::

## Key points

1. Enabled/disabled via a flag.
1. Monetization based on cryptocurrencies and a Telegram wallet.
1. Money goes to the owner of the instance where monetization is enabled, because running an instance is not a trivial task.
1. In the future there may be functionality where, if enabled, part of the money also goes to the Pepeunit creators' wallet, but spending from this wallet will be regulated. It is implied that this functionality will be provided under a special license or even as a separate microservice.
1. 100% unit test coverage for money-related code.
1. 100% integration test coverage for money-related code.

## Monetization mechanism

Required data:

1. For each Unit, an array of the average number of messages is calculated: `[month, week, day, hour]`.
1. For each Unit, memory dynamics in DataPipe is calculated.
1. Capabilities of the system as a whole: how much persistent storage there is, how much CPU, RAM, etc. is available — also in the `[month, week, day, hour]` format.

Every hour the mechanism calculates the total load from Units and compares it with the system load metrics. Based on this it calculates the status of the instance:
1. Green — available for creating Units.
1. Yellow — the system is on the verge of throttling, for example less than 10% of resources remain.
1. Red — the system is throttling, some Units are forcibly disabled. Unit tokens gain the ability to be temporarily blocked; throttling of the system is returned as an error.

Monetization is built on the instance status; it is enabled only if the instance status is Yellow. All Units are colored according to their statistics:
1. Green — resource consumption is below the 50th percentile, low resource consumption, works for free — monetization is not required.
1. Yellow — resource consumption is above the 50th percentile but below the 80th percentile.
1. Red — resource consumption is above the 80th percentile.

Yellow and Red statuses spend internal currency; an amount is debited from the internal account every hour. When the balance is exhausted, the Unit stops.

User balance:
1. Free tokens, credited on the first day of each month in an amount set by the admin, do not accumulate.
1. Refillable tokens via crypto; free tokens are spent first, if they are insufficient, the honestly earned tokens of the user start to be debited.

Admin capabilities:
1. Configure percentiles for Yellow, Green and Red Units.
1. Amount of the monthly allowance for users.
1. Faucet for adding money to the balance for all or specific users.
1. Set prices for Yellow and Red percentiles — in different regions people have different affordable prices, ping is still an important parameter, so there will be regionality.

## Parameters

All monetization parameters and statuses must be included in the basic parameters about an instance so that people can choose.

## Grafana board

Publicly available monetization board on each instance showing how much each user is spending.

## Average message load values for repo registry

This parameter must be added to the registry, mandatory. Ideally, the instance should highlight how much a particular registry will cost.

## Why is monetization needed at all?

Monetization is the only way that is fair to users to give them access to the limited resources of instances. Essentially it is a well-known rule by which Units will be disabled when instances are overloaded.

At the same time, users will have the option to bring their Units back into operation, again under clearly understood rules. Instance owners receive the money from monetization, which will allow them to have a financial cushion to run their instances.

The more popular an instance, the harder it is to maintain and the more funds its maintainer must have.
