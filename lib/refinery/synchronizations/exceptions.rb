class BadRequest < StandardError
  attr :why
  def initialize(p_why)
    @why = p_why
  end
end

class Unauthorized < StandardError; end

class Forbidden < StandardError
  attr :why
  def initialize(p_why)
    @why = p_why
  end
end

class RecordConflict < StandardError
  attr :record_in_conflict
  def initialize(record)
    @record_in_conflict = record
  end
end
