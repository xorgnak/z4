class Bubble
  def initialize k
    @id = k
  end
  def user; @id; end
  def info k
    INFO[k].join("\n")
  end
  def agenda
    Remind.get(@id).join("\n")
  end
  def remind s
    Remind.set(@id, s)
    return "ok."
  end
  def plan
    PLAN.sample.to_md
  end
end
