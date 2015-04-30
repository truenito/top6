class UserDecorator < Draper::Decorator
  delegate_all

  def name
    pretty_name = ''
    pretty_name = h.content_tag(:span, object.name)
    pretty_name << h.image_tag('money.png', {class: 'donator-icon', alt: '(donator)', title: '(donator)'} ) if object.donator
    pretty_name
  end

  def regular_name
    object.name
  end

  def simple_name
    object.name.downcase
  end

  def real_name
    markup = ''
    if object.real_name.nil?
      markup = '(sin nombre real)'
    elsif object.real_name.present? && object.real_middle_name && object.real_last_name
      markup = object.real_name + " " + object.real_middle_name + " " + object.real_last_name
    elsif object.real_name.present? &&  object.real_last_name
      markup = object.real_name + " " + object.real_last_name
    end
    markup.html_safe
  end

  def wins_and_losses
    "W:#{object.win_count} / L:#{object.lose_count}"
  end

  def games_count
    "#{object.win_count + object.lose_count}"
  end

  def position_table_class(position)
    case position
    when 0
      'success'
    when 1
      'danger'
    when 2
      'info'
    else
      ''
    end
  end

end