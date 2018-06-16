# frozen_string_literal: true

class EpisodeRecordsController < ApplicationController
  permits :episode_id, :comment, :shared_twitter, :shared_facebook, :rating_state

  before_action :authenticate_user!, only: %i(create edit update switch)

  def create(episode_record)
    @episode = Episode.published.find(episode_record[:episode_id])
    @work = @episode.work
    @episode_record = @episode.episode_records.new(episode_record)
    ga_client.page_category = params[:page_category]

    service = NewEpisodeRecordService.new(current_user, @episode_record)
    service.page_category = params[:page_category]
    service.ga_client = ga_client
    service.via = "web"

    begin
      service.save!
      flash[:notice] = t("messages.episode_records.created")
      redirect_to work_episode_path(@work, @episode)
    rescue
      params[:locale_en] = locale_en?
      params[:locale_ja] = locale_ja?
      service = EpisodeRecordsListService.new(current_user, @episode, params)

      @all_episode_records = service.all_episode_records
      @all_comment_episode_records = service.all_comment_episode_records
      @friend_comment_episode_records = service.friend_comment_episode_records
      @my_episode_records = service.my_episode_records
      @selected_comment_episode_records = service.selected_comment_episode_records

      data = {
        recordsSortTypes: Setting.records_sort_type.options,
        currentRecordsSortType: current_user&.setting&.records_sort_type.presence || "created_at_desc"
      }
      gon.push(data)

      store_page_params(work: @work)

      @is_spoiler = current_user.hide_episode_record_body?(@episode)

      render "/episodes/show"
    end
  end

  def edit
    load_episode_record
    authorize @episode_record, :edit?
    @work = @episode_record.work
  end

  def update(episode_record)
    load_episode_record
    authorize @episode_record, :update?

    @episode_record.modify_comment = true
    @episode_record.detect_locale!(:comment)

    if @episode_record.update(episode_record)
      @episode_record.update_share_record_status
      @episode_record.share_to_sns
      path = record_path(current_user.username, @episode_record.record)
      redirect_to path, notice: t("messages._common.updated")
    else
      @work = @episode_record.work
      render :edit
    end
  end

  def switch(episode_id, to)
    episode = Episode.find(episode_id)

    return redirect_to work_episode_path(episode.work, episode) unless to.in?(Setting.display_option_record_list.values)

    current_user.setting.update_column(:display_option_record_list, to)
    redirect_to work_episode_path(episode.work, episode)
  end

  def redirect(provider, url_hash)
    url = case provider
    when "tw"
      Record.published.find_by!(twitter_url_hash: url_hash).share_url_with_query(:twitter)
    when "fb"
      Record.published.find_by!(facebook_url_hash: url_hash).share_url_with_query(:facebook)
    else
      root_path
    end

    redirect_to url
  end

  private

  def load_episode_record
    @episode_record = current_user.episode_records.published.find_by(episode_id: params[:episode_id], record_id: params[:id])
  end

  def redirect_to_user_record(record, provider:)
    username = record.user.username
    utm = {
      utm_source: provider,
      utm_medium: "record_share",
      utm_campaign: username
    }

    redirect_to record_path(username, record, utm)
  end
end
