# Background

If you have a MaxDB database on a physical server or a VM in an MSCS cluster we can protect the file system containing the DB drives and get application consistency with this script. The only requirements are:

1)  Actifio Connector must be installed on the host
2)  File systems must be discovered.   If more than one file system needs to be protected please create a consistency group.  If the DB is on the C:\ or a drive with data you don't wish to protect, use a StartPath.  A StartPath is an advanced setting for the app, set using the AGM GUI.   A screen shot showing this is located at the bottom of this readme.
3)  The bat file in this repo must be renamed to match the APPID, so if the appid is 1566877, then the bat file should be named appid.1566877.bat   You can use the CLI command reportapps to display App IDs.
4)  The renamed bat file should be in c:\Program Files\Actifio\Scripts

Effectively the order of events will be:

1)  Actifio requests the Connector to freeze the database
2)  Actifio requests the Connector create a VSS snapshot
3)  Actifio requests the Connector to thaw the database
4)  Actifio creates an image of the VSS snapshot using changed file tracking
5)  Actifio requests the VSS snapshot be removed

# Important points

This technique suspends the log writer, which suspends update transactions.  Therefore this procedure needs to be run as quickly as possible.  VMware snapshots are good for this because snapshot creation at the VSS level is very fast, allowing the log writer to be resumed quickly.

By suspending the log writer, no more Checkpoints (also called Savepoints) can be written.  This means the last Savepoint is used during database restart or restore.


# Supporting documentation

This kind of backup is documented in SAP Note 616814.

Recovery information is documented in SAP Note 371247.  

# Supported MaxDB Versions

MaxDB 7.3 does not support exiting the session between suspend and resume.  For this reason use version 7.4 and above.
From version 7.8.0.2 and above SAP suggest a different method documented in SAP note 1928060

# Customizing the Script

The script need three settings customized.   The password is stored in the clear.

```
@SET DATABASE=MAXDB1
@SET USERNAME=DBADMIN
@SET PASSWORD=passw0rd
```

# Renaming the script

The script is called appid.xxxx.bat by default.   You must learn the AppID of the file system or ConsistencyGroup app and then rename it.   If the AppID is 1566877 then the file name should be appid.1566877.bat

# Installing the Script

Once the script is customized and named corrctly place it in the following location:
```
c:\Program Files\Actifio\Scripts
```

# Testing the Scripts

Open a command prompt using 'Run as Administrator' and run these two commands:
```
cd c:\Program Files\Actifio\Scripts
appid.1566877.bat freeze
appid.1566877.bat thaw
```
Expected output is as follows.
The database state should have no state.  After the freeze the state should be USR HOLD
```
C:\Program Files\Actifio\scripts>appid.1566877.bat freeze
freeze
------------------------------------------
About to freeze MaxDB due to freeze request
***** log active state
OK


ID   UKT  Win   TASK       APPL Current          Nice  Queue          Command timeout Region         Wait       Wait
   Wait        State  UKT     Call/Sleep
          tid   type        pid state            value                    or Priority exclCnt       info1      info2
  info3        since  (state) count
                                                                (curr,enq [last-deq])



***** issue suspend
OK
IO SEQUENCE                    = 30164
***** log active state after suspend
OK


ID   UKT  Win   TASK       APPL Current          Nice  Queue          Command timeout Region         Wait       Wait
   Wait        State  UKT     Call/Sleep
          tid   type        pid state            value                    or Priority exclCnt       info1      info2
  info3        since  (state) count
                                                                (curr,enq [last-deq])

T2     3  0x85C Logwr           USR HOLD (248)       0  ----                          0
              0.7388  (s)     47/25


Done processing commands

C:\Program Files\Actifio\scripts>appid.1566877.bat thaw
thaw
------------------------------------------
About to thaw MaxDB due to thaw request
***** log active state
OK


ID   UKT  Win   TASK       APPL Current          Nice  Queue          Command timeout Region         Wait       Wait
   Wait        State  UKT     Call/Sleep
          tid   type        pid state            value                    or Priority exclCnt       info1      info2
  info3        since  (state) count
                                                                (curr,enq [last-deq])

T2     3  0x85C Logwr           USR HOLD (248)       0  ----                          0
             28.7224  (s)     47/25


***** issue resume
OK
***** log active state after resume
OK


ID   UKT  Win   TASK       APPL Current          Nice  Queue          Command timeout Region         Wait       Wait
   Wait        State  UKT     Call/Sleep
          tid   type        pid state            value                    or Priority exclCnt       info1      info2
  info3        since  (state) count
                                                                (curr,enq [last-deq])



Done processing commands
```
### Incremental backup versus full backup

Because this method using changed file tracking, you may find the backup size is larger than expected because entire data files are copied.    You can use the GUI to set a Connector Option to force changed block comparison during file copy.  This is known as --low-splash and is set as shown in the screen capture below:

![alt text](https://github.com/Actifio/MaxDBFileSystemBackup/blob/master/images/2019-04-16_12-55-05.jpg)
