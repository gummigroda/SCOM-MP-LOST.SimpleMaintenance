# LOST Simple Maintenance

MP to run stuff as rules, for simple maintenance.

---

## Rules

* __LOST.Unsealed.MP.Backup.Rule__  
This rule exports unseal:ed management packs as a ZIP to a UNC path.  
Targeted at the 'All Management Servers' group, and therefor runs on one of the management servers in the group.  
Extended from: https://kevinholman.com/2017/07/07/scom-2012-and-2016-unsealed-mp-backup/

  - Overrides:  
    - BackupPath (Mandatory):  
    Set this to a UNC share and make sure the SCOM account used to run the rule has write access
    
    - DaysToKeep (Optional):  
    Amount of days to keep in the backup folder.  
    _Default: 120 days_

    - IntervalSeconds (Optional):  
    How often the backup is run.  
    _Default: 24h_

    - SyncTime (Optional):  
    When the backup starting. 24h.  
    _Default: 03:00_

    - TimeoutSeconds (Optional):  
    Script timeout.  
    _Default: 5 min_

---

* __LOST.Delete.Disabled.Objects.Rule__  
This rule runs the 'Remove-SCOMDisabledClassInstance' via the SDK endpoint.
Extended from: https://nocentdocent.wordpress.com/2012/11/30/how-to-schedule-the-remove-scomdisabledclassinstance-comdlet/

  - Overrides:

    - IntervalSeconds (Optional):  
    How often the command is run.  
    _Default: 24h_  

    - SyncTime (Optional):  
    When to run it.  
    _Default: 01:00_

    - TimeoutSeconds (Optional):  
    Script timeout.  
    _Default: 10 min_

---

## Install

1. Download the Zip from the "releases tab"
1. UnZip
1. Import into SCOM
1. Set overrides to match your environment

---

