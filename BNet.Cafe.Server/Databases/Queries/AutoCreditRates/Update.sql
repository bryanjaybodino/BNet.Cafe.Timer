UPDATE `auto_credit_rates`
SET 
    `DBCreditName` = '{DBCreditName}',
    `DBCustomerType` = '{DBCustomerType}',
    `DBPoints` = '{DBPoints}',
    `DBTriggerDate` = '{DBTriggerDate}'
WHERE `DBId` = '{DBId}';