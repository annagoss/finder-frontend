require "addressable/uri"

class EmailAlertSignupAPI
  class UnprocessableSubscriberListError < StandardError; end

  def initialize(applied_filters:, default_filters:, facets:, subscriber_list_title:)
    @applied_filters = applied_filters.deep_symbolize_keys
    @default_filters = default_filters.deep_symbolize_keys
    @facets = facets
    @subscriber_list_title = subscriber_list_title
  end

  def signup_url
    subscriber_list["subscription_url"]
  rescue GdsApi::HTTPUnprocessableEntity
    raise UnprocessableSubscriberListError
  end

private

  attr_reader :applied_filters, :default_filters, :facets, :subscriber_list_title, :email_filter_by

  def add_url_param(url, param)
    # this method safely adds a URL parameter using the correct one of '?' or '&'
    parsed_uri = Addressable::URI.parse(url)
    parsed_uri.query_values = (parsed_uri.query_values || {}).merge(param)
    parsed_uri.to_s
  end

  def subscriber_list
    Services.email_alert_api.find_or_create_subscriber_list(subscriber_list_options).dig("subscriber_list")
  end

  def subscriber_list_options
    options = link_based_subscriber_list? ? { "links" => links } : { "tags" => tags }
    options.merge("title" => subscriber_list_title)
  end

  def link_based_subscriber_list?
    # TODO: move this logic into schema
    content_types = %w[organisations people roles world_locations part_of_taxonomy_tree]
    keys = facet_filter_keys.map { |key| key.gsub(/^(all_|any_)/, "") }
    (keys & content_types).present?
  end

  def links
    selected_keys = applied_filters.keys.map(&:to_s) & facet_filter_keys
    filter_links = selected_keys.each_with_object({}) do |full_key, result|
      operator, key = split_key(full_key)
      applied_values = Array.wrap(applied_filters[full_key.to_sym])
      facet = facet_by_key(key) || {}
      facet_choice_values = facet_choice_filter_values(facet, applied_values)
      values = facet_choice_values.any? ? facet_choice_values : applied_values

      result[key] ||= {}
      result[key][operator] = to_content_ids(key, values)
    end
    filter_links.merge(default_links)
  end

  def default_links
    default_filters.transform_values { |value| { any: Array.wrap(value) } }
  end

  def split_key(full_key)
    matches = full_key.match(/^((?<operator>any|all)_)?(?<key>.*)$/)
    operator = matches[:operator] || "any"
    key = matches[:key] == "part_of_taxonomy_tree" ? "taxon_tree" : matches[:key]
    [operator, key]
  end

  def to_content_ids(key, values)
    return values unless %w[organisations people roles world_locations].include?(key)

    registry = Registries::BaseRegistries.new.all[key]
    values.map { |value| registry[value]["content_id"] }
  end

  def facet_filter_keys
    @facet_filter_keys ||= facets.map { |f| f["filter_key"] || f["facet_id"] }
  end

  def tags
    @tags ||= filter_keys.each_with_object({}) do |key, tags_hash|
      values = values_for_key(key)
      any_or_all = is_all_field?(key) ? :all : :any
      tag = is_all_field?(key) ? key[4..-1] : key

      tags_hash[tag] ||= {}
      tags_hash[tag][any_or_all] ||= []
      tags_hash[tag][any_or_all] = tags_hash.dig(tag, any_or_all).concat(values).uniq
    end
  end

  def filter_keys
    applied_filter_keys = applied_filters.keys.reject { |key| facet_by_key(key).nil? }
    applied_filter_keys.concat(default_filters.keys).uniq
  end

  def values_for_key(key)
    applied_values = Array(applied_filters[key])
    default_values = Array(default_filters[key])
    facet = facet_by_key(key) || {}

    facet_choice_values = facet_choice_filter_values(facet, applied_values)
    values = facet_choice_values.any? ? facet_choice_values : applied_values

    values.concat(default_values)
  end

  def facet_choice_filter_values(facet, values)
    facet
      .fetch("facet_choices", [])
      .select { |option| values.include?(option["key"]) }
      .flat_map { |option| option["filter_values"] }
  end

  def facet_by_key(key)
    facets.find { |facet| [facet["filter_key"], facet["facet_id"]].include?(key.to_s) }
  end

  def is_all_field?(key)
    key[0..3] == "all_"
  end
end
