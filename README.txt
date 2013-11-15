RPMCLMInt
=========

Automation scripts and associated code to provision and decommission CLM offer from BRPM 


Install
=======

You first need to create a new automation category in BRPM, to do so, log in BRPM and:
  1. go to Environment -> Metadata -> Manage Lists
  2. Click AutomationCategory in the list displayed.
  3. In the Add List Item box, enter BMC Cloud LifeCycle Management
  4. Click Add Item. The new item gets added to the Active List items list.
  5. Click Save.
  
Then you need to add 2 folders in the RLM server:
  <BRPM install dir>/WEB-INF/lib/script_support/LIBRARY/automation/BMC Cloud LifeCycle Management
  BRPM install dir>/WEB-INF/lib/script_support/LIBRARY/resource_automation/BMC Cloud LifeCycle Management
  
Files in automation directories need to be copied on BRPM server to: 
  <BRPM install dir>/WEB-INF/lib/script_support/LIBRARY/automation/BMC Cloud LifeCycle Management
Files in resource_automation need to be copied on BRPM server to:
  
clm_utilities.rb to be copied on BRPM server to: 
  <BRPM install dir>/WEB-INF/lib/script_support/LIBRARY/resource_automation/BMC Cloud LifeCycle Management

Setup
=====

You need to create an integration server pointing to your CLM server to point to the API:
  Server Name: <up to you>
  Server URL: <CLM API url; exemple: http://clm-pm:8080/csm>
  Username: <CLM User name with admin right>
  password: <password of previously defined user>
  
You need to import in automation (Environment -> Automation):
  1. The resource automation script that you associate with previously defined integration server
      clm_serviceoffering.rb: provide the list of service offering from CLM and add the server to the component instance
                              associated with the step executing the automation
  2. The automation scripts that you associate with previously defined integration server
      clm_provisionserviceoffering.rb: to provision an service from CLM
      clm_decommissionserviceoffering.rb: to decommission a service from CLM using Service Instance ID ususally provided
                                          by clm_provisionserviceoffering.rb.

To use those automation script, the component associated to steps using those automation need to have a property named
ServiceInstID. This is designed for one service to be associated with one component and that the service contain just one 
server. clm_serviceoffering.rb store the Service Instance ID in the ServiceInstID property and 
clm_decommissionserviceoffering.rb get it from the property to decommission the service.

Improvments
===========

May add the capability to provision several instances of the same service adding a parameter for number of instance.
Service to provision still be one server service and use cases is that all those server has exactly the same role and
so will follow the same process (same deployment, etc...) which means that usage of those automations stay the same in
a request than with the actual CLM automation status.
