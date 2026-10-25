SELECT * FROM auto_credit_rates 
WHERE 1 
AND DBCustomerType = '{DBCustomerType}' 
AND DBTriggerDate = '{DBTriggerDate}' 
AND DBIsDeleted = '{DBIsDeleted}' 
ORDER BY DBId DESC 
{LIMIT}