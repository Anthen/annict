# frozen_string_literal: true

ObjectTypes::User = GraphQL::ObjectType.define do
  name "User"

  implements GraphQL::Relay::Node.interface

  global_id_field :id

  field :annictId, !types.Int do
    resolve ->(obj, _args, _ctx) {
      obj.id
    }
  end

  connection :activities, Connections::ActivityConnection do
    argument :orderBy, InputObjectTypes::ActivityOrder

    resolve Resolvers::Activities.new
  end

  connection :followingActivities, Connections::ActivityConnection do
    resolve ->(obj, _args, _ctx) {
      following_ids = obj.followings.pluck(:id)
      following_ids << obj.id
      ForeignKeyLoader.for(Activity, :user_id).load(following_ids)
    }
  end

  connection :followers, ObjectTypes::User.connection_type do
    resolve ->(obj, _args, _ctx) {
      ForeignKeyLoader.for(User, :id).load(obj.followers.pluck(:id))
    }
  end

  connection :following, ObjectTypes::User.connection_type do
    resolve ->(obj, _args, _ctx) {
      ForeignKeyLoader.for(User, :id).load(obj.followings.pluck(:id))
    }
  end

  connection :works, ObjectTypes::Work.connection_type do
    argument :annictIds, types[!types.Int]
    argument :seasons, types[!types.String]
    argument :titles, types[!types.String]
    argument :state, EnumTypes::StatusState
    argument :orderBy, InputObjectTypes::WorkOrder

    resolve Resolvers::Works.new
  end

  connection :programs, ObjectTypes::Program.connection_type do
    argument :unwatched, types.Boolean
    argument :orderBy, InputObjectTypes::ProgramOrder

    resolve Resolvers::Programs.new
  end

  field :username, !types.String

  field :name, !types.String do
    resolve ->(obj, _args, _ctx) {
      obj.profile.name
    }
  end

  field :description, !types.String do
    resolve ->(obj, _args, _ctx) {
      obj.profile.description
    }
  end

  field :url, types.String do
    resolve ->(obj, _args, _ctx) {
      obj.profile.url
    }
  end

  field :avatarUrl, types.String do
    resolve ->(obj, _args, _ctx) {
      ann_api_assets_url(obj.profile, :tombo_avatar)
    }
  end

  field :backgroundImageUrl, types.String do
    resolve ->(obj, _args, _ctx) {
      ann_api_assets_background_image_url(obj.profile, :tombo_background_image)
    }
  end

  field :recordsCount, !types.Int do
    resolve ->(obj, _args, _ctx) {
      obj.checkins_count
    }
  end

  field :followingsCount, !types.Int do
    resolve ->(obj, _args, _ctx) {
      obj.followings.count
    }
  end

  field :followersCount, !types.Int do
    resolve ->(obj, _args, _ctx) {
      obj.followers.count
    }
  end

  LatestStatus.kind.values.each do |kind|
    field "#{kind.to_s.camelcase(:lower)}Count", !types.Int do
      resolve ->(obj, _args, _ctx) {
        obj.latest_statuses.count_on(kind.to_sym)
      }
    end
  end

  field :createdAt, !ScalarTypes::DateTime do
    resolve ->(obj, _args, _ctx) {
      obj.created_at
    }
  end

  field :viewerCanFollow, !types.Boolean do
    resolve ->(obj, _args, ctx) {
      viewer = ctx[:doorkeeper_token].owner
      viewer != obj && !viewer.following?(obj)
    }
  end

  field :viewerIsFollowing, !types.Boolean do
    resolve ->(obj, _args, ctx) {
      viewer = ctx[:doorkeeper_token].owner
      viewer.following?(obj)
    }
  end

  field :email, types.String do
    resolve ->(obj, _args, ctx) {
      return nil if ctx[:doorkeeper_token].owner != obj
      obj.email
    }
  end

  field :notificationsCount, types.Int do
    resolve ->(obj, _args, ctx) {
      return nil if ctx[:doorkeeper_token].owner != obj
      obj.notifications_count
    }
  end
end
