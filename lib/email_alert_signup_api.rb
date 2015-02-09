require 'gds_api/gov_uk_delivery'

class EmailAlertSignupAPI

  def initialize(dependencies = {})
    @email_alert_api = dependencies.fetch(:email_alert_api)
    @attributes = dependencies.fetch(:attributes)
    @subscription_list_title_prefix = dependencies.fetch(:subscription_list_title_prefix)
    @available_choices = dependencies.fetch(:available_choices)
    @filter_key = dependencies.fetch(:filter_key)
    if attributes['filter'].blank? && !available_choices.blank?
      raise ArgumentError, "User must choose at least one of the available options"
    end
  end

  def signup_url
    subscriber_list.subscription_url
  end

private
  attr_reader :email_alert_api, :attributes, :subscription_list_title_prefix, :available_choices, :filter_key

  def subscriber_list
    response = email_alert_api.find_or_create_subscriber_list("tags" => massaged_attributes, "title" => title)
    response.subscriber_list
  end

  def title
    if available_choices.empty?
      title = subscription_list_title_prefix.to_s
    else
      if attributes.fetch("filter").length == 1
        plural_or_single = "singular"
      else
        plural_or_single = "plural"
      end
      title = subscription_list_title_prefix[plural_or_single].to_s + to_sentence(topic_names)
    end
    force_capitalize(title)
  end

  def topic_names
    attributes.fetch("filter").collect {|x| choice_hash_by_key(x).topic_name }
  end

  def choice_hash_by_key(key)
    available_choices.select {|x| x.key == key}[0]
  end

  def massaged_attributes
    massaged_attributes = attributes.dup
    if available_choices.empty?
      massaged_attributes.delete("filter")
    else
      massaged_attributes[@filter_key] = massaged_attributes.delete("filter")
    end
    massaged_attributes
  end

  # Title string helpers
  def to_sentence(arr)
    case arr.length
    when 0
      ""
    when 1
      arr[0].to_s.dup
    when 2
      "#{arr[0]} and #{arr[1]}"
    else
      "#{arr[0...-1].join(", ")}, and #{arr[-1]}"
    end
  end

  def force_capitalize(str)
    str[0] = str[0].capitalize
    str
  end
end