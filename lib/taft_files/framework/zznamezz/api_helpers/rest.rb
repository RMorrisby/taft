require "rest_client"
require "uri"
require "openssl"
require "json"

# File contains methods conductive to the execution of tests and scripts that call REST interfaces


class XXabbrevupperxxHelper

    # Returns a RestClient::Resource object pointing to the URL of the requested service
    def get_rest_client(service, cert_symbol = :regular, parameter_array_or_hash = [], base_url = ZZnamezzConfig::SERVER[:zznamezz_url], version = nil, timeout = 150)
        
        separator = "/"
        api_version_string = separator + ZZnamezzConfig::API_VERSION.to_s # as the version parameter can be entirely absent, let's build the separator into the term
        api_version_string = "" if ZZnamezzConfig::API_VERSION == :none # special case

        api_version_string = separator + version if version # override always wins

        parameter_array_or_hash = [parameter_array_or_hash] if parameter_array_or_hash.class != Array && parameter_array_or_hash.class != Hash # convert to array if a non-array/hash was supplied
        
        # If common headers are needed
        # headers = {"foo" => bar}

        # Build up the path-string, then append it to the base URL
        s = "" # initialise before manipulating it

        if service.class == String
            s = service
        else
            case service
            when :options
                s = "options#{api_version_string}"
                s += "/#{parameter_array_or_hash[0]}"
            when :build_number
                s = "query/info#{api_version_string}/buildnumber"
            else
                raise "Unknown service #{service} supplied to #{__method__}"
            end
        end

        encoded = encode_uri(s).to_s # Generates a URI::Generic object; we want a string
        url = base_url + encoded

        puts url

        #######################################################
        # Get certificate and other parameters needed for valid credentials
        #######################################################

        OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ssl_version] = "SSLv3" # this may or may not be needed

        cert_path = File.expand_path(ZZnamezzConfig::CERTIFICATE_DIR) # this must be an absolute filepath
        cert_extension = get_user_cert_ext(cert_symbol).to_s

        cert_name = get_user_p12_cert_name(cert_symbol)
        cert_pw = get_user_cert_pw(cert_symbol)

        # ca_file = ZZnamezzConfig::CA_CERTIFICATE_FILE # needed for VERIFY_PEER mode # VERIFY_PEER mode currently disabled

        if cert_extension.to_sym == :pem
            # If PEM, the credentials are in two parts - the certs.pem file and the key.pem file
            # Need to read in the two separate files & construct OpenSSL::X509::Certificate & OpenSSL::PKey::RSA objects
            cert_key_name = get_user_pem_cert_key_name(cert_symbol)
            cert_key_pw = get_user_cert_key_pw(cert_symbol)
            pem = File.read(File.join(cert_path, cert_name))
            key_pem = File.read(File.join(cert_path, cert_key_name))

            cert = OpenSSL::X509::Certificate.new(pem)

            begin
                key = OpenSSL::PKey::RSA.new(key_pem, cert_key_pw)
            rescue
                raise "Could not form OpenSSL::PKey::RSA object for the corresponding key.pem file. Does it have the right password?"
            end
            return RestClient::Resource.new(url, {:ssl_client_cert => cert, :ssl_client_key => key, :verify_ssl => OpenSSL::SSL::VERIFY_NONE, :timeout => timeout})
        else
            # If P12 or PFX, only need to construct the one object - the certificate and key are both stored within it
            begin
                p12 = OpenSSL::PKCS12.new(File.read(File.join(cert_path, cert_name), :binmode => true), cert_pw)
            rescue OpenSSL::PKCS12::PKCS12Error => e
                if e.to_s.include?("mac verify failure")
                    raise "Could not create PKCS12 object from certificate #{cert_name}; please specify a password for the certificate"
                else
                    raise e
                end
            end

            # Use if performing SSL Peer verification - needs a ca certificate
            return RestClient::Resource.new(url, {:ssl_client_cert => p12.certificate, :ssl_client_key => p12.key, :ssl_ca_file => ca_file, :verify_ssl => OpenSSL::SSL::VERIFY_PEER, :headers => headers, :timeout => timeout})

            # Use if not performing SSL Peer verification - does not need a ca certificate
            return RestClient::Resource.new(url, {:ssl_client_cert => p12.certificate, :ssl_client_key => p12.key, :verify_ssl => OpenSSL::SSL::VERIFY_NONE, :timeout => timeout})
        end

    end

    # Method to encode the URI
    # Takes a string or an array of path fragments. If an array, the contents will be joined using / characters
    def encode_uri(uri)
        uri = uri.join("/") if uri.class == Array
        additional_encoding(URI.parse(URI.encode(uri)).to_s)
    end


    # Method to perform additional encoding
    # URI.encode does not convert the following chars: : + 
    def additional_encoding(s)
        encoding_hash = {":" => "%3A", "+" => "%2B"}
        encoding_hash.each_pair do |k, v|
            s.gsub!(k, v)
        end
        s
    end

    # Converts a string or int representing the number of microseconds since the Time epoch (1970/01/01) into a DateTime object
    def read_epoch_time(microseconds_since_epoch)
        Time.at(microseconds_since_epoch.to_i/1000)
    end

    # Converts the body of the response object from JSON to Ruby, and sets the defaults for the main hash and all sub-hashes
    def get_response_body(response)
        raise "REST response was nil" if response == nil
        raise "REST response had no attached body" if response.body == nil
        begin
            body = JSON.parse(response.body, {:max_nesting => 100})
            set_all_defaults(body)
        rescue JSON::ParserError => e
            puts "rescued : ParserError"
            puts e
            body = response.body
        end
        body
    end


    # Converts the header of the response object from JSON to Ruby, and sets the defaults for the main hash and all sub-hashes
    def get_response_header(response)
        raise "REST response was nil" if response == nil
        raise "REST response had no attached header" if response.headers == nil
        begin
            header = response.headers # already in Ruby Hash format
            set_all_defaults(body)
        rescue JSON::ParserError => e
            puts "rescued : ParserError"
            puts e
            header = response.headers
        end
        header
    end

    # Takes a hash a recursively sets the default of the hash and all sub-hashes
    def set_all_defaults(hash, default = nil)
        return unless hash.class == Hash
        hash.default = default
        hash.each_pair do |k, v|
            set_all_defaults(v) if v.class == Hash
            if v.class == Array
                v.each {|z| set_all_defaults(z) if z.class == Hash}
            end
        end
    end

    # Method to perform a POST request. Requires the RESTClient Resource client and a hash of the information to be sent in the POST body. This hash is converted to JSON for the POST.
    # Optionally also takes an additional hash which contains desired headers for the POST request.
    # Returns a RESTClient::Response object
    def post_request(client, post_information_hash, additional_hash = nil)
        new_hash = {:content_type => "application/json"}
        additional_hash ||= {} 
        new_hash.merge!(additional_hash)

        begin
            client.post(JSON.generate(post_information_hash, {:max_nesting => 100}), new_hash)
        rescue OpenSSL::SSL::SSLError => e
            raise "SSLError occurred when calling REST service; #{e}"
        rescue RestClient::Exception => e # if the request failed, RestClient will throw an error. We want to retrieve that error and the response within
            puts "RestClient::Exception hit when calling REST service"
            puts e
            puts e.response
            return e.response
        rescue => e
            raise "Unexpected error occurred when calling REST service; #{e}"
        end
    end

    # Method to perform a POST request that sends a file. Requires the RESTClient Resource client and a hash of the information to be sent in the POST body.
    # Assumes that all file information (including the File object itself) is included in the supplied hash
    # Optionally also takes an additional hash which contains desired headers for the POST request.
    # Returns a RESTClient::Response object
    def post_file_request(client, post_information_hash, additional_hash = nil)
        new_hash = {}
        additional_hash ||= {} 
        new_hash.merge!(additional_hash)

        begin
            client.post(post_information_hash, new_hash)
        rescue OpenSSL::SSL::SSLError => e
            raise "SSLError occurred when calling REST service; #{e}"
        rescue RestClient::Exception => e # if the request failed, RestClient will throw an error. We want to retrieve that error and the response within
            puts "RestClient::Exception hit when calling REST service"
            puts e
            puts e.response
            return e.response
        rescue => e
            raise "Unexpected error occurred when calling REST service; #{e}"
        end
    end

    
    # Method to perform a PUT request. Requires the RESTClient Resource client and a hash of the information to be sent in the PUT body. This hash is converted to JSON for the PUT.
    # Optionally also takes an additional hash which contains desired headers for the PUT request, e.g. {:content_type => "application/json"}
    # Returns a RESTClient::Response object
    def put_request(client, put_information_hash, additional_hash = nil)
        new_hash = {:content_type => "application/json"}
        additional_hash ||= {} 
        new_hash.merge!(additional_hash)

        begin
            client.put(JSON.generate(put_information_hash, {:max_nesting => 100}), new_hash)
        rescue OpenSSL::SSL::SSLError => e
            raise "SSLError occurred when calling REST service; #{e}"
        rescue RestClient::Exception => e # if the request failed, RestClient will throw an error. We want to retrieve that error and the response within
            puts "RestClient::Exception hit when calling REST service"
            puts e
            puts e.response
            return e.response
        rescue => e
            raise "Unexpected error occurred when calling REST service; #{e}"
        end
    end

    
    # Method to perform a DELETE request. Requires the RESTClient Resource client.
    # Returns a RESTClient::Response object
    def delete_request(client)
        begin
            client.delete
        rescue OpenSSL::SSL::SSLError => e
            raise "SSLError occurred when calling REST service; #{e}"
        rescue RestClient::Exception => e # if the request failed, RestClient will throw an error. We want to retrieve that error and the response within
            puts "RestClient::Exception hit when calling REST service"
            puts e
            puts e.response
            return e.response
        rescue => e
            raise "Unexpected error occurred when calling REST service; #{e}"
        end
    end
end
