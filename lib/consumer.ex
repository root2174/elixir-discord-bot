defmodule Calangobot.Consumer do
  use Nostrum.Consumer
  alias Nostrum.Api

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    cond do
      msg.content == "!ping" -> Api.create_message(msg.channel_id, "Pong")
      msg.content == "!tempo" -> Api.create_message(msg.channel_id, "Uso do comando !tempo errado. Use !tempo **cidade**")
      String.starts_with?(msg.content, "!tempo ") -> weather(msg)
      String.starts_with?(msg.content, "!word ") -> word(msg)
      String.starts_with?(msg.content, "!crypto ") -> crypto(msg)
      String.starts_with?(msg.content, "!funfact") -> fun_fact(msg)
      String.starts_with?(msg.content, "!funfact ") -> fun_fact(msg)
      true -> :ok
    end
  end

  def handle_event(_) do
    :ok
  end

  defp weather(msg) do
    aux = String.split(msg.content, " ", parts: 2)
    city = Enum.fetch!(aux, 1)
    api_url = "api.openweathermap.org/data/2.5/weather?q=#{city}&units=metric&appid=67b6796050047eb9e9a9025000b5fc59"
    resp = HTTPoison.get!(api_url)
    json = Poison.decode!(resp.body)
    temp = json["main"]["temp"]

    case resp.status_code do
      200 -> Api.create_message(msg.channel_id, "A temperatura em #{city} é #{temp}°C")
      404 -> Api.create_message!(msg.channel_id, "A cidade #{city} não foi encontrada")
    end
  end

  defp word(msg) do
    aux = String.split(msg.content, " ", parts: 2)
    word = Enum.fetch!(aux, 1)
    api_url = "https://api.dictionaryapi.dev/api/v2/entries/en/#{word}"
    resp = HTTPoison.get!(api_url)
    case resp.status_code do
      200 ->
        json = Poison.decode!(resp.body)
        top_res = Enum.fetch!(json, 0)
        origin = top_res["origin"]
        Api.create_message(msg.channel_id, "#{word} origin is: #{origin}")
        Enum.map(top_res["meanings"], fn meaning ->
          part_of_speech = meaning["partOfSpeech"]
          definition = Enum.fetch!(meaning["definitions"], 0)["definition"]
          Api.create_message!(msg.channel_id, "#{part_of_speech} - meaning: #{definition}")
        end)
      404 -> Api.create_message!(msg.channel_id, "The word #{word} was not found. Use !word **word**")
    end
  end

  defp crypto(msg) do
    aux = String.split(msg.content, " ", parts: 2)
    currency = Enum.fetch!(aux, 1)
    api_url = "http://api.coinlayer.com/api/live?access_key=8d3c2d3787f44e461825e77318bebfbd&symbols=#{currency}"
    if String.contains?(currency, " ") do
      Api.create_message!(msg.channel_id, "Currency not found. Use !crypto **currency** with currency being the three word letter for the cryptocurrency. EG: !crypto BTC")
    else
    resp = HTTPoison.get!(api_url)
    json = Poison.decode!(resp.body)
    case json["success"] do
      true ->
        Enum.each(json["rates"], fn {k, v} ->
          Api.create_message!(msg.channel_id, "#{k} currency is: #{v} USD")
        end)
      false -> Api.create_message!(msg.channel_id, "Currency not found. Use !crypto **currency** with currency being the three word letter for the cryptocurrency. EG: !crypto BTC")
    end
    end
  end

  defp fun_fact(msg) do
    api_url = "https://asli-fun-fact-api.herokuapp.com/"
    resp = HTTPoison.get!(api_url)
    json = Poison.decode!(resp.body)
    case json["status"] do
      true ->
        fact = json["data"]["fact"]
        Api.create_message!(msg.channel_id, fact)
      false -> Api.create_message!(msg.channel_id, "Joke not found.")
    end

  end

end
