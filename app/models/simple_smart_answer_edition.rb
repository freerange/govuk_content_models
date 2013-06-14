class SimpleSmartAnswerEdition < Edition
  include Mongoid::Document

  field :body, type: String

  embeds_many :nodes, :class_name => "SimpleSmartAnswerNode"

  GOVSPEAK_FIELDS = Edition::GOVSPEAK_FIELDS + [:body]
  @fields_to_clone = [:body]

  def whole_body
    body
  end

  def build_clone(edition_class=nil)
    new_edition = super

    new_edition.nodes = self.nodes.map {|n| n.dup }
    new_edition
  end

  def initial_node
    self.nodes.first
  end
end
