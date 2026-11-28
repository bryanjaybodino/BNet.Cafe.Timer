UPDATE `rentals` 
SET 
	`DBComputerId` = '{DBComputerId}',
	`DBUserId` = '{DBUserId}',
	`DBDuration` = '{DBDuration}',
	`DBFreeTime` = '{DBFreeTime}',
	`DBAmount` = '{DBAmount}'
WHERE `DBId` = '{DBId}'