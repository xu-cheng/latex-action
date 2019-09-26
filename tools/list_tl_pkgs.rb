#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"
require "optparse"
require "pathname"
require "set"

PREINST_PKGS = %w[
  scheme-small
  collection-fontsrecommended
  biblatex
].freeze

def error(msg)
  if $stderr.tty?
    pre = "\033[31m"
    post = "\033[0m"
  end
  abort "#{pre}Error#{post}: #{msg}"
end

def locate_texmfdist
  cmd = %w[kpsewhich -var-value=TEXMFDIST]
  output, _status = Open3.capture2(*cmd)
  output.strip
rescue StandardError => e
  error "Fail to execute `#{cmd.join " "}`\n#{e.message}"
end

def read_tlpdb
  cmd = %w[tlmgr dump-tlpdb --json --local]
  output, _status = Open3.capture2(*cmd)
  JSON.parse output
rescue StandardError => e
  error "Fail to execute `#{cmd.join " "}`\n#{e.message}"
end

def build_mapping(db)
  file_pkg_mapping = {}
  pkg_deps_mapping = {}
  db["main"]["tlpkgs"].each do |pkg|
    name = pkg["name"]
    pkg["runfiles"].each do |file|
      file_pkg_mapping[file] = name
    end
    pkg_deps_mapping[name] = pkg["depends"]
  end
  [file_pkg_mapping, pkg_deps_mapping]
end

def list_preinst_pkgs(pkg_deps_mapping)
  all_pkgs = Set.new
  pkgs = Set.new(PREINST_PKGS)
  until pkgs.empty?
    all_pkgs |= pkgs
    pkgs = Set.new(pkgs.flat_map { |pkg| pkg_deps_mapping[pkg] }.compact)
  end
  all_pkgs
end

if $PROGRAM_NAME == __FILE__
  subtract_preinst = true
  parser = OptionParser.new do |opts|
    opts.banner = <<~BANNER
      Usage: #{$PROGRAM_NAME} [options] <root_file>

      List all texlive packages used by a document.

      Arguments:
          <root_file>                      Path to the root TeX file
    BANNER

    opts.separator ""
    opts.separator "Options:"
    opts.on("--list-all", "Include preinstalled packages in Github Action") do
      subtract_preinst = false
    end
    opts.on("-h", "--help", "Show this message") do
      puts opts.help
      exit
    end
  end
  parser.parse!

  abort parser.help if ARGV.size != 1
  root_file = Pathname.new ARGV[0]
  fls_file = root_file.parent / "#{root_file.basename ".*"}.fls"

  unless fls_file.file?
    error <<~ERROR
      Cannot find the file <#{fls_file}>.
      Please compile the document using latexmk.
    ERROR
  end

  db = read_tlpdb
  file_pkg_mapping, pkg_deps_mapping = build_mapping db
  texmfdist = locate_texmfdist
  texmfdist_parent = "#{File.dirname texmfdist}/"

  pkgs = Set.new
  fls_file.readlines.each do |line|
    next unless line.start_with? "INPUT"

    input_file = line.strip.rpartition(" ").last

    next unless input_file.start_with? texmfdist

    pkgs << file_pkg_mapping[input_file.sub texmfdist_parent, ""]
  end

  preinst_pkgs = list_preinst_pkgs pkg_deps_mapping
  pkgs.subtract(preinst_pkgs) if subtract_preinst
  puts pkgs.to_a.sort.join(" ")
end
