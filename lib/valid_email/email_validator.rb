require 'active_model'
require 'active_model/validations'
require 'mail'
class EmailValidator < ActiveModel::EachValidator
  def validate_each(record,attribute,value)
    begin
      return if options[:allow_nil] && value.nil?
      return if options[:allow_blank] && value.blank?

      m = Mail::Address.new(value)
      # We must check that value contains a domain and that value is an email address
      r = m.domain && m.address == value
      t = m.__send__(:tree)
      # We need to dig into treetop
      # A valid domain must have dot_atom_text elements size > 1
      # user@localhost is excluded
      # treetop must respond to domain
      # We exclude valid email values like <user@localhost.com>
      # Hence we use m.__send__(tree).domain
      r &&= (t.domain.dot_atom_text.elements.size > 1)
      # Check if domain has DNS MX record
      if r && options[:mx]
        require 'valid_email/mx_validator'
        r &&= MxValidator.new(:attributes => attributes).validate(record)
      elsif r && options[:mx_with_fallback]
        require 'valid_email/mx_with_fallback_validator'
        r &&= MxWithFallbackValidator.new(:attributes => attributes).validate(record)
      end
      # Check if domain is disposable
      if r && options[:ban_disposable_email]
        require 'valid_email/ban_disposable_email_validator'
        r &&= BanDisposableEmailValidator.new(:attributes => attributes).validate(record)
      end
    rescue Exception => e
      r = false
    end
    record.errors.add attribute, (options[:message] || I18n.t(:invalid, :scope => "valid_email.validations.email")) unless r
  end
end
