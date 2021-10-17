defmodule Calangobot.Consumer do
  use Nostrum.Consumer
  alias Nostrum.Api

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    cond do
      msg.content == "!word" -> Api.create_message(msg.channel_id, "Wrong usage of the command !word. Use !word **word**")
      msg.content == "!crypto" -> Api.create_message(msg.channel_id, "Wrong usage of the command !crypto. Use !crypto **currency** with currency being the three word letter for the cryptocurrency. EG: !crypto BTC")
      msg.content == "!holidays" -> Api.create_message(msg.channel_id, "Wrong usage of the command !holidays. Use !holidays **country** month's number, with country being the ISO 3166-1 Alpha 2 code for that country. Eg: !holidays BR 1 to get a full list of holidays on January in Brazil.")
      msg.content == "!cep" -> Api.create_message(msg.channel_id, "Wrong usage of the command !cep. Use !cep **cep number**")

      String.starts_with?(msg.content, "!word ") -> word(msg)
      String.starts_with?(msg.content, "!crypto ") -> crypto(msg)
      String.starts_with?(msg.content, "!funfact") -> fun_fact(msg)
      String.starts_with?(msg.content, "!holidays ") -> holidays(msg)
      String.starts_with?(msg.content, "!cep ") -> cep(msg)
      true -> :ok
    end
  end

  def handle_event(_) do
    :ok
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

  defp holidays(msg) do
    aux = String.split(msg.content, " ", parts: 3)
    country = Enum.fetch!(aux, 1)
    month = Enum.fetch!(aux, 2)
    current_year = Date.utc_today.year
    api_url = "https://calendarific.com/api/v2/holidays?&api_key=079be43cfec4c3cfa9a4c3e3bdcd35eab2f045e8&country=#{country}&year=#{current_year}&month=#{month}"
    resp = HTTPoison.get!(api_url)
    json = Poison.decode!(resp.body)

    holidays = json["response"]["holidays"]

    if Enum.empty?(holidays) do
      Api.create_message!(msg.channel_id, "No holidays this month!\nUse !holidays **country** month's number, with country being the ISO 3166-1 Alpha 2 code for that country. Eg: !holidays BR 1 to get a full list of holidays on January in Brazil.")
    else
    new_word = Enum.map_join(
      holidays,
      "\n",
      fn holiday ->
        day = holiday["date"]["datetime"]["day"]
        month = holiday["date"]["datetime"]["month"]
        year = holiday["date"]["datetime"]["year"]
        date = "#{day}/#{month}/#{year}"

        name = holiday["name"]

        "#{name} - Date: #{date}"
    end
    )
    Api.create_message!(msg.channel_id, "#{new_word}")
    end
  end

  defp cep(msg) do
    aux = String.split(msg.content, " ", parts: 2)
    cep = Enum.fetch!(aux, 1)
    api_url = "https://api.postmon.com.br/v1/cep/#{cep}"
    try do
      resp = HTTPoison.get!(api_url)
      json = Poison.decode!(resp.body)

      logradouro = json["logradouro"]
      bairro = json["bairro"]
      estado = json["estado"]
      cidade = json["cidade"]
      Api.create_message!(msg.channel_id, "CEP #{cep} - Logradouro: #{logradouro} - Bairro: #{bairro} - Cidade: #{cidade} - Estado: #{estado}")
    rescue
      _ -> Api.create_message!(msg.channel_id, "CEP #{cep} não foi encontrado")
    end

  end

end
