require 'open3'

class Xlo
  attr_accessor :rnv, :xmllint, :csv

  def initialize(_file)
    @rnv = []
    @xmllint = []
    @csv = File.new(_file,"w+")
    @csv << "type; error; freq; files \n"
    @error = {}
  end

  def rnv_wrapper (_rnc, _dir)
    Dir[_dir + "/" + "*.xml"].each do |file|
      stdout = Open3.capture3("rnv #{_rnc} #{file}")
      stdout = stdout[1].split("\n")
      stdout.each do |line|
        @rnv << line
      end
    end
  end

  def rnv_aggregate
    @rnv.each do |el|
      if (el.include?("error") && !el.include?("are invalid"))

        type = el.split("error")[1].split(" ")[1]

        if (type == "attribute" || type == "element")
          key =  type + "; " + el[/\^.*/][1..-1]
          filename = File.basename(el.split("error")[0])
          filename[filename.length - 2] = ""
        else
          type = "other"
          key = type + "; " + el.split("error:")[1]
          filename = File.basename(el.split("error")[0])
          filename[filename.length - 2] = ""
        end

        if (@error.has_key?(key))
          @error[key] <<  " || " + filename
        else
          @error[key] = filename
        end

      end
    end
  end

  def xmllint_wrapper (_dir)
    Dir[_dir + "/" + "*.xml"].each do |file|
      stdout = Open3.capture3("xmllint #{file}")
      stdout = stdout[1].split("\n")
      stdout.each do |line|
          @xmllint << line
      end
    end
  end

  def xmllint_aggregate

    @xmllint.delete_if {|el| el.include?("^")}
    @xmllint.map { |e| e.chomp  }
    @xmllint = @xmllint.values_at(* @xmllint.each_index.select {|i| i.even?})
    @xmllint.each do |el|
      split_el = el.split(" ")
      type = el[/element|attribute|parser error/]
      key = type + ";" + el.split(":")[-1]
      filename =  File.basename(split_el[0])[0..-2]
      if (@error.has_key?(key))
        @error[key] <<  " || " + filename
      else
        @error[key] = filename
      end
    end
  end

  def csv_writer
    @error.each do |entry|
        line =  entry.dup
        line[-1] = line[-1].split("||")[0..50].join
        freq = entry[1].split("||").length
        @csv.write(line.insert(1, freq.to_s).join(";")[0..-2] +  "\n" )
      end
  end

  def self.main(_rnv_arg,_folder_arg)

    xlo = Xlo.new(File.new("error.csv",  "w+"))

    xlo.rnv_wrapper(_rnv_arg, _folder_arg)
    xlo.rnv_aggregate

    xlo.xmllint_wrapper(_folder_arg)
    xlo.xmllint_aggregate

    xlo.csv_writer
  end
end
