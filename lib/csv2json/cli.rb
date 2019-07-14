require 'json'
require 'pry'
class Csv2json::CLI 

    def build_hash (row) 
        hash = Hash.new
        @headers.each do | field |
            hash[field]=row.shift
        end
        hash
    end

    def pretty_print (hash)
        puts JSON.pretty_generate(hash)
    end

    def get_file_names
        puts "enter input csv file"
        @input_file = gets.chomp
        puts "enter output text file"
        @output_file = gets.chomp 
    end

    # def endFieldsCheck(index,last)
    #     index == last ? "}" 
    def get_mappings
        mappings = <<~JS
        {
            \"properties\": {
        JS

        last_index = @headers.length - 1
        @headers.each_with_index do |field, index|
            mappings+= <<-JS
            \"#{field}\": {
                "type": "text",
                "fields": {
                    "keyword": {
                        "type": "keyword",
                        "ignore_above": 256
                    }
                }
            }#{index == last_index ? "" : ","}
            JS
        end
        mappings+= <<~JS
            }
        }
        JS
        mappings
    end

    def call
        puts "csv 2 json"

        get_file_names
        puts "Converting CSV data from #{@input_file} to JSON string data in #{@output_file}"

        rows = CSV.read(@input_file)
        file = File.open(@output_file, "w")

        @headers = rows.shift
        file.write "mappings=#{get_mappings}"

        file.write "\nbulk data=" 
        rows_last_index = rows.count - 1      
        rows.each_with_index do | row, index |
            json_string = JSON.pretty_generate build_hash row
            json_string += (index == rows_last_index) ? "\n" : ",\n" 
            file.write json_string
        end
        file.close

        puts "success!"
    end

end