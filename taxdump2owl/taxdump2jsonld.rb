#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'optparse'
require 'fileutils'

module TaxonomyJSON
  TAX     = 'http://ddbj.nig.ac.jp/ontologies/taxonomy/'
  TAXID   = 'http://identifiers.org/taxonomy/'
  PUBMED  = 'http://identifiers.org/pubmed/'
  TAXNCBI = 'http://www.ncbi.nlm.nih.gov/taxonomy/'

  NAME_CLASS_TO_PROP = {
    'scientific name'       => 'scientificName',
    'authority'             => 'authority',
    'synonym'               => 'synonym',
    'preferred synonym'     => 'preferredSynonym',
    'acronym'               => 'acronym',
    'preferred acronym'     => 'preferredAcronym',
    'anamorph'              => 'anamorph',
    'teleomorph'            => 'teleomorph',
    'misnomer'              => 'misnomer',
    'common name'           => 'commonName',
    'preferred common name' => 'preferredCommonName',
    'in-part'               => 'inPart',
    'includes'              => 'includes',
    'equivalent name'       => 'equivalentName',
    'misspelling'           => 'misspelling',
    'type material'         => 'typeMaterial',
    'genbank acronym'       => 'genbankAcronym',
    'genbank anamorph'      => 'genbankAnamorph',
    'genbank common name'   => 'genbankCommonName',
    'genbank synonym'       => 'genbankSynonym',
    'blast name'            => 'blastName',
    'unpublished name'      => 'unpublishedName'
  }.freeze

  RANK_CLASS = {
    'class'            => 'Class',
    'family'           => 'Family',
    'forma'            => 'Forma',
    'genus'            => 'Genus',
    'infraclass'       => 'Infraclass',
    'infraorder'       => 'Infraorder',
    'kingdom'          => 'Kingdom',
    'no rank'          => 'NoRank',
    'order'            => 'Order',
    'parvorder'        => 'Parvorder',
    'phylum'           => 'Phylum',
    'species'          => 'Species',
    'species group'    => 'SpeciesGroup',
    'species subgroup' => 'SpeciesSubgroup',
    'subclass'         => 'Subclass',
    'subfamily'        => 'SubFamily',
    'subgenus'         => 'SubGenus',
    'subkingdom'       => 'SubKingdom',
    'suborder'         => 'SubOrder',
    'subphylum'        => 'SubPhylum',
    'subspecies'       => 'SubSpecies',
    'subtribe'         => 'SubTribe',
    'superclass'       => 'SuperClass',
    'superfamily'      => 'SuperFamily',
    'superkingdom'     => 'SuperKingdom',
    'superorder'       => 'SuperOrder',
    'superphylum'      => 'SuperPhylum',
    'tribe'            => 'Tribe',
    'varietas'         => 'Varietas',
    'strain'           => 'Strain',
    'isolate'          => 'Isolate',
    'serotype'         => 'Serotype',
    'clade'            => 'Clade',
    'forma specialis'  => 'FormaSpecialis',
    'section'          => 'Section',
    'serogroup'        => 'Serogroup',
    'subsection'       => 'SubSection',
    'genotype'         => 'Genotype',
    'biotype'          => 'Biotype',
    'morph'            => 'Morph',
    'series'           => 'Series',
    'subvariety'       => 'SubVariety',
    'pathogroup'       => 'Pathogroup',
    'cohort'           => 'Cohort',
    'subcohort'        => 'SubCohort'
  }.freeze

  module_function

  def context_hash
    {
      '@base' => TAX,
      'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
      'rdfs' => 'http://www.w3.org/2000/01/rdf-schema#',
      'owl' => 'http://www.w3.org/2002/07/owl#',
      'xsd' => 'http://www.w3.org/2001/XMLSchema#',
      'dcterms' => 'http://purl.org/dc/terms/',
      'tax' => TAX,
      'taxid' => TAXID,
      'pubmed' => PUBMED,

      'label' => 'rdfs:label',
      'comment' => 'rdfs:comment',
      'seeAlso' => { '@id' => 'rdfs:seeAlso', '@type' => '@id' },
      'subClassOf' => { '@id' => 'rdfs:subClassOf', '@type' => '@id' },

      'rank' => { '@id' => 'tax:rank', '@type' => '@id' },
      'merged' => { '@id' => 'tax:merged', '@type' => '@id' },

      'citation' => 'tax:citation',
      'citationPubMed' => { '@id' => 'tax:citationPubMed', '@type' => '@id' },
      'citationURL' => 'tax:citationURL',
      'citationKey' => 'tax:citationKey',
      'citationText' => 'tax:citationText',

      'geneticCode' => { '@id' => 'tax:geneticCode', '@type' => '@id' },
      'geneticCodeMt' => { '@id' => 'tax:geneticCodeMt', '@type' => '@id' },
      'geneticCodePt' => { '@id' => 'tax:geneticCodePt', '@type' => '@id' },

      'name' => 'tax:name',
      'scientificName' => 'tax:scientificName',
      'authority' => 'tax:authority',
      'synonym' => 'tax:synonym',
      'preferredSynonym' => 'tax:preferredSynonym',
      'acronym' => 'tax:acronym',
      'preferredAcronym' => 'tax:preferredAcronym',
      'anamorph' => 'tax:anamorph',
      'teleomorph' => 'tax:teleomorph',
      'misnomer' => 'tax:misnomer',
      'commonName' => 'tax:commonName',
      'preferredCommonName' => 'tax:preferredCommonName',
      'inPart' => 'tax:inPart',
      'includes' => 'tax:includes',
      'equivalentName' => 'tax:equivalentName',
      'misspelling' => 'tax:misspelling',
      'typeMaterial' => 'tax:typeMaterial',
      'genbankAcronym' => 'tax:genbankAcronym',
      'genbankAnamorph' => 'tax:genbankAnamorph',
      'genbankCommonName' => 'tax:genbankCommonName',
      'genbankSynonym' => 'tax:genbankSynonym',
      'blastName' => 'tax:blastName',
      'unpublishedName' => 'tax:unpublishedName',
      'uniqueName' => 'tax:uniqueName',
      'formalNameIndicator' => { '@id' => 'tax:formalNameIndicator', '@type' => 'xsd:boolean' },
      'genbankHiddenFlag' => { '@id' => 'tax:genbankHiddenFlag', '@type' => 'xsd:boolean' },
      'hiddenSubtreeRootFlag' => { '@id' => 'tax:hiddenSubtreeRootFlag', '@type' => 'xsd:boolean' }
    }
  end

  def context_document
    { '@context' => context_hash }
  end

  def taxon_uri(tax_id)
    "#{TAXID}#{tax_id}"
  end

  def rank_uri(rank_name)
    "#{TAX}#{RANK_CLASS.fetch(rank_name, 'NoRank')}"
  end

  def gencode_uri(code_id)
    "#{TAX}GeneticCode#{code_id}"
  end

  def ncbi_uri(tax_id)
    "#{TAXNCBI}#{tax_id}"
  end

  def pubmed_uri(pubmed_id)
    "#{PUBMED}#{pubmed_id}"
  end
end

class TaxdumpReader
  def initialize(dir)
    @dir = dir
    @names = Hash.new { |h, k| h[k] = [] }
    @labels = {}
    @unique_names = Hash.new { |h, k| h[k] = [] }
    @formal_name = {}
    @merged = Hash.new { |h, k| h[k] = [] }
    @citations = Hash.new { |h, k| h[k] = [] }
  end

  def load_all
    read_names
    read_merged
    read_citations
    self
  end

  def each_node(format: :jsonld, context_ref: nil)
    return enum_for(:each_node, format: format, context_ref: context_ref) unless block_given?

    File.foreach(path('nodes.dmp'), chomp: true) do |line|
      fields = dmp_fields(line)
      next if fields.length < 13

      tax_id,
      parent_tax_id,
      rank,
      _embl_code,
      _division_id,
      _inherited_div_flag,
      genetic_code_id,
      _inherited_gc_flag,
      mitochondrial_genetic_code_id,
      _inherited_mgc_flag,
      genbank_hidden_flag,
      hidden_subtree_root_flag,
      comments = fields

      yield build_common_node(
        tax_id: tax_id,
        parent_tax_id: parent_tax_id,
        rank: rank,
        genetic_code_id: genetic_code_id,
        mitochondrial_genetic_code_id: mitochondrial_genetic_code_id,
        genbank_hidden_flag: genbank_hidden_flag,
        hidden_subtree_root_flag: hidden_subtree_root_flag,
        comments: comments,
        format: format,
        context_ref: context_ref
      )
    end
  end

  private

  def build_common_node(tax_id:, parent_tax_id:, rank:, genetic_code_id:, mitochondrial_genetic_code_id:, genbank_hidden_flag:, hidden_subtree_root_flag:, comments:, format:, context_ref:)
    node =
      if format == :jsonld
        {
          '@context' => context_ref,
          '@id' => TaxonomyJSON.taxon_uri(tax_id),
          '@type' => ['owl:Class', 'tax:Taxon'],
          'seeAlso' => { '@id' => TaxonomyJSON.ncbi_uri(tax_id) },
          'rank' => { '@id' => TaxonomyJSON.rank_uri(rank) },
          'geneticCode' => { '@id' => TaxonomyJSON.gencode_uri(genetic_code_id) },
          'geneticCodeMt' => { '@id' => TaxonomyJSON.gencode_uri(mitochondrial_genetic_code_id) }
        }
      else
        {
          'id' => TaxonomyJSON.taxon_uri(tax_id),
          'type' => ['owl:Class', 'tax:Taxon'],
          'seeAlso' => TaxonomyJSON.ncbi_uri(tax_id),
          'rank' => TaxonomyJSON.rank_uri(rank),
          'geneticCode' => TaxonomyJSON.gencode_uri(genetic_code_id),
          'geneticCodeMt' => TaxonomyJSON.gencode_uri(mitochondrial_genetic_code_id)
        }
      end

    unless tax_id == parent_tax_id
      node['subClassOf'] =
        if format == :jsonld
          { '@id' => TaxonomyJSON.taxon_uri(parent_tax_id) }
        else
          TaxonomyJSON.taxon_uri(parent_tax_id)
        end
    end

    label = @labels[tax_id]
    if label
      node['label'] = label
      node['scientificName'] = label
    end

    @names[tax_id].each do |name_class, name_txt|
      prop = TaxonomyJSON::NAME_CLASS_TO_PROP[name_class]
      next unless prop
      next if prop == 'scientificName'
      append_value(node, prop, name_txt)
    end

    uniqs = @unique_names[tax_id]
    node['uniqueName'] = uniqs if uniqs && !uniqs.empty?

    if @merged.key?(tax_id) && !@merged[tax_id].empty?
      node['merged'] =
        if format == :jsonld
          @merged[tax_id].map { |old_id| { '@id' => TaxonomyJSON.taxon_uri(old_id) } }
        else
          @merged[tax_id].map { |old_id| TaxonomyJSON.taxon_uri(old_id) }
        end
    end

    if @citations.key?(tax_id) && !@citations[tax_id].empty?
      node['citation'] = convert_citations(@citations[tax_id], format)
    end

    node['comment'] = comments unless comments.nil? || comments.empty?
    node['genbankHiddenFlag'] = (genbank_hidden_flag == '1')
    node['hiddenSubtreeRootFlag'] = (hidden_subtree_root_flag == '1')
    node['formalNameIndicator'] = @formal_name[tax_id] if @formal_name.key?(tax_id)

    node
  end

  def convert_citations(citations, format)
    return citations if format == :jsonld

    citations.map do |c|
      x = {}
      x['id'] = c['@id'] if c['@id']
      x['citationPubMed'] = c.dig('citationPubMed', '@id') if c['citationPubMed']
      x['citationURL'] = c['citationURL'] if c['citationURL']
      x['citationKey'] = c['citationKey'] if c['citationKey']
      x['citationText'] = c['citationText'] if c['citationText']
      x
    end
  end

  def path(name)
    File.join(@dir, name)
  end

  def dmp_fields(line)
    line.sub(/\t\|\s*\z/, '').split("\t|\t", -1).map(&:strip)
  end

  def read_names
    File.foreach(path('names.dmp'), chomp: true) do |line|
      tax_id, name_txt, unique_name, name_class = dmp_fields(line)
      @names[tax_id] << [name_class, name_txt]
      @labels[tax_id] = name_txt if name_class == 'scientific name'
      @unique_names[tax_id] << unique_name unless unique_name.nil? || unique_name.empty?
      @formal_name[tax_id] ||= false
    end
  end

  def read_merged
    file = path('merged.dmp')
    return unless File.exist?(file)

    File.foreach(file, chomp: true) do |line|
      old_tax_id, new_tax_id = dmp_fields(line)
      @merged[new_tax_id] << old_tax_id
    end
  end

  def read_citations
    file = path('citations.dmp')
    return unless File.exist?(file)

    File.foreach(file, chomp: true) do |line|
      citation_id, citation_key, pubmed_id, _medline_id, url, text, taxid_list = dmp_fields(line)

      citation_node = { '@id' => "#{TaxonomyJSON::TAX}citation/#{citation_id}" }
      citation_node['citationPubMed'] = { '@id' => TaxonomyJSON.pubmed_uri(pubmed_id) } unless pubmed_id.nil? || pubmed_id.empty? || pubmed_id == '0'
      citation_node['citationURL'] = url unless url.nil? || url.empty?
      citation_node['citationKey'] = citation_key unless citation_key.nil? || citation_key.empty?
      citation_node['citationText'] = unescape_ncbi_text(text) unless text.nil? || text.empty?

      next if taxid_list.nil? || taxid_list.empty?

      taxid_list.split(/\s+/).each do |tax_id|
        @citations[tax_id] << citation_node
      end
    end
  end

  def unescape_ncbi_text(text)
    text
      .gsub('\\\\', "\\")
      .gsub('\n', "\n")
      .gsub('\t', "\t")
      .gsub('\"', '"')
  end

  def append_value(node, prop, value)
    return if value.nil? || value.empty?

    if node.key?(prop)
      node[prop] = [node[prop]] unless node[prop].is_a?(Array)
      node[prop] << value
    else
      node[prop] = value
    end
  end
end

class StreamingWriter
  def initialize(io, pretty: false, format: :jsonld)
    @io = io
    @pretty = pretty
    @format = format
  end

  def write_nodes(nodes_enum)
    if @format == :jsonld
      write_jsonld_lines(nodes_enum)
    else
      write_json_lines(nodes_enum)
    end
  end

  private

  def write_jsonld_lines(nodes_enum)
    nodes_enum.each do |node|
      if @pretty
        @io.write(JSON.pretty_generate(node))
        @io.write("\n")
      else
        @io.write(JSON.generate(node))
        @io.write("\n")
      end
    end
  end

  def write_json_lines(nodes_enum)
    nodes_enum.each do |node|
      if @pretty
        @io.write(JSON.pretty_generate(node))
        @io.write("\n")
      else
        @io.write(JSON.generate(node))
        @io.write("\n")
      end
    end
  end
end

def write_context_file(path, pretty: true)
  File.open(path, 'wb') do |f|
    if pretty
      f.write(JSON.pretty_generate(TaxonomyJSON.context_document))
      f.write("\n")
    else
      f.write(JSON.generate(TaxonomyJSON.context_document))
      f.write("\n")
    end
  end
end

options = {
  pretty: false,
  output: '-',
  format: 'jsonld',
  context_output: nil,
  context_ref: nil
}

OptionParser.new do |opts|
  opts.banner = 'Usage: ruby taxdump2jsonld.rb TAXDUMP_DIR [--format jsonld|json] [-o FILE] [--context-output FILE] [--context-ref REF] [--pretty]'

  opts.on('--pretty', 'Pretty-print each record (JSON Lines / JSON-LD Lines では非推奨)') do
    options[:pretty] = true
  end

  opts.on('-o', '--output FILE', 'Write node lines to FILE instead of STDOUT') do |v|
    options[:output] = v
  end

  opts.on('--format FORMAT', 'Output format: jsonld or json') do |v|
    options[:format] = v
  end

  opts.on('--context-output FILE', 'Write JSON-LD context document to FILE') do |v|
    options[:context_output] = v
  end

  opts.on('--context-ref REF', 'Context reference to embed in each JSON-LD line, e.g. taxonomy.context.jsonld or URL') do |v|
    options[:context_ref] = v
  end
end.parse!

taxdump_dir = ARGV.shift
abort 'TAXDUMP_DIR is required' unless taxdump_dir
abort "Directory not found: #{taxdump_dir}" unless Dir.exist?(taxdump_dir)

unless %w[jsonld json].include?(options[:format])
  abort "Unsupported format: #{options[:format]} (use jsonld or json)"
end

required_files = %w[nodes.dmp names.dmp]
missing = required_files.reject { |f| File.exist?(File.join(taxdump_dir, f)) }
abort "Missing required files: #{missing.join(', ')}" unless missing.empty?

if options[:format] == 'jsonld'
  options[:context_output] ||= begin
    if options[:output] == '-'
      'taxonomy.context.jsonld'
    else
      "#{options[:output]}.context.jsonld"
    end
  end

  options[:context_ref] ||= File.basename(options[:context_output])
end

reader = TaxdumpReader.new(taxdump_dir).load_all

if options[:format] == 'jsonld'
  context_dir = File.dirname(options[:context_output])
  FileUtils.mkdir_p(context_dir) unless context_dir == '.'
  write_context_file(options[:context_output], pretty: true)
end

io =
  if options[:output] == '-'
    STDOUT.binmode
  else
    output_dir = File.dirname(options[:output])
    FileUtils.mkdir_p(output_dir) unless output_dir == '.'
    File.open(options[:output], 'wb')
  end

begin
  writer = StreamingWriter.new(
    io,
    pretty: options[:pretty],
    format: options[:format].to_sym
  )

  writer.write_nodes(
    reader.each_node(
      format: options[:format].to_sym,
      context_ref: options[:context_ref]
    )
  )
ensure
  io.close unless io.equal?(STDOUT)
end