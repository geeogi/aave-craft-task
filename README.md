# Aave Take Home Test - Aave V3 & V4 User Analytics Dashboard

The dashboard is located here: https://dune.com/geeogi_team/aave-v3-to-v4

Much of the thought processes and definitions are written into the dashboard and are not duplicated here.

# Approach and how you structured the analysis

I chose to focus on Aave V3 Ethereum (as opposed to other V3 markets) in order to narrow the scope of this task. Also, the V3 Ethereum market is probably the most relevant for understanding the growth of V4, given that it is the largest and most successful DeFi lending market, on the same chain as V4 and with a similar brand positioning.

I chose to focus on supplied asset balances (as opposed to volumes, borrows, risk) in order to narrow the scope of this task. Supplies are the most relevant metric because every user must have a supplied balance and long asset exposure is an important aspect of the user profile.

The source queries aim to standardise the balance of supplied assets per-user per-week across V3 and V4. Care was taken to ensure balances are tracked through time with precision using shares:amount ratios. Materialised views were used to improve query speeds. This is the base dataset from which all views are generated.

To generate confidence in the base dataset the following sanity checks were made: Compare total V3/V4 supplied balances against app.aave.com and pro.aave.com, compare individual V3 aToken balances against Etherscan, compare individual V4 balances against aave.tokenlogic.xyz, compare the V4 total supplied balance through time on pro.aave.com.

# Assumptions made

The term "user" is often used where specifically this means an Ethereum address. Retention metrics focus on users with a balance above $100 - this is likely the minimum amount for which the protocol could be useful but it includes many dust users.

# Tradeoffs or unfinished work

Our V3 balance histories reflect only a limited number of assets i.e. not every V3 supplied asset is tracked. I chose the top assets which reflect 92%+ of the current V3 balance sheet. This tradeoff was made to improve query speed and increase confidence in the base dataset.

# What you would improve next with more time

Increase confidence in the base dataset with more sanity checking e.g. RPC lookup.

Improve the structure of this repo using the Dune Analytics API to update queries programmatically.

Experiment with longer running retention views to understand if this metric can be more useful. Experiment with retention metrics using a higher balance threshold than $100.

Idea that I didn't get a chance to try: identify and aggregate the collateral-debt mix of V4 users to identify which strategies are growing. For example, SUPPLY-wstETH-BORROW-ETH and SUPPLY-USDG are two strategies on V4. By identifying the growing stragegies we could understand which user profiles are growing on V4 and also compare the profitability of these strategies to V3.
