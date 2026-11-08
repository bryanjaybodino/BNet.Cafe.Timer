UPDATE `rentals` 
SET 
	`DBIsDeleted` = 'TRUE',
	`DBDeletedById` = '{DBDeletedById}',
	`DBDateDeleted` = '{DBDateDeleted}',
	`DBTimeDeleted` = '{DBTimeDeleted}'
WHERE `DBId` = '{DBId}';