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
# UserParameters:
#	name: user parameters for CLM offer
#	position: A3:F3
#	type: in-text
###

require 'lib/script_support/clm_utilities'
params["direct_execute"] = true

CLM_HOST = SS_integration_dns
CLM_USER = SS_integration_username
CLM_PASSWORD = decrypt_string_with_prefix(SS_integration_password_enc)

#Init variables
env = params["SS_environment"]
offerID = params["OfferName"].split("|")[0]
instname = params["ServiceName"]
username = "root"
password = params["Password"]
hostnameprefix=params["HostPrefix"]
userparams=params["UserParameters"]

raise "Error: OfferName needs to be populated" if offerID.empty?
raise "Error: ServiceName needs to be populated" if instname.empty?

userparams_hash=nil
unless userparams.empty?
	userparams_hash={}
	userparams.split('|').each do |aux|
		userparams_hash[aux.split('=')[0]]=aux.split('=')[1]
	end
end

#Init and connecting to CLM
clmobj = ClmUtilities::ClmCall.new(CLM_HOST, CLM_USER, CLM_PASSWORD)
clmobj.login()

# Provision requested offer (tenant should be parametrized with a resource automation requesting CLM)
result = clmobj.service_provision(offerID, instname, username, password, hostnameprefix,"Development & Test",1,userparams_hash)
serviceoffID = result["servoffinst"]
serverNames = result["servnames"]

# print result and update rpm properties, servers with result
set_property_flag("ServiceInstID", "#{serviceoffID}")
set_server = "name, environment\n"
serverNames.each do |elt|
  write_to("Server name: #{elt}")
  set_server+="#{elt}, #{env}\n"
end
set_server_flag(set_server)






