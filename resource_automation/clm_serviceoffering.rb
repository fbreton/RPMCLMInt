require 'script_support/clm_utilities'
params["direct_execute"] = true

CLM_HOST = SS_integration_dns
CLM_USER = SS_integration_username
CLM_PASSWORD = SS_integration_password

def execute(script_params, parent_id, offset, max_records)
	clmobj = ClmUtilities::ClmCall.new(CLM_HOST, CLM_USER, CLM_PASSWORD)
	clmobj.login()
	result = clmobj.get_offeringlist()
    response = [{'Select' => ''}]
	result.each do |elt|
		response << {elt["name"]=>"#{elt["reconciliationID"]}|#{elt["name"]}"}
	end
	clmobj.logout()
	return response
end

def  import_script_parameters
	{ "render_as" => "List" }
end




