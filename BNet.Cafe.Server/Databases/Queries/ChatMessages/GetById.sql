SELECT * FROM chat_messages 
WHERE 
DBIsDeleted ='FALSE'
AND DBId = '{DBId}'
ORDER BY DBId DESC 
{LIMIT}