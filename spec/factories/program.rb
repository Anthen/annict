# frozen_string_literal: true

FactoryGirl.define do
  factory :program do
    association :work
    association :episode
    started_at Time.parse("2017-01-29 0:00:00")
    channel

    before(:create) { |p| p.work = p.episode.work }
  end
end
