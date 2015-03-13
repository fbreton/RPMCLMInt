require 'json'
require 'rest-client'

module ClmUtilities
	class ClmCall
		attr_reader :authentication_token, :base_url, :timeout_sec
		
		AUTH_TOKEN = :authentication_token
		AUTH_ACTION = "/login"
		ERROR_ACTION = "errorCause"
		LOGOUT_ACTION = "/logout"
		SVC_SRCH_ACTION = "/ServiceOffering/search"
		SVC_BULK_CREATE_ACTION = "/ServiceOfferingInstance/bulkcreate"

		OP_TYPE_STRING = "java.lang.String"
		OP_TYPE_DATE = "java.util.Date"
		OP_TYPE_INT = "java.lang.Integer"
		OP_TYPE_SVC = "com.bmc.cloud.model.beans.ServiceOffering"
		
		def initialize(clm_url, user_name, password, timeout_sec=300)

			raise ArgumentError, "Expected a URL to the CLM REST api" if clm_url.nil?
			raise ArgumentError, "Expected a user name to the CLM REST api" if user_name.nil?
			raise ArgumentError, "Expected a password to the CLM REST api" if password.nil?

			@base_url = clm_url
			@user_name = user_name
			@password = password

			@timeout_sec = timeout_sec
		end

		def login()
			response = call_service_post(AUTH_ACTION,{:username => @user_name, :password => @password}.to_json)

			if !response.nil?
				if response.headers.has_key?(AUTH_TOKEN)
					@authentication_token = response.headers[AUTH_TOKEN]
				else
					raise "Wrong user: #{@user_name} or wrong password"
				end
			else
				raise "No Reponse Data Exists for: #{@user_name}"
			end

			return 0
		end	

		def get_offeringlist(filter=nil)
			# filter: array of name of offer to filter on
			ops_req = [{:multiplicity=>"1", :name=>"fillFields",:type=>"java.lang.String", :value=>"reconciliationID"},{:multiplicity=>"1",:name=>"orderBy", :type =>"java.lang.String", :value=>"name"}]
			hash_req = {:timeout=>-1, :operationParams=>ops_req}
			result=request("POST",SVC_SRCH_ACTION,hash_req)
			response=Array.new
			if !filter.nil?
				result["results"].each do |x|
					if filter.include?(x["name"])
						response << x
					end
				end
			else
				response = result["results"]
			end
			return response
		end	

		def service_provision(offerID, instname, username, password, hostnameprefix, tenant, quantity=1, userparam=nil)
			servNames = Array.new
			servOffInst = nil
			ops_req = Array.new
			password = "" if password.nil?
			password="plaintext:#{password}"
			
			raise "Error: offerID needs to contain a value" if offerID.empty?
			raise "Error: instname needs to contain a value" if instname.empty?
			raise "Error: username needs to contain a value" if username.empty?
			raise "Error: hostnameprefix needs to contain a value" if hostnameprefix.empty?
			raise "Error: tenant needs to contain a value" if tenant.empty?

			ops_req << {:name=>"serviceOfferingID",:type=>OP_TYPE_SVC,:multiplicity=>"1",:value=>{:cloudClass=>"com.bmc.cloud.model.beans.ServiceOffering",:reconciliationID=>offerID}}
			ops_req << {:name=>"name",:type=>OP_TYPE_STRING,:multiplicity=>"1",:value=>instname}
			ops_req << {:name=>"username",:type=>OP_TYPE_STRING,:multiplicity=>"1",:value=>username}
			ops_req << {:name=>"password",:type=>OP_TYPE_STRING,:multiplicity=>"1",:value=>password}
			ops_req << {:name=>"hostnamePrefix",:type=>OP_TYPE_STRING,:multiplicity=>"1",:value=>hostnameprefix}
			ops_req << {:name=>"quantity",:type=>OP_TYPE_INT,:multiplicity=>"1",:value=>quantity}
			ops_req << {:name=>"tenant",:type=>OP_TYPE_STRING,:multiplicity=>"1",:value=>tenant}
			unless userparam.nil?
				aux = []
				userparam.each_pair do |name, value|
					aux << {:cloudClass=>"com.bmc.cloud.model.beans.NameValuePair",:name=>name,:value=>value}
				end
				ops_req << {:name=>"userParameters",:type=>"com.bmc.cloud.model.beans.NameValuePair",:multiplicity=>"1..*",:value=>aux}
			end
			hash_req = {:timeout=>-1, :operationParams=>ops_req}
			
			response = request("POST",SVC_BULK_CREATE_ACTION,hash_req) 	#launch service provisioning
			taskUri = response["taskStatusURI"]
			raise "operation failed: #{response["errors"][0]}" if taskUri.nil?
			ind = taskUri.index("csm")
			taskUri = taskUri[(ind+3)..(taskUri.length)]
			result = wait_task_completed(taskUri)						#wait for service to be provisioned and started or failed
			
			# following 2 lines are because of bad formating of the output not respecting JSON format
			ind =  result.index(":")
			result = JSON.parse result[(ind+1)..(result.length)]
			
			# Store service offering instance uri and name of provisionned servers
			servOffInst = result["functionalComponentsObject"][0]["serviceOfferingInstance"]
			result = request("GET",result["functionalComponentsObject"][0]["resourceSet"])
			raise "Compute not found in #{result}" if result["compute"].nil?
			result["compute"].each do |compuri|
				result = request("GET",compuri)
				servNames << result["name"]
			end
			return {"servoffinst"=>servOffInst.gsub("/serviceofferinginstance/",""), "servnames"=>servNames}
		end
		
		def service_decommission(soi)
			raise "Error: soi needs to contain a value" if soi.empty?
			hash_req = {:timeout=>-1, :preCallout=>"", :postCallout=>"", :operationParams=>[]}
			response = request("POST","/serviceofferinginstance/#{soi}/decommission",hash_req)
			raise "Error: Service instance does not exist" if response.has_key? "errors"
		end


		def wait_task_completed(uri)
			getresult = 1
			until getresult == 0
				result=request("GET",uri)
				if result.has_key? "results"
                                        getresult = 0
                                        result = result["results"][0]
                                else
                                       	raise "#{result["className"]} #{result["operationName"]} operation failed" if result["taskState"] == "FAILED"
                                        sleep(60)
                                end
				if result["taskState"] == "FAILED" 
					raise "#{result["className"]} #{result["operationName"]} operation failed"
				end
			end	
			return result
		end
	
		def request(method, uri, reqbody={})
			if method == "GET"
				response = call_service_get(uri,reqbody.to_json)
			else
				response = call_service_post(uri,reqbody.to_json)
			end
			
			if !response.nil?
				outer_array = JSON.parse response
				raise "#{outer_array[0]["errorID"]}: #{outer_array[0]["errorCause"]}" if outer_array[0].has_key?(ERROR_ACTION)
				return outer_array[0]
			else
				raise "Wrong uri:#{uri} or wrong reqbody: #{reqbody}"	
			end

		end	

		def logout()
			response = call_service_post(LOGOUT_ACTION,{ }.to_json)
			return 0
		end	
		
		def call_service_post (action, payload)
			response = call_service true, action, payload
		end
		private :call_service_post

		def call_service_get (action, payload)
			response = call_service false, action, nil
		end
		private :call_service_get

		def call_service (is_post, action, payload)
			url = "#{@base_url}#{action}"

			resource = RestClient::Resource.new url, :timeout => timeout_sec, :open_timeout => timeout_sec

			if is_post
				response = resource.post payload, "Authentication-Token" => authentication_token, :content_type => "application/json"
			else
				response = resource.get "Authentication-Token" => authentication_token, :content_type => "application/json"
			end

			if (response.code == 200)
				response
			else
				raise Exception, response.code.to_s + " error executing call"
			end

		end
		private :call_service

	end
end
