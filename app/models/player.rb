class Player < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  attr_accessor :login

  self.per_page = 25

  ###############################################
  # VALIDATION AND HOOKS                        #
  ###############################################

  before_save :update_parameterized_username
  before_update :update_parameterized_username
  after_create :add_to_global
  after_create :add_to_mit

  validates_format_of :username, with: /\A[A-Za-z0-9_.\-]+\Z/

  def update_parameterized_username
    self.parameterized_username = self.username.parameterize
    self.parameterized_username
  end

  def to_param
    self.parameterized_username
  end

  validates :username, presence: true, uniqueness: true, case_sensitive: false
  validates :parameterized_username, uniqueness: true, case_sensitive: false

  ###############################################
  # GROUPS                                      #
  ###############################################

  # groups
  has_many :group_players
  has_many :groups, through: :group_players, source: :group

  #return ranking of player based on algorithm
  def rank_in(group)
    group_players = group.group_players.where("points > ? and player_id != ?", self.points_in(group), self.id)
    players = group_players.map { |gp| gp.player }
    players.count + 1
  end

  def is_ranked_in?(group)
    self.group_player(group).games_count >= 2
  end

  def is_ranked?
    self.games_count >= 2
  end

  def group_player(group)
    GroupPlayer.find_by(group_id: group.id, player_id: self.id)
  end

  def global_group_player
    GroupPlayer.find_by(group_id: Group.global.id, player_id: self.id)
  end

  def games_in(group)
    group_games = games.select {|game| (game.players - group.players).empty?}
    return group_games.sort {|a,b| b.created_at <=> a.created_at}
  end

  def points_in(group)
    self.group_player(group).points
  end

  def points
    self.global_group_player.points
  end

  def rank
    self.rank_in(Group.global)
  end

  def add_to_global
    global = Group.global
    if global
      global.players << self
      global.save
    end
  end

  def add_to_mit
    if self.email.end_with? "@mit.edu", ".mit.edu"
      mit = Group.find_by_name("MIT")
      if mit
        mit.players << self
        mit.save
      end
    end
  end

  ###############################################
  # GAMES                                       #
  ###############################################

  # all games a user has won
  has_many :game_winners
  has_many :wins, :through => :game_winners, :source => :game
  
  # all games a user has lost
  has_many :game_losers
  has_many :losses, :through => :game_losers, :source => :game

  def games
    all_games = wins + losses
    return all_games.sort {|a,b| b.created_at <=> a.created_at}
  end

  def games_count
    return wins.count + losses.count
  end

  def games_count_in(group)
    self.group_player(group).games_count
  end

  def confirmed_games
    confirmed = self.wins.where(confirmed: true) + self.losses.where(confirmed: true)
    return confirmed.sort {|a,b| b.created_at <=> a.created_at}
  end

  def unconfirmed_games
    unconfirmed = self.wins.where(confirmed: false) + self.losses.where(confirmed: false)
    return unconfirmed.sort {|a,b| a.created_at <=> b.created_at}
  end

  #games that have not been confirmed, but you cannot confirm yourself
  def pending_games
    self.wins.where(confirmed: false).order("created_at DESC")
  end

  #games you lost and can confirm
  def games_to_confirm
    return self.losses.where(confirmed: false).order("created_at DESC")
  end

  ###############################################
  # AUTH                                        #
  ###############################################

  #override will allow for login in with email
  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions).first
    end
  end
end
