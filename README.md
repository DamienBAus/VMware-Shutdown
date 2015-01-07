# VMware-Shutdown
This script can be used when you need to shut down some vmware virtual machines in a farm environment. It uses Powershell to query the servers and send a soft shutdown command to the vms. 

---

This script was created to help shutdown a whole farm of virtual machines 
in one sweeping go (when you may not necessarily know which machine sits
on which server). The main purpose was for incidences such as power outages
in which an administrator wants to shutdown the machines gracefully before
the power runs out.

This script works by:

1) Querying each computer for any vmware virtual machines that exist on it. 
2) Finding the original vmdk file that can be used to shutdown the vm
3) Sending a soft shutdown signal to each vm, coming from the computer.

The following assumptions have been made:
- Powershell is available on the machine
- There exists a file called "Physicals.txt" which holds a list of server 
  names (or IPs) in which to query
- Their exists administrative credentials which can be used to remote into 
  each server (variables $Admin and $Pass).
  
This script will almost definitely have to be tailored to each new environment
it is introduced to, but it should provide a good starting point for any 
vmware administrator. 
