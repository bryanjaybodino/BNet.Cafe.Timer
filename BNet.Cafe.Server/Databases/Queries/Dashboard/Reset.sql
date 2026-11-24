UPDATE rentals 
SET DBIsCollected = 'TRUE' 
WHERE STR_TO_DATE(DBDateCreated, '%Y-%m-%d') BETWEEN STR_TO_DATE('{DBDateStart}', '%Y-%m-%d') AND STR_TO_DATE('{DBDateEnd}', '%Y-%m-%d');

UPDATE balances 
SET DBIsCollected = 'TRUE' 
WHERE STR_TO_DATE(DBDateCreated, '%Y-%m-%d') BETWEEN STR_TO_DATE('{DBDateStart}', '%Y-%m-%d') AND STR_TO_DATE('{DBDateEnd}', '%Y-%m-%d');

UPDATE inventory_transactions 
SET DBIsCollected = 'TRUE' 
WHERE STR_TO_DATE(DBDateCreated, '%Y-%m-%d') BETWEEN STR_TO_DATE('{DBDateStart}', '%Y-%m-%d') AND STR_TO_DATE('{DBDateEnd}', '%Y-%m-%d');

UPDATE vouchers 
SET DBIsCollected = 'TRUE' 
WHERE STR_TO_DATE(DBDateCreated, '%Y-%m-%d') BETWEEN STR_TO_DATE('{DBDateStart}', '%Y-%m-%d') AND STR_TO_DATE('{DBDateEnd}', '%Y-%m-%d');