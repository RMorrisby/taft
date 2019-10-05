require "test/unit/assertions" # required for the assert_ methods

require "json-schema"
require "avro"
require "csv"
require "net/ssh"
require "net/sftp"
require "more_ruby"


class RSHelper
    include Test::Unit::Assertions

    # Reads in a file of CSV test data, e.g for use in data-driven tests
    def read_csv_test_data(filename)
        path = File.join(File.dirname(File.expand_path(__FILE__)) + "/../../../../tests/data", filename)
        read_csv_data_from_file(path)
    end

    # Reads in a CSV
    def read_csv_data_from_file(full_file_path)
        data = []
        CSV.open(full_file_path, "r") do |csv|
            data = csv.readlines
        end
        data
    end

    # Reads in a JSON schema
    def read_json_schema(schema_filename)
        path = File.join(File.dirname(File.expand_path(__FILE__)) + "/../../../../tests/data", schema_filename)
        data = []
        File.open(path, "r") do |f|
            data = f.readlines
        end
        schema = JSON.parse(data.chomp) # there may be trailing whitespace
        schema
    end

    # Reads in a serialised AVRO file
    # Returns an array of the deserialised data rows
    def read_avro_file(filename)
        lines = []
        File.open(path, "rb") do |f|
            reader = Avro::IO::DatumReader.new
            dr = Avro::DataFile::Reader.new(f, reader)
            dr.each do |record|
                lines << record
            end
        end
        lines
    end

    # Validates the supplied hash against the JSON schema
    def validate_hash_against_json_schema(hash, schema_filename)
        raise "Must supply a hash to #{__method__}" unless hash.class == Hash

        schema = read_json_schema(schema_filename)
        errors = JSON::Validator.fully_validate(schema, hash)
        errors
    end

    # Calls the build_number REST method
    # This is an example of how to use get_rest_client
    def get_version_number_from_api(cert_symbol = :regular)
        client = get_rest_client(:build_number, cert_symbol)
        json = client.get # {"message":"1.8.0"}
        parsed = JSON.parse(json)
        parsed["message"]
    end

    # Forms a .tar.gz archive from the specified source file
    # Creates the file in the working directory
    # Creates the .tar.gz via a call to system
    def create_tar_gz_file(gz_base_file_name, source_file)
        gz_name = "#{gz_base_file_name}.tar.gz"
        cmd = "tar -czf #{gz_name} #{source_file}"
        system(cmd)
        gz_name
    end

    # Renames the specified file on the Linux server
    # Needs the full path
    def rename_linux_file(old_file, new_file, cert_symbol = :regular)
        # Derive the FTP host & path from the URL in config
        host = RedSkyConfig::SERVER[:red_sky_url].split("//")[1].split(":")[0]
        host_short_form = host.split(".")[0]
        user = get_user_id(cert_symbol)
        pass = get_user_cert_pw(cert_symbol)

        Net::SFTP.start(host, user, :password => pass) do |sftp|
            puts "Renaming file : #{old_file} -> #{new_file}"
            sftp.rename(old_file, new_file)
        end
    end

    # Sets 777 permissions to the Linux server file
    # Need the file name & dir
    def chmod_linux_file(host, user, pass, path, file_name)
        Net::SSH.start(host, user, :password => pass) do |ssh|
            ssh.exec!("cd #{path}; chmod 777 #{file_name}")
        end
    end

    # Executes the supplied curl command on the server
    def submit_curl_command(cmd, cert_symbol = :regular)
        # Derive the FTP host & path from the URL in config
        host = RedSkyConfig::SERVER[:red_sky_url].split("//")[1].split(":")[0]
        host_short_form = host.split(".")[0]
        user = get_user_id(cert_symbol)
        pass = get_user_cert_pw(cert_symbol)

        output = ""
        Net::SSH.start(host, user, :password => pass) do |ssh|
            output = ssh.exec!(cmd)
        end

        # We expect a JSON response from the server
        # The recorded output will contain this inside curl's own SDTOUT, so we need to extract the JSON
        output = output[output.index("{") .. output.index("}")]
        JSON.parse(output)
    end


end
