UPDATE client_config 
SET 
    DBTimeZone = '{DBTimeZone}',
    DBAccountCreationAllowed = '{DBAccountCreationAllowed}',
    DBAutoShutDownInterval = '{DBAutoShutDownInterval}',
    DBDesktopSlideShow = '{DBDesktopSlideShow}',
    DBResetShutdownCountdown = '{DBResetShutdownCountdown}',
    DBComshopName = '{DBComshopName}',
    DBEnableScheduler = '{DBEnableScheduler}',
    DBOpeningTime = '{DBOpeningTime}',
    DBClosingTime = '{DBClosingTime}',
    DBClosingTimeMessage = '{DBClosingTimeMessage}',
    DBWarningTime = '{DBWarningTime}',
    DBWarningTimeMessage = '{DBWarningTimeMessage}',
    DBBirthdayCredits = '{DBBirthdayCredits}',
    DBEnableGameMenu = '{DBEnableGameMenu}'
WHERE DBId = '{DBId}';