class Checklists::Answers
  attr_reader :criteria_keys

  def initialize(criteria_keys, actions)
    @criteria_keys = criteria_keys
    @actions = actions
  end

  def answers
    @answers ||= criteria.map { |c| { readable_text: c.text } }
  end

  def action_sections
    [
      {
        heading: "Some category",
        actions: actions
      }
    ]
  end


private

  attr_reader :actions

  def criteria
    @criteria ||= Checklists::Criterion.load(criteria_keys)
  end
end
