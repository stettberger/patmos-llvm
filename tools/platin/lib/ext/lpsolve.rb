#
# PLATIN tool set
#
# Bindings to lp_solve
#
require 'platin'
include PML
begin
  require 'rubygems'
  require "lpsolve"
rescue Exception => details
  warn "Failed to load library lpsolve"
  info "  ==> aptitude install liblpsolve55-dev [Debian/Ubuntu]"
  info "  ==> gem1.9.1 install lpsolve --pre"
  die "Failed to load required ruby libraries"
end

# Simple interface to lp_solve
class LpSolveILP < ILP
  # Tolarable floating point error in objective
  EPS=0.0001
  def initialize(options = nil)
    super(options)
    @eps = EPS
    @do_diagnose = true
  end
  # run solver to find maximum cost
  def solve_max
    # create LP problem (maximize)
    lp = create_lp
    lp.set_maxim
    # set objective and add constraints
    lp.set_add_rowmode(true)
    set_objective(lp)
    add_linear_constraints(lp)
    # solve
    lp.set_add_rowmode(false)
    lp.print_lp if options.lp_debug
    lp.set_verbose(0)

    self.dump($stderr) if options.debug
    r = lp.solve

    # read solution
    lp.print_solution(-1) if options.lp_debug
    obj = lp.objective
    freqmap = extract_frequencies(lp.get_variables)
    if (r == LPSolve::INFEASIBLE)
      diagnose_infeasible(r, freqmap) if @do_diagnose
    elsif (r == LPSolve::UNBOUNDED)
      diagnose_unbounded(r, freqmap) if @do_diagnose
    end
    lp_solve_error(r) unless r == 0
    if (obj-obj.round.to_f).abs > @eps
      raise Exception.new("Untolerable floating point inaccuracy > #{EPS} in objective #{obj}")
    end

    [obj.round, freqmap ]
  end

  private
  # create an LP with variables
  def create_lp
    lp = LPSolve.new(0, variables.size)
    variables.each do |v|
      ix = index(v)
      lp.set_col_name(ix, "v_#{ix}")
      lp.set_int(ix, true)
    end
    lp
  end
  # set LP ovjective
  def set_objective(lp)
    lp.set_obj_fnex(@costs.map { |v,c| [index(v),c] })
  end
  # add LP constraints
  def add_linear_constraints(lp)
    @constraints.each do |constr|
      v =  lp.add_constraintex(constr.name,constr.lhs.to_a,lpsolve_op(constr.op),constr.rhs)
      if ! v
        dump($stderr)
        die("constraintex #{constr} failed with return value #{v.inspect}")
      end
    end
  end
  # extract solution vector
  def extract_frequencies(fs)
    vmap = {}
    fs.each_with_index do |v, ix|
      vmap[@variables[ix]] = v if v != 0
    end
    vmap
  end
  # lp-solve comparsion operators
  def lpsolve_op(op)
    case op
    when "equal"
      LPSolve::EQ
    when "less-equal"
      LPSolve::LE
    when "greater-equal"
      LPSolve::GE
    else
      internal_error("Unsupported comparison operator #{op}")
    end
  end
  def lp_solve_error_msg(r)
      case r
      when LPSolve::NOMEMORY
        "NOMEMORY"
      when LPSolve::SUBOPTIMAL
        "SUBOPTIMAL"
      when LPSolve::INFEASIBLE
        "INFEASIBLE"
      when LPSolve::UNBOUNDED
        "UNBOUNDED"
      else
        "ERROR_#{r}"
      end
  end
  def lp_solve_error(r)
    raise Exception.new("LPSolver Error: #{lp_solve_error_msg(r)} (E#{r})")
  end

  SLACK=10000000
  BIGM= 10000000
  def diagnose_unbounded(problem, freqmap)
    $stderr.puts "#{lp_solve_error_msg(problem)} PROBLEM - starting diagnosis"
    @do_diagnose = false
    variables.each do |v|
      add_constraint([[v,1]],"less-equal",BIGM,"__debug_upper_bound_v#{index(v)}",:debug)
    end
    @eps = 1.0
    cycles,freq = self.solve_max
    freq.each do |v,k|
      if k >= BIGM - 1.0
        $stderr.puts "UNBOUNDED: #{v.to_s.ljust(40)} #{k.to_s.rjust(8)}"
      end
    end
    @do_diagnose = true
  end

  def diagnose_infeasible(problem, freqmap)
    $stderr.puts "#{lp_solve_error_msg(problem)} PROBLEM - starting diagnosis"
    @do_diagnose = false
    old_constraints, slackvars = @constraints, []
    reset_constraints
    variables.each do |v|
      add_constraint([[v,1]],"less-equal",BIGM,"__debug_upper_bound_v#{index(v)}",:debug)
    end
    old_constraints.each { |constr|
      n = constr.name
      next if n =~ /__positive_/
      # only relax flow facts, assuming structural constraints are correct
      if constr.name =~ /^ff/
        v_lhs = add_variable("__slack_#{n}",:slack,0, BIGM)
        add_cost("__slack_#{n}", -SLACK)
        constr.set(v_lhs, -1)
        if constr.op == "equal"
          v_rhs = add_variable("__slack_#{n}_rhs",:slack,0, BIGM)
          add_cost("__slack_#{n}_rhs", -SLACK)
          constr.set(v_rhs, 1)
        end
      end
      add_indexed_constraint(constr.lhs,constr.op,constr.rhs,"__slack_#{n}",Set.new([:slack]))
    }
    @eps = 1.0
    # @constraints.each do |c|
    #   puts "Slacked constraint #{n}: #{c}"
    # end
    cycles,freq = self.solve_max
    freq.each do |v,k|
      if v.to_s =~ /__slack/ && k != 0
        $stderr.puts "SLACK: #{v.to_s.ljust(40)} #{k.to_s.rjust(8)}"
      end
    end
    $stderr.puts "Finished diagnosis with objective #{cycles}"
    @do_diagnose = true
  end
end
