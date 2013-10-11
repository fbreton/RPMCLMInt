###
# ServiceName:
#   name: Name of the service
#   position: A1:B1
#   type: in-text
# OfferName:
#   name: offer name
#   position: E1:F1
#   type: in-external-single-select
#   external_resource: clm_serviceoffering
# HostPrefix:
#   name: Host name prefix
#   position: A2:B2
#   type: in-text
# Password:
#   name: password for the host
#   position: E2:F2
#   type: in-text
###

require 'lib/script_support/clm_utilities'
params["direct_execute"] = true

CLM_HOST = SS_integration_dns
CLM_USER = SS_integration_username
CLM_PASSWORD = SS_integration_password

#Init variables
env = params["SS_environment"]
offerID = params["OfferName"].split("|")[0]
instname = params["ServiceName"]
username = "root"
password = params["Password"]
hostnameprefix=params["HostPrefix"]

raise "Error: OfferName needs to be populated" if offerID.empty?
raise "Error: ServiceName needs to be populated" if instname.empty?

#Init and connecting to CLM
clmobj = ClmUtilities::ClmCall.new(CLM_HOST, CLM_USER, CLM_PASSWORD)
clmobj.login()

# Provision requested offer (tenant should be parametrized with a resource automation requesting CLM)
result = clmobj.service_provision(offerID, instname, username, password, hostnameprefix,"Development & Test")
serviceoffID = result["servoffinst"]
serverNames = result["servnames"]

#logout from CLM
clmobj.logout()

# print result and update rpm properties, servers with result
set_property_flag("ServiceInstID", "#{serviceoffID}")
set_server = "name, environment\n"
serverNames.each do |elt|
  write_to("Server name: #{elt}")
  set_server+="#{elt}, #{env}\n"
end
set_server_flag(set_server)






