class Checklists::ChangeNote
  include ActiveModel::Validations

  CONFIG_PATH = Rails.root.join('lib/checklists/change_notes.yaml')

  validates_presence_of :action_id
  validates_inclusion_of :type, in: %w(addition content_change)
  validates_format_of :time, with: /\d{4}-\d{2}-\d{2} \d{2}:\d{2}/
  validates_presence_of :note, if: -> { type == "content_change" }
  validates_length_of :id, is: SecureRandom.uuid.length, message: "ID not a UUID"

  attr_reader :id, :action_id, :type, :note, :time

  def initialize(attrs)
    attrs.each { |key, value| instance_variable_set("@#{key}", value) }
    validate!
  end

  def action
    Checklists::Action.find_by_id(action_id)
  end

  def self.load(params)
    parsed_params = params.dup
    parsed_params['id'] = params['uuid']
    new(parsed_params)
  end

  def self.load_all
    @load_all ||= YAML.load_file(CONFIG_PATH)['change_notes'].to_a
      .map { |c| load(c) }
  end

  def self.find_by_id(id)
    load_all.find { |c| c.id == id }
  end
end