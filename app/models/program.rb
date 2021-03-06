class Program < ActiveRecord::Base
  attr_accessible :graduating_salary, :institution_id, :name, :tag_ids
  #Relationships
  belongs_to :institution
  has_many :program_tags
  has_many :user_programs
  has_many :reviews
  has_many :users, :through => :user_programs
  has_many :tags, :through => :program_tags

  validates_presence_of :institution
  validates_numericality_of :graduating_salary, :only_integer => true, :greater_than_or_equal_to => 0
  
  scope :for_institution, lambda {|institution| where("institution_id = ?", "#{institution.id}") }


  #Returns top five tags for a program. First retrives tags, sorts them. Reverses list so goes in decreasing order then returns first five
  def tfivetags
    tag_array = self.tags
    sort_array = tag_array.sort!{|a,b| a.reputation_for(:votes) <=> b.reputation_for(:votes)}
    sort_array.reverse!
    topfive = sort_array.take(5)
    topfive
  end
  # ==============================================

  # Find all program_tags that share the query tags
  def self.search_by_tag(query)
    sql = "SELECT DISTINCT program_tags.program_id, program_tags.tag_id
          FROM program_tags
          INNER JOIN tags
          ON program_tags.tag_id = tags.id
          WHERE"
     
    query = query.downcase
    @tags = query.split(', ')
    @queryTagSet = @tags.to_set
    last = @tags.pop
    @tags.each do |tag|
      sql += " tags.name ILIKE \'%#{tag}%\' OR "
    end
    sql += " tags.name ILIKE '%#{last}%' "
    @programs = []
     
    @results = ActiveRecord::Base.connection.execute(sql)
     
    # Return unique programs that have ALL tags
    @results.each do |r|
      @tagSet = Set.new
      program = Program.find(r["program_id"])
      program.tags.each do |tag|
        @tagSet << tag.name.downcase
      end
      if (@queryTagSet.subset?(@tagSet))
        @programs << program.name #returing progam name only
      end
    end
    @programs.uniq
  end
  # ===========================================


end
