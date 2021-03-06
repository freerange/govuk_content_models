require "edition"
require "parted"

class GuideEdition < Edition
  include Parted

  field :video_url,     type: String
  field :video_summary, type: String

  GOVSPEAK_FIELDS = []
  @fields_to_clone = [:video_url, :video_summary]

  def has_video?
    video_url.present?
  end

  def safe_to_preview?
    parts.any? and parts.first.slug.present?
  end
end
