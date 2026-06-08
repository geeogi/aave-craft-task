table: aave_v3_ethereum.pool_evt_supply
schema:
| name | type |
| --- | --- |
| contract_address | varbinary |
| evt_tx_hash | varbinary |
| evt_tx_from | varbinary |
| evt_tx_to | varbinary |
| evt_tx_index | integer |
| evt_index | bigint |
| evt_block_time | timestamp |
| evt_block_number | bigint |
| evt_block_date | date |
| amount | uint256 |
| onBehalfOf | varbinary |
| referralCode | integer |
| reserve | varbinary |
| user | varbinary |

table: aave_v3_ethereum.pool_evt_withdraw
schema:
| name | type |
| --- | --- |
| contract_address | varbinary |
| evt_tx_hash | varbinary |
| evt_tx_from | varbinary |
| evt_tx_to | varbinary |
| evt_tx_index | integer |
| evt_index | bigint |
| evt_block_time | timestamp |
| evt_block_number | bigint |
| evt_block_date | date |
| amount | uint256 |
| reserve | varbinary |
| to | varbinary |
| user | varbinary |

table: aave_v3_ethereum.pool_evt_liquidationcall
schema:
| name | type |
| --- | --- |
| contract_address | varbinary |
| evt_tx_hash | varbinary |
| evt_tx_from | varbinary |
| evt_tx_to | varbinary |
| evt_tx_index | integer |
| evt_index | bigint |
| evt_block_time | timestamp |
| evt_block_number | bigint |
| evt_block_date | date |
| collateralAsset | varbinary |
| debtAsset | varbinary |
| debtToCover | uint256 |
| liquidatedCollateralAmount | uint256 |
| liquidator | varbinary |
| receiveAToken | boolean |
| user | varbinary |
