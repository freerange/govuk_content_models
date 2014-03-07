require "govspeak"

class SafeHtml < ActiveModel::Validator
  def validate(record)
    record.changes.each do |field_name, (old_value, new_value)|
      check_struct(record, field_name, new_value)
    end
  end

  def check_struct(record, field_name, value)
    if value.respond_to?(:values) # e.g. Hash
      value.values.each { |entry| check_struct(record, field_name, entry) }
    elsif value.respond_to?(:each) # e.g. Array
      value.each { |entry| check_struct(record, field_name, entry) }
    elsif value.is_a?(String)
      check_string(record, field_name, value)
    end
  end

  def check_string(record, field_name, string)
    if govspeak_fields(record).include?(field_name)
      unless Govspeak::Document.new(string).valid?
        error = "cannot include invalid Govspeak or JavaScript"
        record.errors.add(field_name, error)
      end
    else
      unless Govspeak::HtmlValidator.new(string).valid?
        error = "cannot include invalid HTML or JavaScript"
        record.errors.add(field_name, error)
      end
    end
  end

private
  def govspeak_fields(record)
    if record.class.const_defined?(:GOVSPEAK_FIELDS)
      record.class.const_get(:GOVSPEAK_FIELDS)
    else
      []
    end
  end
end
