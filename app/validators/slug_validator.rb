class SlugValidator < ActiveModel::EachValidator
  # implement the method called during validation
  def validate_each(record, attribute, value)
    validators = [
      DonePageValidator,
      ForeignTravelAdvicePageValidator,
      HelpPageValidator,
      GovernmentPageValidator,
      SpecialistDocumentPageValidator,
      DefaultValidator
    ].map { |klass| klass.new(record, attribute, value) }

    validators.find(&:applicable?).validate!
  end

protected
  class InstanceValidator < Struct.new(:record, :attribute, :value)
    def starts_with?(expected_prefix)
      value.to_s[0...expected_prefix.size] == expected_prefix
    end

    def of_kind?(expected_kind)
      record.respond_to?(:kind) && [*expected_kind].include?(record.kind)
    end

    def url_after_first_slash
      value.to_s.split('/', 2)[1]
    end

    def url_after_first_slash_is_valid_slug!
      if !valid_slug?(url_after_first_slash)
        record.errors[attribute] << "must be usable in a url"
      end
    end

    def url_parts
      value.to_s.split("/")
    end

    def valid_slug?(url_part)
      # Regex taken from ActiveSupport::Inflector.parameterize
      # We don't want to use this method because it also does a number of cosmetic tidy-ups
      # which lead to false-positives (eg merging consecutive '-'s)
      ! url_part.to_s.match(/[^a-z0-9\-_]/)
    end
  end

  class DonePageValidator < InstanceValidator
    def applicable?
      starts_with?("done/")
    end

    def validate!
      url_after_first_slash_is_valid_slug!
    end
  end

  class ForeignTravelAdvicePageValidator < InstanceValidator
    def applicable?
      starts_with?("foreign-travel-advice/") && of_kind?('travel-advice')
    end

    def validate!
      url_after_first_slash_is_valid_slug!
    end
  end

  class HelpPageValidator < InstanceValidator
    def applicable?
      of_kind?('help_page')
    end

    def validate!
      record.errors[attribute] << "Help page slugs must have a help/ prefix" unless starts_with?("help/")
      url_after_first_slash_is_valid_slug!
    end
  end

  class GovernmentPageValidator < InstanceValidator
    def applicable?
      record.respond_to?(:kind) && prefixed_whitehall_format_names.include?(record.kind)
    end

    def validate!
      record.errors[attribute] << "Inside Government slugs must have a government/ prefix" unless starts_with?('government/')
      unless url_parts.all? { |url_part| valid_slug?(url_part) }
        record.errors[attribute] << "must be usable in a URL"
      end
    end

  protected
    def prefixed_whitehall_format_names
      Artefact::FORMATS_BY_DEFAULT_OWNING_APP["whitehall"] - ["detailed_guide"]
    end
  end

  class SpecialistDocumentPageValidator < InstanceValidator
    def applicable?
      of_kind?('specialist-document')
    end

    def validate!
      unless url_parts.size == 2
        record.errors[attribute] << "must be of form <finder-slug>/<specialist-document-slug>"
      end
      unless url_parts.all? { |url_part| valid_slug?(url_part) }
        record.errors[attribute] << "must be usable in a URL"
      end
    end
  end

  class DefaultValidator < InstanceValidator
    def applicable?
      true
    end

    def validate!
      record.errors[attribute] << "must be usable in a url" unless valid_slug?(value)
    end
  end

end
