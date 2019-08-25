require 'fileutils'
require 'pathname'
require 'more_ruby'

def pd(s)
    puts s if $TAFT_DEBUGGING
end

class Taft
    TEMPLATE_PROJECT_NAME_REGEX = /(zznamezz)/ # e.g. redsky if one word, red_sky if two # regex to use when matching a template file name
    TEMPLATE_PROJECT_NAME_UPPERCASE_REGEX = /(ZZnamezz)/ # e.g. Redsky if one word, RedSky if two # regex to use when matching a template file name
    TEMPLATE_PROJECT_ABBREV_REGEX = /(xxabbrevxx)/ # e.g. bs # regex to use when matching a template file name
    TEMPLATE_PROJECT_ABBREV_UPPERCASE_REGEX = /(xxabbrevupperxx)/i # e.g. BS # regex to use when matching some template text
    TEMPLATE_PROJECT_RAW_NAME_REGEX = /(yyrawnameyy)/i # e.g. RED SKY # regex to use when matching some template text

    NAMES_AND_ABBREVS_REGEXES = [TEMPLATE_PROJECT_ABBREV_REGEX, TEMPLATE_PROJECT_ABBREV_UPPERCASE_REGEX, TEMPLATE_PROJECT_NAME_REGEX, TEMPLATE_PROJECT_NAME_UPPERCASE_REGEX]
    TEMPLATE_GEM_NAME_REGEX = /-\d+.\d+.\d+.gem/

    LANGUAGES = [:ruby]#, :java] # Java not yet supported

    @project_name_part = nil
    @project_name_uppercase_part = nil
    @project_abbrev_part = nil
    @project_abbrev_uppercase_part = nil

    def self.install_ruby(debugging = false, dest = "", overwrite_ok = false, project_name = "", project_abbrev = "")
        install(:ruby, debugging, dest, overwrite_ok, project_name, project_abbrev)
    end

    def self.install_java(debugging = false, dest = "", overwrite_ok = false, project_name = "", project_abbrev = "")
        install(:java, debugging, dest, overwrite_ok, project_name, project_abbrev)
    end

    def self.install(lang = nil, debugging = false, dest = "", overwrite_ok = false, project_name = "", project_abbrev = "")
        $TAFT_DEBUGGING = true if debugging

        unless dest.empty?
            puts "Taft.install has been called with the following parameters :"
            puts "Language             : #{lang}"
            puts "Project name         : #{project_name}"
            puts "Project abbreviation : #{project_abbrev}"
            puts "Destination folder (relative to #{Dir.getwd} if a relative path) : #{dest}"
            puts "Press Enter to continue..."
            gets
        end

        base_wd = Dir.getwd
        dest_base_folder = ""

        if lang == nil
            puts "\nPlease enter the language of this project : #{LANGUAGES.join(", ")}"
            lang = gets.chomp.downcase.to_sym
            raise "TAFT cannot install a new project in that language" unless LANGUAGES.include?(lang)
        end

        if dest.empty?
            puts "\nPlease enter the path of the base folder that TAFT should create, up to and including the name of the base folder"
            puts "TAFT will create this folder if it does not exist"
            puts "If a relative path is entered, it will be taken as being relative to path : #{Dir.getwd}"
            dest = gets.chomp
            raise "The base folder path entered was empty" if dest.empty?

            puts "Does this folder already exist? Entering Y will grant TAFT permission to write into that folder, overwriting any files with matching names that are aready present."
            folder_exists = gets.chomp

            overwrite_ok = (folder_exists == "Y")
        end
        # if dest has been specified in the call, then overwrite_ok has as well

        case lang
        when :ruby
            raw_file_path = "#{File.expand_path(File.dirname(__FILE__))}/taft_files"
            # TODO determine list of gems & put in folder
            # Might be better to output a list of gem install commands instead? What if people are using earlier/later versions of Ruby?
            # bundled_gem_path = "#{File.expand_path(File.dirname(__FILE__))}/bundled_gems"
            # install_gems(bundled_gem_path)
        when :java
            raw_file_path = "#{File.expand_path(File.dirname(__FILE__))}/java_taft_files"
        end

        # TODO does this handle dests like "~/foo" ?
        if (Pathname.new dest).absolute?
            dest_base_folder = dest
        else
            dest_base_folder = File.join(Dir.getwd, dest)
        end
        dest_base_folder = File.expand_path(dest_base_folder)
        puts "TAFT will install to #{dest_base_folder}"

        raise "Folder #{dest_base_folder} already exists, and you did not grant TAFT permission to write into the folder" if Dir.exists?(dest_base_folder) && !overwrite_ok

        # Create the base folder
        begin
            Dir.mkdir(dest_base_folder) unless Dir.exists?(dest_base_folder)
        ensure
            raise "The base folder '#{dest_base_folder}' did not exist" if folder_exists && !Dir.exists?(dest_base_folder)
            raise "The base folder '#{dest_base_folder}' could not be created" unless Dir.exists?(dest_base_folder)
        end

        # Copy the raw files into the base folder, preserving the structure
        FileUtils.copy_entry(raw_file_path, dest_base_folder, false, false, true)

        puts "\nFiles have been copied"
        if project_name.empty?
            puts "\nPlease enter the name of your project (e.g. RED SKY) :"
            project_name = gets.chomp
            raise "The project name entered was empty" if project_name.empty?
        end

        if project_abbrev.empty?
            puts "\nPlease enter the abbreviation of your project (e.g. RS) :"
            project_abbrev = gets.chomp
            raise "The project abbreviation entered was empty" if project_abbrev.empty?
        end


        @project_name_part = project_name.gsub(/[\s-]+/, "_").downcase # TODO use .snakecase ?
        @project_name_uppercase_part = @project_name_part.upcase
        @project_abbrev_part = project_abbrev.gsub(/[\s-]+/, "_").delete("_").downcase # TODO use .snakecase ?
        @project_abbrev_uppercase_part = @project_abbrev_part.upcase

        # Now sweep over the copied files, adjusting the names accordingly
        Taft.adjust_file_names(dest_base_folder, project_name, project_abbrev)

        # Now sweep over the copied files, adjusting the contents accordingly
        Taft.adjust_file_contents(dest_base_folder, project_name, project_abbrev)

        puts "\nFiles have been tailored to your project."

        puts "\nTAFT has installed a tailored copy of the #{lang.capitalize} Automation Framework to #{dest_base_folder}"
        puts "Installation complete."
    end

    # Looks at the names of each file & folder within dest_base_folder and renames them, applying the project_name or project_abbrev as appropriate
    def self.adjust_file_names(dest_base_folder, project_name, project_abbrev)
        pd "Now in #{__method__}; #{dest_base_folder}; #{project_name}; #{project_abbrev}"
        project_file_name_part = project_name.gsub(/[\s-]+/, "_").downcase # TODO use .snakecase ?
        project_file_abbrev_part = project_abbrev.gsub(/[\s-]+/, "_").delete("_").downcase # TODO use .snakecase ?

        pd "project_file_name_part : #{project_file_name_part}" # snakecase
        pd "project_file_abbrev_part : #{project_file_abbrev_part}" # lowercase
        Dir.chdir(dest_base_folder) do
            entries = Dir.entries(dest_base_folder)
            entries.delete(".")
            entries.delete("..")
            entries.each do |f|
                f = File.expand_path(f)
                pd "Now looking at #{f}; is dir? #{Dir.exists?(f)}"
                if Dir.exists?(f) # if this is a dir, call recursively
                    Taft.adjust_file_names(f, project_name, project_abbrev)
                end

                # After processing the contents of the directory, rename it
                # Or if the entry was actually a file, rename it
                basename = File.basename(f, ".*")
                NAMES_AND_ABBREVS_REGEXES.each do |regex|
                    if basename =~ regex
                        ext = File.extname(f)
                        dir = File.split(f)[0]

                        # For the given regex, work out what the replacement text should be
                        case regex.inspect
                        when TEMPLATE_PROJECT_NAME_REGEX
                            replacement = @project_name_part
                        when TEMPLATE_PROJECT_NAME_UPPERCASE_REGEX
                            replacement = @project_name_uppercase_part
                        when TEMPLATE_PROJECT_ABBREV_REGEX
                            replacement = @project_abbrev_part
                        when TEMPLATE_PROJECT_ABBREV_UPPERCASE_REGEX
                            replacement = @project_abbrev_uppercase_part
                        end

                        new_f = basename.gsub(regex, replacement)
                        new_f += ext # must add the extension back on
                        new_f = File.join(dir, new_f) # this is the full path
                        pd "Will rename #{f}\n to       #{new_f}"
                        Taft.delete_file(new_f)
                        File.rename(f, new_f)
                    end
                end
            end
        end
    end

    
    # Looks at the contents of each file within dest_base_folder and edits their contents, applying the project_name or project_abbrev as appropriate
    def self.adjust_file_contents(dest_base_folder, project_name, project_abbrev)
        pd "Now in #{__method__}; #{dest_base_folder}; #{project_name}; #{project_abbrev}"
        raw_name = project_name # should have been entered in form like RED SKY
        project_class_name_part = project_name.gsub(/[\s-]+/, "_").downcase # TODO use .snakecase ?
        project_class_name_uppercase_part = project_name.pascalcase
        project_class_abbrev_part = project_abbrev.gsub(/[\s-]+/, "_").delete("_").downcase # TODO use .snakecase ?
        
        pd "project_class_name_part : #{project_class_name_part}" # snakecase
        pd "project_class_name_uppercase_part : #{project_class_name_uppercase_part}" # pascalcase
        pd "project_class_abbrev_part : #{project_class_abbrev_part}" # lowercase

        Dir.chdir(dest_base_folder) do
            entries = Dir.entries(dest_base_folder)
            entries.delete(".")
            entries.delete("..")
            entries.each do |f|
                f = File.expand_path(f)
                pd "Now looking at #{f}; is dir? #{Dir.exists?(f)}"
                if Dir.exists?(f) # if this is a dir, call recursively
                    Taft.adjust_file_contents(f, project_name, project_abbrev)
                    next
                end

                lines = []
                File.open(f, "r") do |file_obj|
                    lines = file_obj.readlines
                end

                
                # Each line may match more than one regex
                # Hence each line should be passed through all of the regexes, not stopping after the first one it matches
                # i.e. separate if-ends, not one big case-when or if-elsif routine
                lines.each do |line|
                    if line =~ TEMPLATE_PROJECT_NAME_REGEX
                        line.gsub!(TEMPLATE_PROJECT_NAME_REGEX, project_class_name_part)
                    end
                    if line =~ TEMPLATE_PROJECT_NAME_UPPERCASE_REGEX
                        line.gsub!(TEMPLATE_PROJECT_NAME_UPPERCASE_REGEX, project_class_name_uppercase_part)
                    end
                    if line =~ TEMPLATE_PROJECT_ABBREV_REGEX
                        line.gsub!(TEMPLATE_PROJECT_ABBREV_REGEX, project_class_abbrev_part)
                    end
                    if line =~ TEMPLATE_PROJECT_ABBREV_UPPERCASE_REGEX
                        line.gsub!(TEMPLATE_PROJECT_ABBREV_UPPERCASE_REGEX, project_class_abbrev_part.upcase)
                    end
                    if line =~ TEMPLATE_PROJECT_RAW_NAME_REGEX
                        line.gsub!(TEMPLATE_PROJECT_RAW_NAME_REGEX, raw_name)
                    end
                end
                
                File.open(f, "w") do |file_obj|
                    file_obj.puts lines
                end
            end
        end
    end

    def self.delete_file(abs_file_path)
        if Dir.exists?(abs_file_path)
            FileUtils.remove_dir(abs_file_path)
        elsif File.exists?(abs_file_path)            
            File.delete(abs_file_path)
        end
    end

    def self.install_gems(bundled_gem_path)
        puts "\nWill first install all gems bundled in with the TAFT gem."

        gem_list = Dir.entries(bundled_gem_path)
        gem_list.delete(".")
        gem_list.delete("..")
        gems_to_install = []
        gem_list.each do |gem_name|
            # For each gem, try to require it. Only install those that couldn't be required.
            begin
                gem_base_name = gem_name.gsub(TEMPLATE_GEM_NAME_REGEX, "")
                require gem_base_name
            rescue LoadError
                puts "#{gem_base_name} could not be required; will install #{gem_name}"
                gems_to_install << gem_name
            end
        end

        if gems_to_install.empty?
            puts "All required gems are already installed"
        else
            puts "Will install the following gems :"
            gems_to_install.each {|gem_name| puts gem_name }

            Dir.chdir(bundled_gem_path) # set this to be the working directory while installing the gems
            gems_to_install.each do |gem_name|
                puts "\nNow installing #{gem_name}..."
                system("gem install #{gem_name}")
                puts "Gem installed."
            end
            Dir.chdir(base_wd) # reset the working directory
        end
    end

end
