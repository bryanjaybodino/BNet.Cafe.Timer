UPDATE client_config 
SET 
    DBTimeZone = '{DBTimeZone}',
    DBAccountCreationAllowed = '{DBAccountCreationAllowed}',
    DBAutoShutDownInterval = '{DBAutoShutDownInterval}',
    DBDesktopSlideShow = '{DBDesktopSlideShow}',
    DBResetShutdownCountdown = '{DBResetShutdownCountdown}',
    DBTimerSizeMode = '{DBTimerSizeMode}',
    DBComshopName = '{DBComshopName}',
    DBEnableScheduler = '{DBEnableScheduler}',
    DBOpeningTime = '{DBOpeningTime}',
    DBClosingTime = '{DBClosingTime}',
    DBClosingTimeMessage = '{DBClosingTimeMessage}',
    DBWarningTime = '{DBWarningTime}',
    DBWarningTimeMessage = '{DBWarningTimeMessage}',
    DBVIPBirthdayCredits = '{DBVIPBirthdayCredits}',
    DBMemberBirthdayCredits = '{DBMemberBirthdayCredits}',
    DBEnableGameMenu = '{DBEnableGameMenu}',
    DBLayoutMode = '{DBLayoutMode}',
    DBEnableMinimize = '{DBEnableMinimize}',
    DBEnableWindowsKey = '{DBEnableWindowsKey}',
    DBSharedDataPath = '{DBSharedDataPath}',
    DBId = '{DBId}'
WHERE DBId = '{DBId}';