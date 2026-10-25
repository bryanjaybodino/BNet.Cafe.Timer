-- Restore record if the combination of Credit Name and Customer Type already exists
UPDATE auto_credit_rates
SET DBIsDeleted = 'FALSE'
WHERE DBCreditName = '{DBCreditName}'
  AND DBCustomerType = '{DBCustomerType}';

-- Check if the Auto Credit Rate record exists
SELECT 
    (
        SELECT COUNT(*) 
        FROM auto_credit_rates 
        WHERE DBCreditName = '{DBCreditName}'
          AND DBCustomerType = '{DBCustomerType}'
    ) AS AutoCreditExist;

-- Insert new record if no conflict exists
INSERT INTO auto_credit_rates (
    DBCreditName,
    DBCustomerType,
    DBPoints,
    DBTriggerDate,
    DBDateCreated,
    DBTimeCreated,
    DBIsDeleted
)
SELECT 
    '{DBCreditName}',
    '{DBCustomerType}',
    '{DBPoints}',
    '{DBTriggerDate}',
    '{DBDateCreated}',
    '{DBTimeCreated}',
    '{DBIsDeleted}'
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1
    FROM auto_credit_rates
    WHERE DBCreditName = '{DBCreditName}'
      AND DBCustomerType = '{DBCustomerType}'
);