require 'json'
require 'pry'
class Csv2json::CLI 

    def build_hash (row) 
        hash = Hash.new
        @headers.each do | field |
            val = row.shift
            if val 
                if isPrice? field
                    val = (val[0]=='$') ? val.delete("$,") : val;
                elsif isDate? field
                    vals = val.split('/').map{ |e| format('%02d', e) } 
                    val = "#{vals[2]}-#{vals[0]}-#{vals[1]}"
                end
                val = val.strip
            end
            hash[field]= val
        end
        hash
    end

    def isPrice?(str)
        str =~ /price/i
    end

    def isDate?(str)
        str =~ /date/i
    end

    def get_file_names
        puts "enter input csv file"
        @input_file = gets.chomp
        puts "enter output text file"
        @output_file = gets.chomp 
    end

 #TODO: mapping set the type : if heading is price, set to long, if heading has date, set to date
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
        rows.each_with_index do | row, index |
            json_string = "{\"index\": { \"_id\": #{index+1}}}\n"
            json_string += JSON.dump build_hash row
            json_string += "\n"
            file.write json_string
        end
        file.close

        puts "success!"
    end

end