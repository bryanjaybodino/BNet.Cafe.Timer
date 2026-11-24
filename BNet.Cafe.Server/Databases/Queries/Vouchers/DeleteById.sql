UPDATE `vouchers` 
SET 
	`DBDeletedById` = '{DBDeletedById}',
	`DBDateDeleted` = '{DBDateDeleted}',
	`DBTimeDeleted` = '{DBTimeDeleted}'
WHERE `DBId` = '{DBId}';