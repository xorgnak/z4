module Z4
  def self.weather h={}
    return JSON.parse(Z4.api['https://api.openweathermap.org'].get('data/2.5/weather', { units: 'imperial', appid: ENV['OPENWEATHER_API_KEY'] }.merge(h)).body)
  end
end
