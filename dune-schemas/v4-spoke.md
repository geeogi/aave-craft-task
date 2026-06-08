table: aave_v4_ethereum.mainspoke_evt_supply
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
| caller | varbinary |
| reserveId | uint256 |
| suppliedAmount | uint256 |
| suppliedShares | uint256 |
| user | varbinary |

table: aave_v4_ethereum.mainspoke_evt_withdraw
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
| caller | varbinary |
| reserveId | uint256 |
| user | varbinary |
| withdrawnAmount | uint256 |
| withdrawnShares | uint256 |

table: aave_v4_ethereum.mainspoke_evt_borrow
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
| caller | varbinary |
| drawnAmount | uint256 |
| drawnShares | uint256 |
| reserveId | uint256 |
| user | varbinary |

table: aave_v4_ethereum.mainspoke_evt_repay
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
| caller | varbinary |
| drawnShares | uint256 |
| premiumDelta | varchar |
| reserveId | uint256 |
| totalAmountRepaid | uint256 |
| user | varbinary |

table: aave_v4_ethereum.mainspoke_evt_liquidationcall
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
| collateralAmountRemoved | uint256 |
| collateralReserveId | uint256 |
| collateralSharesLiquidated | uint256 |
| collateralSharesToLiquidator | uint256 |
| debtAmountRestored | uint256 |
| debtReserveId | uint256 |
| drawnSharesLiquidated | uint256 |
| liquidator | varbinary |
| premiumDelta | varchar |
| receiveShares | boolean |
| user | varbinary |

table: aave_v4_ethereum.mainspoke_evt_addreserve
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
| assetId | uint256 |
| hub | varbinary |
| reserveId | uint256 |
