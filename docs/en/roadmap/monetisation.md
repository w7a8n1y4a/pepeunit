# Monetization for instance holders

## Main points

1. Enabled and disabled with a flag
1. Monetization based on cryptocurrencies and the instance's Ethereum wallet
1. The money goes to the holder of the Instance on which monetization is enabled
1. 100% unit test coverage for code that handles money
1. 100% integration test coverage for code that handles money

## Why is monetization needed at all?

Monetization is the only way that is fair to users to give them access to the limited resources of instances. It should be understood as a publicly known rule by which Unit are disabled when Instances are overloaded.

Users will also be able to bring their Unit back into operation according to publicly known rules. The money from monetization goes to Instance holders, giving them a financial cushion for running their instances.

The more popular an instance is, the harder it is to maintain, and the more funds the person maintaining it needs.

## Monetization mechanism

The monetization module aims to prevent an instance from going down by responding to new Unit being created or existing Unit consuming more resources. The goal is to keep instance utilization below 90% of capacity, always reserving 10% for spikes from existing Unit. Users will always have an incentive to look for an instance with a lower rate.

[MessageProcessor](/roadmap/message-processor) calculates the following (see [MessageProcessor](/roadmap/message-processor) for calculation details):

1. How many resources each Unit consumes
2. How many resources the instance has in total
3. What percentage of resources is in use

The monetization module automatically calculates the rate based on this data.

The rate is a resource price multiplier for Unit:

- The higher the rate, the more expensive it is to host a Unit on the instance
- The lower the rate, the cheaper it is to host a Unit on the instance

The monetization module aims to prevent an instance from going down by responding to new Unit being created or existing Unit consuming more resources. The goal is to keep instance utilization below 90% of capacity, always reserving 10% for spikes from existing Unit.

- When the instance is empty, the rate is at its minimum. As load from Unit increases, the rate rises.
- When the instance's rate rises quickly, Unit holders receive notifications so they know prices are increasing.
- The rate grows exponentially: as instance utilization approaches 90%, the rate should skyrocket.
- At low utilization, up to approximately 50–60%, the rate remains at its minimum.

## User balance

1. Free tokens are credited daily in an amount set by the Instance Owner
    - A top-up cannot raise the free token balance above the target amount, so free tokens do not accumulate
1. Paid tokens are topped up using crypto; free tokens are spent first, and paid tokens are spent last

## Instance Owner

1. Sets hardware limits:
    - Network bandwidth
    - The machine's monthly traffic limit
1. Sets the daily free token allowance for the entire instance
1. Can grant tokens at their discretion
1. Sets the instance wallet address
1. Sets the instance's base price
    - For example, $200 means that at N% utilization, the Owner expects to receive 200 USDT
    - There will be no other pricing parameters, to avoid overloading the Owner with settings
1. Schedules downtime with alerts for users
1. Can increase the number of Ethereum nodes

## MessageProcessor changes

- When a user runs out of tokens, message forwarding for their Unit is suspended

## Wishlist

- A publicly available monetization dashboard on every instance showing how much money came in and how much was spent over a specified period
- A repo hosting cost metric so users can estimate the cost of hosting a particular repo
- Expose monetization parameters in /instences/current
- Rate forecasts for an hour, a week and a month
