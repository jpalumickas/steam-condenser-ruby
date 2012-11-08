# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2012-2013, Sebastian Staudt

require 'multi_json'

require 'steam/community/cacheable'
require 'steam/community/game_stats_schema'
require 'steam/community/web_api'

class UserStats

  include Cacheable
  cacheable_with_ids [ :app_id, :steam_id64 ]

  attr_reader :app_id

  attr_reader :game_schema

  attr_reader :locked_achievements

  attr_reader :stats_data

  attr_reader :steam_id64

  attr_reader :unlocked_achievements

  def initialize(app_id, steam_id64)
    @app_id     = app_id
    @steam_id64 = steam_id64

    params = { :appid => app_id, :steamid => steam_id64 }
    stats = WebApi.json('ISteamUserStats', 'GetUserStatsForGame', 2, params)[:playerstats]

    @game_schema = GameStatsSchema.new app_id

    @locked_achievements = Hash[@game_schema.achievements.map { |achievement|
      [ achievement.api_name, achievement ]
    }]
    @unlocked_achievements = {}
    stats[:achievements].each do |achievement|
      if achievement[:achieved] == 1
        @unlocked_achievements[achievement[:name]] = @locked_achievements.delete(achievement[:name])
      end
    end

    @stats_data = {}
    stats[:stats].each do |stats_value|
      api_name = stats_value[:name]
      @stats_data[api_name] = GameStatsValue::Instance.new(@game_schema.stats_values[api_name], stats_value[:value])
    end
  end

  def inspect
    "#<#{self.class}:#@steam_id64 \"#{@game_schema.app_name}\" #{@unlocked_achievements.size}/#{@locked_achievements.size + @unlocked_achievements.size} achievements>"
  end

end
