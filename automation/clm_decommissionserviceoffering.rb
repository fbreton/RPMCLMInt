###
# ServiceInstID:
#   name: Name of the service
#   position: A1:B1
#   type: in-text
###

#=== General Integration Server: CLM ===#
# [integration_id=3]
SS_integration_dns = "http://clm-pm:8080/csm"
SS_integration_username = "CloudAdmin"
SS_integration_password = "-private-"
SS_integration_details = ""
SS_integration_password_enc = "__SS__Cj1RbWN2ZDNjekZHYw=="
#=== End ===#

require 'lib/script_support/clm_utilities'
params["direct_execute"] = true



CLM_HOST = SS_integration_dns
CLM_USER = SS_integration_username
CLM_PASSWORD = SS_integration_password

soi = params["ServiceInstID"]

clmobj = ClmUtilities::ClmCall.new(CLM_HOST, CLM_USER, CLM_PASSWORD)
clmobj.login()
result = clmobj.service_decommission(soi)
write_to("Decommission done")

