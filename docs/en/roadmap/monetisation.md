# Monetization for instance holders

## Main points

1. Turned on and off with a flag
1. Monetization based on cryptocurrencies and the Telegram wallet
1. The money goes to the holder of the Instance on which monetization is enabled, since running an instance is not an easy task
1. In the future there may be a feature which, when enabled, sends money also to the creators of Pepeunit to a wallet, but spending from this wallet will be regulated. It is assumed that this feature will be provided under a special license, or will be a separate microservice altogether
1. 100% unit test coverage for the money code
1. 100% integration test coverage for the money code

## Monetization mechanism

The instance status is in [federation](/roadmap/federation). The counters are in [MessageProcessor](/roadmap/message-processor).

Monetization is enabled only if the instance status is Yellow. All Unit are colored by their statistics:
1. Green - resource consumption below the 50th percentile, low resource consumption, works for free - monetization is not required
1. Yellow - resource consumption above the 50th percentile but below the 80th percentile
1. Red - resource consumption above the 80th percentile

Yellow and Red statuses spend the internal currency, the amount is deducted from the internal account every hour. When the amount runs out, the Unit is stopped.

User balance:
1. Free tokens, credited on the first day of every month in the amount set by the admin, do not accumulate
1. Tokens topped up with crypto; the free tokens are spent first, and if they are not enough, the tokens honestly earned by the user start being deducted

Admin capabilities:
1. Setting the percentiles of yellow, green and red Unit
1. The size of the monthly allowance for users
1. A faucet for adding money to the account of everyone or of specific users
1. Setting the price in the yellow and red percentile - in different regions, people have different purchasing power, ping is an important parameter after all, so there will be regionality

## Parameters

All monetization parameters and statuses must be included in the basic parameters of the instance, so that people can choose

## Grafana board
A publicly available monetization board on every instance, how much money came into the instance and how much was spent, over a certain time

## Average message load values for repo registry

This parameter must be added to the registry, without fail. It is desirable to show on the instance how much this or that registry will cost

## Why is monetization needed at all?

Monetization is the only way that is fair to users to give them access to the limited resources of instances. In essence, it is a publicly known rule by which Unit will be switched off when Instances are overloaded.

At the same time, users will be able to bring their Unit back into operation, also by publicly known rules. The money from monetization goes to the Instance holders, which lets them have a financial cushion for running the instances

The more popular an instance is, the harder it is to maintain, and the more funds the person who maintains it must have
