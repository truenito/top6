# Team class, it's required to have two separate teams to play a match,
# a Team has the references of the players that belong to it.
class Team < ActiveRecord::Base
  has_and_belongs_to_many :users
  belongs_to :match

  def self.create_for_match(balanced_teams_hash, match_id)
    captain_a = balanced_teams_hash[:blue].sort_by(&:rating).reverse.first
    captain_b = balanced_teams_hash[:red].sort_by(&:rating).reverse.first

    blue = Team.new(match_id: match_id, captain_id: captain_a[:id], side: 'blue')
    blue.users << balanced_teams_hash[:blue]; blue.save!

    red_team = Team.new(match_id: match_id, captain_id: captain_b[:id], side: 'red')
    red_team.users << balanced_teams_hash[:red]; red_team.save!
  end

  class << self
    # Interface to calculate Rating Change based on teams.
    def rating_change(blue, red)
      return nil if blue.nil? || red.nil?
      { blue: team_rating_change(EloRating::Match.new, 'blue', blue, red),
        red: team_rating_change(EloRating::Match.new, 'red', blue, red) }
    end

    # Calculates rating win/loss depending on the winner team, receives an
    # EloRating Match to calculate amounts with the update_ratings method.
    def team_rating_change(match, winner, blue, red)
      if winner == 'blue'
        match.add_player(rating: blue, winner: true)
        match.add_player(rating: red)
        match.updated_ratings[0] - blue
      else
        match.add_player(rating: blue)
        match.add_player(rating: red, winner: true)
        match.updated_ratings[1] - red
      end
    end

    # Calculates team average rating.
    def rating_average(team, match)
      if match.ended?
        sum = 0; team.each { |u| sum += u['rating'].to_i }
      else
        sum = 0; team.users.each { |u| sum += u['rating'].to_i }
      end
      sum / 5
    end
  end
end
