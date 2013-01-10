require File.join(File.dirname(__FILE__),"utils.rb")
include PMLUtils

class AISExporter
    attr_reader :outfile
    def initialize(outfile)
	@outfile = outfile
    end

    # Generate a global AIS header
    def gen_header(data)
	# TODO get compiler type depending on YAML arch type
	@outfile.puts "#compiler"
	@outfile.puts "compiler \"patmos-llvm\";"
	@outfile.puts ""

	#@outfile.puts "#clock rate"
	#@outfile.puts "clock exactly 24 MHz;"
	#@outfile.puts ""

	# TODO any additional header stuff to generate (context, entry, ...)?
    end

    # Export flow facts from a machine-function entry
    def export_function(func)
      func['blocks'].each do |mbb|
        branches = 0
        mbb['instructions'].each do |ins|
          branches += 1 if ins['branch-type'] && ins['branch-type'] != "none"
          if ins['branch-type'] == 'any'
            label = get_mbb_label(func['name'],mbb['name'])
            instr = "#{dquote(label)} + #{branches} branches"
	    successors = ins['branch-targets'] ? ins['branch-targets'] : mbb['successors']
            targets = successors.uniq.map { |succ_name|
              dquote(get_mbb_label(func['name'],succ_name))
            }.join(", ")
            @outfile.puts "instruction #{instr} branches to #{targets};"
          end
        end
      end
    end

end

class AisExportTool
  def AisExportTool.run(pml, of, options)
    outfile = if ! of || of == "-"
              then $>
              else File.new(of,"w")
              end
    # export
    ais = AISExporter.new(outfile)
    ais.gen_header(pml.data) if options.header

    pml['machine-functions'].each do |func|
      ais.export_function(func)
    end
    outfile.close
  end
  def AisExportTool.add_options(opts,options)
    opts.on("-o", "--output FILE.ais", "AIS file to generate") { |f| options.output = f }
    opts.on("-g", "--header", "Generate AIS header") { |f| options.header = f }
  end
end
