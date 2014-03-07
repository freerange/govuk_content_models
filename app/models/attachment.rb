require 'attachable'

class Attachment
  include Mongoid::Document
  include Mongoid::Timestamps
  include Attachable

  field :title
  field :filename
  attaches :file

  validates_with SafeHtml

  def url
    file.file_url
  end

  # TODO: Move this to a domain object in specialist publisher
  def snippet
    "[InlineAttachment:#{filename}]"
  end
end