# frozen_string_literal: true

FactoryGirl.define do
  factory :profile do
    sequence(:name) { |n| "人造人間#{n}号" }
    description "悟空を倒すために生まれました。よろしくお願いします。"
    tombo_avatar File.open("#{Rails.root}/public/images/no_image.png")
    tombo_background_image File.open("#{Rails.root}/public/images/no_image.png")
  end
end
