Linksys Broadcom Northstar routers (EA6900 etc) have a dual boot option, this sounds like a good idea and it usually is but unfortunately this also halves the nvram size to 32 Kb which is not adequate for a modern router.  
Enter the Xcortex CFE which wil change the router to a single boot device with 64 Kb nvram.   
See: https://forum.dd-wrt.com/phpBB2/viewtopic.php?t=291230&postdays=0&postorder=asc&start=1 It has drawbacks as described in the install guide but it runs well and is fast and stable One of the drawbacks is difficulty upgrading, to make matters worse on builds past 55XXX you cannot update via the command line any more as mtd write always tries to write to the second boot partition (linux 2).  
The following procedure can be used to upgrade with the help of the CFE mini webserver (and advantage of the XVortex CFE which actually makes it more like an Asus AC68U):  
1.	Make backup of settings  
2.	Download new build to your PC  
3.	Do not connect WAN cable  
4.	Connect PC to port 1 set static address 192.168.1.10/24 gateway 192.168.1.1  
5.	Hard Reset to defaults with power down  and holding blue WPS button for about 10 sec until the light starts blinking 
6.	Invoke CFE mini webserver: power down, hold rest button with a pin for about 10 sec while powering up  
7.	Go to http://192.168.1.1 and you should see the CFE mini webserver  
8.	Upload new build with CFE miniwebserver

Alternatively you can use a special made build which makes it possible to write to the first boot partition: linux instead of linux2.  
Important is to delete (unset) the bootpartion nvram variable or to set it to 0 to indicating you want to write to the first boot partition (linux): 
1. Download the patched firmware from: https://github.com/egc112/ddwrt/tree/main/EA6900-XVortex
2. Unzip firmware  
3.	From the command line do: `nvram unset bootpartition; nvram commit`  
4.	Upload via GUI.  

```
Patch
Index: src/router/rc/mtd.c
===================================================================
--- src/router/rc/mtd.c	(revision 57160)
+++ src/router/rc/mtd.c	(working copy)
@@ -396,7 +396,7 @@
 			nvram_seti("bootpartition", 0);
 			_nvram_commit();
 		} else {
-			mtd = "linux2";
+			mtd = "linux";
 			nvram_seti("bootpartition", 1);
 			_nvram_commit();
 		}
```
